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

    double amountChange = transaction.type == TransactionType.income
        ? transaction.amount
        : -transaction.amount;

    batch.update(ledgerRef, {'balance': FieldValue.increment(amountChange)});

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

    // Reverse logic: if it was income (added to balance), we subtract it.
    // If it was expense (subtracted from balance), we add it back.
    double amountChange = transaction.type == TransactionType.income
        ? -transaction.amount
        : transaction.amount;

    batch.update(ledgerRef, {'balance': FieldValue.increment(amountChange)});

    await batch.commit();
  }

  Future<void> updateTransaction(
    String userId,
    TransactionModel oldTransaction,
    TransactionModel newTransaction,
  ) async {
    final userDoc = _firestore.collection('users').doc(userId);
    final batch = _firestore.batch();

    // Revert old balance
    if (oldTransaction.ledgerId == newTransaction.ledgerId) {
      final ledgerRef = userDoc
          .collection('ledgers')
          .doc(oldTransaction.ledgerId);
      final oldNet = oldTransaction.type == TransactionType.income
          ? oldTransaction.amount
          : -oldTransaction.amount;
      final newNet = newTransaction.type == TransactionType.income
          ? newTransaction.amount
          : -newTransaction.amount;

      batch.update(ledgerRef, {
        'balance': FieldValue.increment(newNet - oldNet),
      });
    } else {
      // Revert old
      final oldLedgerRef = userDoc
          .collection('ledgers')
          .doc(oldTransaction.ledgerId);
      final oldNet = oldTransaction.type == TransactionType.income
          ? oldTransaction.amount
          : -oldTransaction.amount;
      batch.update(oldLedgerRef, {'balance': FieldValue.increment(-oldNet)});

      // Apply new
      final newLedgerRef = userDoc
          .collection('ledgers')
          .doc(newTransaction.ledgerId);
      final newNet = newTransaction.type == TransactionType.income
          ? newTransaction.amount
          : -newTransaction.amount;
      batch.update(newLedgerRef, {'balance': FieldValue.increment(newNet)});
    }

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
