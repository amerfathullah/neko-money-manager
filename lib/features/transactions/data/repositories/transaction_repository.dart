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
      // 1. Add Transaction
      final transactionRef = userDoc
          .collection(_collection)
          .doc(transactionModel.id);
      transaction.set(transactionRef, transactionModel.toJson());

      // 2. Update Asset Balance & History
      if (transactionModel.assetId != null) {
        await _updateAssetBalanceInTransaction(
          transaction,
          userDoc,
          transactionModel.assetId!,
          transactionModel.type == TransactionType.income
              ? transactionModel.amount
              : -transactionModel.amount, // Expense or Transfer Source
          transactionModel.id,
          'transaction_add',
        );

        if (transactionModel.type == TransactionType.transfer &&
            transactionModel.destinationAssetId != null) {
          await _updateAssetBalanceInTransaction(
            transaction,
            userDoc,
            transactionModel.destinationAssetId!,
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
      // 1. Delete Transaction
      final transactionRef = userDoc
          .collection(_collection)
          .doc(transactionModel.id);
      transaction.delete(transactionRef);

      // 2. Revert Asset Balance & History
      if (transactionModel.assetId != null) {
        // Revert: Expense -> Add, Income -> Subtract
        await _updateAssetBalanceInTransaction(
          transaction,
          userDoc,
          transactionModel.assetId!,
          transactionModel.type == TransactionType.income
              ? -transactionModel.amount
              : transactionModel.amount,
          transactionModel.id,
          'transaction_delete',
        );

        if (transactionModel.type == TransactionType.transfer &&
            transactionModel.destinationAssetId != null) {
          // Revert Transfer Dest: Subtract
          await _updateAssetBalanceInTransaction(
            transaction,
            userDoc,
            transactionModel.destinationAssetId!,
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
      // 1. Revert Old (Manual Logic to avoid double reads?)
      // Actually _updateAssetBalanceInTransaction handles reads.
      // Firestore transactions handle repeated reads of same doc fine (returns same snap).

      // Revert Old Source
      if (oldTransaction.assetId != null) {
        await _updateAssetBalanceInTransaction(
          transaction,
          userDoc,
          oldTransaction.assetId!,
          oldTransaction.type == TransactionType.income
              ? -oldTransaction.amount
              : oldTransaction.amount,
          newTransaction.id, // Use new ID for history relation
          'transaction_update_revert',
        );

        if (oldTransaction.type == TransactionType.transfer &&
            oldTransaction.destinationAssetId != null) {
          await _updateAssetBalanceInTransaction(
            transaction,
            userDoc,
            oldTransaction.destinationAssetId!,
            -oldTransaction.amount,
            newTransaction.id,
            'transaction_update_revert_transfer',
          );
        }
      }

      // 2. Apply New
      if (newTransaction.assetId != null) {
        await _updateAssetBalanceInTransaction(
          transaction,
          userDoc,
          newTransaction.assetId!,
          newTransaction.type == TransactionType.income
              ? newTransaction.amount
              : -newTransaction.amount,
          newTransaction.id,
          'transaction_update_apply',
        );

        if (newTransaction.type == TransactionType.transfer &&
            newTransaction.destinationAssetId != null) {
          await _updateAssetBalanceInTransaction(
            transaction,
            userDoc,
            newTransaction.destinationAssetId!,
            newTransaction.amount,
            newTransaction.id,
            'transaction_update_apply_transfer',
          );
        }
      }

      // 3. Update Transaction Doc
      final transactionRef = userDoc
          .collection(_collection)
          .doc(newTransaction.id);
      transaction.set(transactionRef, newTransaction.toJson());
    });
  }

  // Helper to update balance and log history
  Future<void> _updateAssetBalanceInTransaction(
    Transaction transaction,
    DocumentReference userDoc,
    String assetId,
    double amountChange,
    String? transactionId,
    String reason,
  ) async {
    final assetRef = userDoc.collection('assets').doc(assetId);
    final assetSnap = await transaction.get(assetRef);

    if (assetSnap.exists) {
      final currentBalance =
          (assetSnap.data() as Map<String, dynamic>)['balance'] as double? ??
          0.0;
      final newBalance = currentBalance + amountChange;

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
