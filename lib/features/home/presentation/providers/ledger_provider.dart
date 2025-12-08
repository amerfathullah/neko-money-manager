import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ledger.dart';
import '../../data/repositories/ledger_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final ledgerRepositoryProvider = Provider((ref) => LedgerRepository());

class LedgerNotifier extends StreamNotifier<List<Ledger>> {
  @override
  Stream<List<Ledger>> build() {
    final userId = ref.watch(userIdProvider);
    if (userId == null) {
      return Stream.value([]);
    }
    final repository = ref.read(ledgerRepositoryProvider);
    return repository.getLedgers(userId);
  }

  Future<void> addLedger(Ledger ledger) async {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    await ref.read(ledgerRepositoryProvider).addLedger(userId, ledger);
  }

  Future<void> updateLedger(Ledger ledger) async {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    await ref.read(ledgerRepositoryProvider).updateLedger(userId, ledger);
  }

  Future<void> deleteLedger(String id) async {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    await ref.read(ledgerRepositoryProvider).deleteLedger(userId, id);
  }
}

final ledgerProvider = StreamNotifierProvider<LedgerNotifier, List<Ledger>>(
  LedgerNotifier.new,
);
