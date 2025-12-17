import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import '../../../assets/data/models/asset_history_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'transactions';

  Future<void> addTransaction(
    String userId,
    TransactionModel transactionModel,
  ) async {
    final userDoc = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      // 1. READ PHASE: Fetch all necessary assets
      final assetIds = <String>{};
      if (transactionModel.assetId != null) {
        assetIds.add(transactionModel.assetId!);
      }
      if (transactionModel.type == TransactionType.transfer &&
          transactionModel.destinationAssetId != null) {
        assetIds.add(transactionModel.destinationAssetId!);
      }

      final assetSnapshots = await _getAssetSnapshots(
        transaction,
        userDoc,
        assetIds,
      );

      // 2. WRITE PHASE: Perform all writes
      // Add Transaction
      final transactionRef = userDoc
          .collection(_collection)
          .doc(transactionModel.id);
      transaction.set(transactionRef, transactionModel.toJson());

      // Update Asset Balance & History
      if (transactionModel.assetId != null) {
        _queueAssetUpdate(
          transaction,
          userDoc,
          assetSnapshots[transactionModel.assetId!]!,
          transactionModel.type == TransactionType.income
              ? transactionModel.amount
              : -transactionModel.amount, // Expense or Transfer Source
          transactionModel.id,
          'transaction_add',
        );

        if (transactionModel.type == TransactionType.transfer &&
            transactionModel.destinationAssetId != null) {
          _queueAssetUpdate(
            transaction,
            userDoc,
            assetSnapshots[transactionModel.destinationAssetId!]!,
            transactionModel.amount, // Transfer Dest (Income)
            transactionModel.id,
            'transaction_add_transfer',
          );
        }
      }
    });
  }

  Future<void> deleteTransaction(
    String userId,
    TransactionModel transactionModel,
  ) async {
    final userDoc = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      // 1. READ PHASE
      final assetIds = <String>{};
      if (transactionModel.assetId != null) {
        assetIds.add(transactionModel.assetId!);
      }
      if (transactionModel.type == TransactionType.transfer &&
          transactionModel.destinationAssetId != null) {
        assetIds.add(transactionModel.destinationAssetId!);
      }

      final assetSnapshots = await _getAssetSnapshots(
        transaction,
        userDoc,
        assetIds,
      );

      // 2. WRITE PHASE
      // Delete Transaction
      final transactionRef = userDoc
          .collection(_collection)
          .doc(transactionModel.id);
      transaction.delete(transactionRef);

      // Revert Asset Balance & History
      if (transactionModel.assetId != null) {
        // Revert: Expense -> Add, Income -> Subtract
        _queueAssetUpdate(
          transaction,
          userDoc,
          assetSnapshots[transactionModel.assetId!]!,
          transactionModel.type == TransactionType.income
              ? -transactionModel.amount
              : transactionModel.amount,
          transactionModel.id,
          'transaction_delete',
        );

        if (transactionModel.type == TransactionType.transfer &&
            transactionModel.destinationAssetId != null) {
          // Revert Transfer Dest: Subtract
          _queueAssetUpdate(
            transaction,
            userDoc,
            assetSnapshots[transactionModel.destinationAssetId!]!,
            -transactionModel.amount,
            transactionModel.id,
            'transaction_delete_transfer',
          );
        }
      }
    });
  }

  Future<void> updateTransaction(
    String userId,
    TransactionModel oldTransaction,
    TransactionModel newTransaction,
  ) async {
    final userDoc = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      // 1. READ PHASE: Collect ALL asset IDs from old and new
      final assetIds = <String>{};
      if (oldTransaction.assetId != null) assetIds.add(oldTransaction.assetId!);
      if (oldTransaction.type == TransactionType.transfer &&
          oldTransaction.destinationAssetId != null) {
        assetIds.add(oldTransaction.destinationAssetId!);
      }
      if (newTransaction.assetId != null) assetIds.add(newTransaction.assetId!);
      if (newTransaction.type == TransactionType.transfer &&
          newTransaction.destinationAssetId != null) {
        assetIds.add(newTransaction.destinationAssetId!);
      }
      if (oldTransaction.reimbursedAssetId != null) {
        assetIds.add(oldTransaction.reimbursedAssetId!);
      }
      if (newTransaction.reimbursedAssetId != null) {
        assetIds.add(newTransaction.reimbursedAssetId!);
      }

      final assetSnapshots = await _getAssetSnapshots(
        transaction,
        userDoc,
        assetIds,
      );

      // Logic check: Calculate net changes for each asset?
      // Or just apply reverts then applies sequentially?
      // Firestore transactions handle sequential writes to same doc in one batch fine?
      // Actually, since we read first, we have the BASE snapshot.
      // If we update the same asset twice (revert old, apply new), we need to daisy-chain the balance.

      // Map to track running balance updates during this transaction block
      final tempBalances = <String, double>{};
      for (final id in assetIds) {
        final snap = assetSnapshots[id];
        if (snap != null && snap.exists) {
          tempBalances[id] =
              (snap.data() as Map<String, dynamic>)['balance'] as double? ??
              0.0;
        }
      }

      // Helper to apply change to temp balance and queue write
      void queueUpdate(
        String assetId,
        double change,
        String reason,
        String txId,
      ) {
        if (!tempBalances.containsKey(assetId)) return; // Asset doesn't exist?

        final current = tempBalances[assetId]!;
        final newBal = current + change;
        tempBalances[assetId] = newBal; // Update temp for next op

        // We can queue multiple writes.
        final assetRef = userDoc.collection('assets').doc(assetId);
        transaction.update(assetRef, {'balance': newBal});

        final historyRef = userDoc.collection('asset_history').doc();
        final historyEntry = AssetHistoryModel(
          id: historyRef.id,
          assetId: assetId,
          balance: newBal,
          date: DateTime.now(),
          reason: reason,
          relatedTransactionId: txId,
        );
        transaction.set(historyRef, historyEntry.toJson());
      }

      // 2. WRITE PHASE - Execute Revert Old
      if (oldTransaction.assetId != null) {
        queueUpdate(
          oldTransaction.assetId!,
          oldTransaction.type == TransactionType.income
              ? -oldTransaction.amount
              : oldTransaction.amount,
          'transaction_update_revert',
          newTransaction.id,
        );
      }

      if (oldTransaction.type == TransactionType.transfer &&
          oldTransaction.destinationAssetId != null) {
        queueUpdate(
          oldTransaction.destinationAssetId!,
          -oldTransaction.amount,
          'transaction_update_revert_transfer',
          newTransaction.id,
        );
      }

      if (oldTransaction.reimbursedAssetId != null &&
          oldTransaction.reimbursedAmount != null) {
        queueUpdate(
          oldTransaction.reimbursedAssetId!,
          -oldTransaction.reimbursedAmount!,
          'reimbursement_revert',
          newTransaction.id,
        );
      }

      // 3. WRITE PHASE - Execute Apply New
      if (newTransaction.assetId != null) {
        queueUpdate(
          newTransaction.assetId!,
          newTransaction.type == TransactionType.income
              ? newTransaction.amount
              : -newTransaction.amount,
          'transaction_update_apply',
          newTransaction.id,
        );
      }

      if (newTransaction.type == TransactionType.transfer &&
          newTransaction.destinationAssetId != null) {
        queueUpdate(
          newTransaction.destinationAssetId!,
          newTransaction.amount,
          'transaction_update_apply_transfer',
          newTransaction.id,
        );
      }

      if (newTransaction.reimbursedAssetId != null &&
          newTransaction.reimbursedAmount != null) {
        queueUpdate(
          newTransaction.reimbursedAssetId!,
          newTransaction.reimbursedAmount!,
          'reimbursement_apply',
          newTransaction.id,
        );
      }

      // Update Transaction Doc
      final transactionRef = userDoc
          .collection(_collection)
          .doc(newTransaction.id);
      transaction.set(transactionRef, newTransaction.toJson());
    });
  }

  // Helper: Batch read assets
  Future<Map<String, DocumentSnapshot>> _getAssetSnapshots(
    Transaction transaction,
    DocumentReference userDoc,
    Set<String> assetIds,
  ) async {
    final results = <String, DocumentSnapshot>{};
    for (final id in assetIds) {
      final ref = userDoc.collection('assets').doc(id);
      final snap = await transaction.get(ref);
      results[id] = snap;
    }
    return results;
  }

  // Helper: Queue Write (Assumes single write per asset per transaction for simplicity,
  // but updateTransaction uses local state to allow multiple logical updates)
  // NOTE: This simple helper is used by add/delete where we modify each asset once.
  void _queueAssetUpdate(
    Transaction transaction,
    DocumentReference userDoc,
    DocumentSnapshot assetSnap,
    double amountChange,
    String? transactionId,
    String reason,
  ) {
    if (!assetSnap.exists) return;

    final currentBalance =
        (assetSnap.data() as Map<String, dynamic>)['balance'] as double? ?? 0.0;
    final newBalance = currentBalance + amountChange;
    final assetId = assetSnap.id;

    final assetRef = userDoc.collection('assets').doc(assetId);

    // Update Asset
    transaction.update(assetRef, {'balance': newBalance});

    // Log History
    final historyRef = userDoc.collection('asset_history').doc();
    final historyEntry = AssetHistoryModel(
      id: historyRef.id,
      assetId: assetId,
      balance: newBalance,
      date: DateTime.now(),
      reason: reason,
      relatedTransactionId: transactionId,
    );
    transaction.set(historyRef, historyEntry.toJson());
  }

  Stream<List<TransactionModel>> getRecentTransactions(
    String userId, {
    int limit = 10,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_collection)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TransactionModel.fromJson(doc.data()))
              .toList();
        });
  }

  Stream<List<TransactionModel>> getAllTransactionsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_collection)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TransactionModel.fromJson(doc.data()))
              .toList();
        });
  }

  Stream<List<TransactionModel>> getTransactionsByLedger(
    String userId,
    String ledgerId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_collection)
        .where('ledgerId', isEqualTo: ledgerId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TransactionModel.fromJson(doc.data()))
              .toList();
        });
  }

  Future<List<TransactionModel>> getAllTransactions(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection(_collection)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromJson(doc.data()))
        .toList();
  }
}
