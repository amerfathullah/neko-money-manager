import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider(
  (ref) => TransactionRepository(),
);

class TransactionNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() async {
    final repository = ref.read(transactionRepositoryProvider);
    return repository.getRecentTransactions();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await ref.read(transactionRepositoryProvider).addTransaction(transaction);
    ref.invalidateSelf();
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    await ref.read(transactionRepositoryProvider).deleteTransaction(transaction);
    ref.invalidateSelf();
  }

  Future<void> updateTransaction(
    TransactionModel oldTransaction,
    TransactionModel newTransaction,
  ) async {
    await ref
        .read(transactionRepositoryProvider)
        .updateTransaction(oldTransaction, newTransaction);
    ref.invalidateSelf();
  }

  Future<void> toggleBookmark(TransactionModel transaction) async {
    final updatedTransaction = transaction.copyWith(
      isBookmarked: !transaction.isBookmarked,
    );
    await updateTransaction(transaction, updatedTransaction);
  }
}

final transactionProvider =
    AsyncNotifierProvider<TransactionNotifier, List<TransactionModel>>(
      TransactionNotifier.new,
    );

final ledgerTransactionsProvider =
    FutureProvider.family<List<TransactionModel>, String>((ref, ledgerId) {
      final repository = ref.watch(transactionRepositoryProvider);
      return repository.getTransactionsByLedger(ledgerId);
    });

final allTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getAllTransactions();
});
