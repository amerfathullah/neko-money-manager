import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final transactionRepositoryProvider = Provider(
  (ref) => TransactionRepository(),
);

class TransactionNotifier extends StreamNotifier<List<TransactionModel>> {
  @override
  Stream<List<TransactionModel>> build() {
    final userId = ref.watch(userIdProvider);
    if (userId == null) {
      return Stream.value([]);
    }
    final repository = ref.read(transactionRepositoryProvider);
    return repository.getRecentTransactions(userId);
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    await ref
        .read(transactionRepositoryProvider)
        .addTransaction(userId, transaction);
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    await ref
        .read(transactionRepositoryProvider)
        .deleteTransaction(userId, transaction);
  }
}

final transactionProvider =
    StreamNotifierProvider<TransactionNotifier, List<TransactionModel>>(
      TransactionNotifier.new,
    );

final ledgerTransactionsProvider =
    StreamProvider.family<List<TransactionModel>, String>((ref, ledgerId) {
      final userId = ref.watch(userIdProvider);
      if (userId == null) return Stream.value([]);

      final repository = ref.watch(transactionRepositoryProvider);
      return repository.getTransactionsByLedger(userId, ledgerId);
    });
