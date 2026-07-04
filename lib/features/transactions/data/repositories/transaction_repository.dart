import '../../../../core/services/database_service.dart';
import '../models/transaction_model.dart';
import '../../../assets/data/models/asset_history_model.dart';

class TransactionRepository {
  Future<void> addTransaction(TransactionModel transactionModel) async {
    final db = await DatabaseService.database;

    await db.transaction((txn) async {
      // Add Transaction
      await txn.insert('transactions', transactionModel.toJson());

      // Update Asset Balance & History
      if (transactionModel.assetId != null) {
        final change = transactionModel.type == TransactionType.income
            ? transactionModel.amount
            : -transactionModel.amount;
        await _updateAssetBalance(
          txn,
          transactionModel.assetId!,
          change,
          transactionModel.id,
          'transaction_add',
        );

        if (transactionModel.type == TransactionType.transfer &&
            transactionModel.destinationAssetId != null) {
          await _updateAssetBalance(
            txn,
            transactionModel.destinationAssetId!,
            transactionModel.amount,
            transactionModel.id,
            'transaction_add_transfer',
          );
        }
      }
    });
  }

  Future<void> deleteTransaction(TransactionModel transactionModel) async {
    final db = await DatabaseService.database;

    await db.transaction((txn) async {
      // Delete Transaction
      await txn.delete('transactions', where: 'id = ?', whereArgs: [transactionModel.id]);

      // Revert Asset Balance & History
      if (transactionModel.assetId != null) {
        final change = transactionModel.type == TransactionType.income
            ? -transactionModel.amount
            : transactionModel.amount;
        await _updateAssetBalance(
          txn,
          transactionModel.assetId!,
          change,
          transactionModel.id,
          'transaction_delete',
        );

        if (transactionModel.type == TransactionType.transfer &&
            transactionModel.destinationAssetId != null) {
          await _updateAssetBalance(
            txn,
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
    TransactionModel oldTransaction,
    TransactionModel newTransaction,
  ) async {
    final db = await DatabaseService.database;

    await db.transaction((txn) async {
      // Revert old transaction
      if (oldTransaction.assetId != null) {
        await _updateAssetBalance(
          txn,
          oldTransaction.assetId!,
          oldTransaction.type == TransactionType.income
              ? -oldTransaction.amount
              : oldTransaction.amount,
          newTransaction.id,
          'transaction_update_revert',
        );
      }
      if (oldTransaction.type == TransactionType.transfer &&
          oldTransaction.destinationAssetId != null) {
        await _updateAssetBalance(
          txn,
          oldTransaction.destinationAssetId!,
          -oldTransaction.amount,
          newTransaction.id,
          'transaction_update_revert_transfer',
        );
      }
      if (oldTransaction.reimbursedAssetId != null &&
          oldTransaction.reimbursedAmount != null) {
        await _updateAssetBalance(
          txn,
          oldTransaction.reimbursedAssetId!,
          -oldTransaction.reimbursedAmount!,
          newTransaction.id,
          'reimbursement_revert',
        );
      }

      // Apply new transaction
      if (newTransaction.assetId != null) {
        await _updateAssetBalance(
          txn,
          newTransaction.assetId!,
          newTransaction.type == TransactionType.income
              ? newTransaction.amount
              : -newTransaction.amount,
          newTransaction.id,
          'transaction_update_apply',
        );
      }
      if (newTransaction.type == TransactionType.transfer &&
          newTransaction.destinationAssetId != null) {
        await _updateAssetBalance(
          txn,
          newTransaction.destinationAssetId!,
          newTransaction.amount,
          newTransaction.id,
          'transaction_update_apply_transfer',
        );
      }
      if (newTransaction.reimbursedAssetId != null &&
          newTransaction.reimbursedAmount != null) {
        await _updateAssetBalance(
          txn,
          newTransaction.reimbursedAssetId!,
          newTransaction.reimbursedAmount!,
          newTransaction.id,
          'reimbursement_apply',
        );
      }

      // Update Transaction Doc
      await txn.update(
        'transactions',
        newTransaction.toJson(),
        where: 'id = ?',
        whereArgs: [newTransaction.id],
      );
    });
  }

  Future<void> _updateAssetBalance(
    dynamic txn,
    String assetId,
    double amountChange,
    String? transactionId,
    String reason,
  ) async {
    final assetRows = await txn.query('assets', where: 'id = ?', whereArgs: [assetId]);
    if (assetRows.isEmpty) return;

    final currentBalance = (assetRows.first['balance'] as num?)?.toDouble() ?? 0.0;
    final newBalance = currentBalance + amountChange;

    await txn.update('assets', {'balance': newBalance}, where: 'id = ?', whereArgs: [assetId]);

    final historyId = DateTime.now().millisecondsSinceEpoch.toString();
    final historyEntry = AssetHistoryModel(
      id: historyId,
      assetId: assetId,
      balance: newBalance,
      date: DateTime.now(),
      reason: reason,
      relatedTransactionId: transactionId,
    );
    await txn.insert('asset_history', historyEntry.toJson());
  }

  Future<List<TransactionModel>> getRecentTransactions({int limit = 10}) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map((m) => TransactionModel.fromJson(m)).toList();
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await DatabaseService.database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => TransactionModel.fromJson(m)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByLedger(
    String ledgerId, {
    int limit = 50,
  }) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'transactions',
      where: 'ledgerId = ?',
      whereArgs: [ledgerId],
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map((m) => TransactionModel.fromJson(m)).toList();
  }
}
