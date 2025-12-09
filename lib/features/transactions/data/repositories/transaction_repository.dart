import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'transactions';

  Future<void> addTransaction(
    String userId,
    TransactionModel transaction,
  ) async {
    final userDoc = _firestore.collection('users').doc(userId);

    // Batch write to update transaction list and asset balance atomically
    final batch = _firestore.batch();

    // 1. Add Transaction
    final transactionRef = userDoc.collection(_collection).doc(transaction.id);
    batch.set(transactionRef, transaction.toJson());

    // 2. Update Asset Balance
    if (transaction.assetId != null) {
      final assetRef = userDoc.collection('assets').doc(transaction.assetId);

      if (transaction.type == TransactionType.transfer &&
          transaction.destinationAssetId != null) {
        // Transfer: Deduct from Source Asset, Add to Destination Asset
        batch.update(assetRef, {
          'balance': FieldValue.increment(-transaction.amount),
        });

        final destAssetRef = userDoc
            .collection('assets')
            .doc(transaction.destinationAssetId);
        batch.update(destAssetRef, {
          'balance': FieldValue.increment(transaction.amount),
        });
      } else {
        // Expense or Income
        // Income increases Asset balance (e.g. Salary -> Bank)
        // Expense decreases Asset balance (e.g. Lunch -> Wallet)
        double amountChange = transaction.type == TransactionType.income
            ? transaction.amount
            : -transaction.amount;
        batch.update(assetRef, {'balance': FieldValue.increment(amountChange)});
      }
    }

    await batch.commit();
  }

  Future<void> deleteTransaction(
    String userId,
    TransactionModel transaction,
  ) async {
    final userDoc = _firestore.collection('users').doc(userId);
    final batch = _firestore.batch();

    // 1. Delete Transaction
    final transactionRef = userDoc.collection(_collection).doc(transaction.id);
    batch.delete(transactionRef);

    // 2. Revert Asset Balance
    if (transaction.assetId != null) {
      final assetRef = userDoc.collection('assets').doc(transaction.assetId);

      if (transaction.type == TransactionType.transfer &&
          transaction.destinationAssetId != null) {
        // Revert Transfer: Refund Source, Deduct from Destination
        batch.update(assetRef, {
          'balance': FieldValue.increment(transaction.amount),
        });

        final destAssetRef = userDoc
            .collection('assets')
            .doc(transaction.destinationAssetId);
        batch.update(destAssetRef, {
          'balance': FieldValue.increment(-transaction.amount),
        });
      } else {
        // Revert Expense/Income
        // Income was +, so revert is -
        // Expense was -, so revert is +
        double amountChange = transaction.type == TransactionType.income
            ? -transaction.amount
            : transaction.amount;
        batch.update(assetRef, {'balance': FieldValue.increment(amountChange)});
      }
    }

    await batch.commit();
  }

  Future<void> updateTransaction(
    String userId,
    TransactionModel oldTransaction,
    TransactionModel newTransaction,
  ) async {
    final userDoc = _firestore.collection('users').doc(userId);
    final batch = _firestore.batch();

    // Helper to revert old transaction
    void revertOld() {
      if (oldTransaction.assetId != null) {
        final oldSource = userDoc
            .collection('assets')
            .doc(oldTransaction.assetId);

        if (oldTransaction.type == TransactionType.transfer &&
            oldTransaction.destinationAssetId != null) {
          // Revert Transfer
          batch.update(oldSource, {
            'balance': FieldValue.increment(oldTransaction.amount),
          });
          final oldDest = userDoc
              .collection('assets')
              .doc(oldTransaction.destinationAssetId);
          batch.update(oldDest, {
            'balance': FieldValue.increment(-oldTransaction.amount),
          });
        } else {
          // Revert Expense/Income
          final change = oldTransaction.type == TransactionType.income
              ? -oldTransaction.amount
              : oldTransaction.amount;
          batch.update(oldSource, {'balance': FieldValue.increment(change)});
        }
      }
    }

    // Helper to apply new transaction
    void applyNew() {
      if (newTransaction.assetId != null) {
        final newSource = userDoc
            .collection('assets')
            .doc(newTransaction.assetId);

        if (newTransaction.type == TransactionType.transfer &&
            newTransaction.destinationAssetId != null) {
          // Apply Transfer
          batch.update(newSource, {
            'balance': FieldValue.increment(-newTransaction.amount),
          });
          final newDest = userDoc
              .collection('assets')
              .doc(newTransaction.destinationAssetId);
          batch.update(newDest, {
            'balance': FieldValue.increment(newTransaction.amount),
          });
        } else {
          // Apply Expense/Income
          final change = newTransaction.type == TransactionType.income
              ? newTransaction.amount
              : -newTransaction.amount;
          batch.update(newSource, {'balance': FieldValue.increment(change)});
        }
      }
    }

    // Applying both separately (revert then apply)
    revertOld();
    applyNew();

    // Update Transaction
    final transactionRef = userDoc
        .collection(_collection)
        .doc(newTransaction.id);
    batch.set(transactionRef, newTransaction.toJson());

    await batch.commit();
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
