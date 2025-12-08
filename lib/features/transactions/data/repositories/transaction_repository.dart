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

    // Batch write to update transaction list and ledger balance atomically
    final batch = _firestore.batch();

    // 1. Add Transaction
    final transactionRef = userDoc.collection(_collection).doc(transaction.id);
    batch.set(transactionRef, transaction.toJson());

    // 2. Update Ledger Balance
    // Note: This requires reading the ledger first or using increment if possible.
    // Ideally we should use a Transaction (Firestore Transaction) not just a Batch
    // to ensure consistency if multiple concurrent writes happen, but for this app Batch/Client-side logic might suffice for MVP.
    // However, FieldValue.increment is safer.

    final ledgerRef = userDoc.collection('ledgers').doc(transaction.ledgerId);

    if (transaction.type == TransactionType.transfer &&
        transaction.destinationLedgerId != null) {
      // Transfer: Deduct from Source, Add to Destination
      batch.update(ledgerRef, {
        'balance': FieldValue.increment(-transaction.amount),
      });

      final destLedgerRef = userDoc
          .collection('ledgers')
          .doc(transaction.destinationLedgerId);
      batch.update(destLedgerRef, {
        'balance': FieldValue.increment(transaction.amount),
      });
    } else {
      // Expense or Income
      double amountChange = transaction.type == TransactionType.income
          ? transaction.amount
          : -transaction.amount;
      batch.update(ledgerRef, {'balance': FieldValue.increment(amountChange)});
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

    // 2. Revert Ledger Balance
    final ledgerRef = userDoc.collection('ledgers').doc(transaction.ledgerId);

    if (transaction.type == TransactionType.transfer &&
        transaction.destinationLedgerId != null) {
      // Revert Transfer: Refund Source, Deduct from Destination
      batch.update(ledgerRef, {
        'balance': FieldValue.increment(transaction.amount),
      });

      final destLedgerRef = userDoc
          .collection('ledgers')
          .doc(transaction.destinationLedgerId);
      batch.update(destLedgerRef, {
        'balance': FieldValue.increment(-transaction.amount),
      });
    } else {
      // Revert Expense/Income
      double amountChange = transaction.type == TransactionType.income
          ? -transaction.amount
          : transaction.amount;
      batch.update(ledgerRef, {'balance': FieldValue.increment(amountChange)});
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
      if (oldTransaction.type == TransactionType.transfer &&
          oldTransaction.destinationLedgerId != null) {
        // Revert Transfer
        final oldSource = userDoc
            .collection('ledgers')
            .doc(oldTransaction.ledgerId);
        batch.update(oldSource, {
          'balance': FieldValue.increment(oldTransaction.amount),
        });
        final oldDest = userDoc
            .collection('ledgers')
            .doc(oldTransaction.destinationLedgerId);
        batch.update(oldDest, {
          'balance': FieldValue.increment(-oldTransaction.amount),
        });
      } else {
        // Revert Expense/Income
        final oldSource = userDoc
            .collection('ledgers')
            .doc(oldTransaction.ledgerId);
        final change = oldTransaction.type == TransactionType.income
            ? -oldTransaction.amount
            : oldTransaction.amount;
        batch.update(oldSource, {'balance': FieldValue.increment(change)});
      }
    }

    // Helper to apply new transaction
    void applyNew() {
      if (newTransaction.type == TransactionType.transfer &&
          newTransaction.destinationLedgerId != null) {
        // Apply Transfer
        final newSource = userDoc
            .collection('ledgers')
            .doc(newTransaction.ledgerId);
        batch.update(newSource, {
          'balance': FieldValue.increment(-newTransaction.amount),
        });
        final newDest = userDoc
            .collection('ledgers')
            .doc(newTransaction.destinationLedgerId);
        batch.update(newDest, {
          'balance': FieldValue.increment(newTransaction.amount),
        });
      } else {
        // Apply Expense/Income
        final newSource = userDoc
            .collection('ledgers')
            .doc(newTransaction.ledgerId);
        final change = newTransaction.type == TransactionType.income
            ? newTransaction.amount
            : -newTransaction.amount;
        batch.update(newSource, {'balance': FieldValue.increment(change)});
      }
    }

    // Applying both separately (revert then apply) is safer and easier to reason about
    // than complex diffing for transfers.
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
