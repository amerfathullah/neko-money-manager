import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final currencyProvider = AsyncNotifierProvider<CurrencyNotifier, String>(
  CurrencyNotifier.new,
);

class CurrencyNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final repo = ref.read(settingsRepositoryProvider);
    final symbol = await repo.getCurrency();
    return symbol ?? '\$'; // Default if not set
  }

  Future<void> setCurrency(String symbol) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setCurrency(symbol);
    state = AsyncData(symbol);
  }
}
