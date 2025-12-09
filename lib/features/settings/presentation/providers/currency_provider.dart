import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/settings_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final currencyProvider = AsyncNotifierProvider<CurrencyNotifier, String>(
  CurrencyNotifier.new,
);

class CurrencyNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) {
      return '\$'; // Default if not logged in
    }

    final repo = ref.read(settingsRepositoryProvider);
    final symbol = await repo.getCurrency(user.uid);
    return symbol ?? '\$'; // Default if not set in DB
  }

  Future<void> setCurrency(String symbol) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;

    final repo = ref.read(settingsRepositoryProvider);
    await repo.setCurrency(user.uid, symbol);
    state = AsyncData(symbol);
  }
}
