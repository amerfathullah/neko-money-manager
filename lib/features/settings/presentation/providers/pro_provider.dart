import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final proProvider = AsyncNotifierProvider<ProNotifier, bool>(ProNotifier.new);

class ProNotifier extends AsyncNotifier<bool> {
  static const _keyIsPro = 'is_pro';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsPro) ?? false;
  }

  Future<void> upgradeToPro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPro, true);
    state = const AsyncData(true);
  }

  Future<void> downgradeToFree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPro, false);
    state = const AsyncData(false);
  }
}
