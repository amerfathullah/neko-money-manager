import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ledger.dart';
import '../../data/repositories/ledger_repository.dart';

final ledgerRepositoryProvider = Provider((ref) => LedgerRepository());

class LedgerNotifier extends AsyncNotifier<List<Ledger>> {
  @override
  Future<List<Ledger>> build() async {
    final repository = ref.read(ledgerRepositoryProvider);
    return repository.getLedgers();
  }

  Future<void> addLedger(Ledger ledger) async {
    await ref.read(ledgerRepositoryProvider).addLedger(ledger);
    ref.invalidateSelf();
  }

  Future<void> updateLedger(Ledger ledger) async {
    await ref.read(ledgerRepositoryProvider).updateLedger(ledger);
    ref.invalidateSelf();
  }

  Future<void> deleteLedger(String id) async {
    await ref.read(ledgerRepositoryProvider).deleteLedger(id);
    ref.invalidateSelf();
  }
}

final ledgerProvider = AsyncNotifierProvider<LedgerNotifier, List<Ledger>>(
  LedgerNotifier.new,
);

class SelectedLedgerNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) {
    state = value;
  }
}

final selectedLedgerProvider =
    NotifierProvider<SelectedLedgerNotifier, String?>(
      SelectedLedgerNotifier.new,
    );
