import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/settings_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Settings State Model
class SettingsState {
  final Locale locale;
  final int monthlyStartDate; // 1-28
  final int firstDayOfWeek; // 1 (Mon) - 7 (Sun)
  final bool useCommaSeparator;
  final bool isBiometricEnabled;

  const SettingsState({
    this.locale = const Locale('en'),
    this.monthlyStartDate = 1,
    this.firstDayOfWeek = 7, // Default Sunday
    this.useCommaSeparator = true,
    this.isBiometricEnabled = false,
  });

  SettingsState copyWith({
    Locale? locale,
    int? monthlyStartDate,
    int? firstDayOfWeek,
    bool? useCommaSeparator,
    bool? isBiometricEnabled,
  }) {
    return SettingsState(
      locale: locale ?? this.locale,
      monthlyStartDate: monthlyStartDate ?? this.monthlyStartDate,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      useCommaSeparator: useCommaSeparator ?? this.useCommaSeparator,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
    );
  }
}

// Settings Repository Provider
final settingsRepositoryProvider = Provider((ref) => SettingsRepository());

// Settings Notifier
class SettingsNotifier extends StreamNotifier<SettingsState> {
  static const _keyBiometric = 'settings_biometric';

  @override
  Stream<SettingsState> build() async* {
    final prefs = await SharedPreferences.getInstance();
    final biometric = prefs.getBool(_keyBiometric) ?? false;
    // Default local state
    var currentState = SettingsState(isBiometricEnabled: biometric);
    yield currentState;

    final userId = ref.watch(userIdProvider);
    if (userId != null) {
      final repository = ref.read(settingsRepositoryProvider);

      await for (final data in repository.getSettingsStream(userId)) {
        if (data.isNotEmpty) {
          currentState = currentState.copyWith(
            locale: data['locale'] != null ? Locale(data['locale']) : null,
            monthlyStartDate: data['monthlyStartDate'],
            firstDayOfWeek: data['firstDayOfWeek'],
            useCommaSeparator: data['useCommaSeparator'],
          );
          yield currentState;
        }
      }
    }
  }

  Future<void> setLocale(String languageCode) async {
    final userId = ref.read(userIdProvider);
    if (userId != null) {
      await ref.read(settingsRepositoryProvider).updateSettings(userId, {
        'locale': languageCode,
      });
    }
    // Optimistic update handled by stream if online, but local state isn't directly mutable in StreamNotifier
    // unless we use a different pattern or rely on stream entirely.
    // For simplicity, we rely on the stream update.
  }

  Future<void> setMonthlyStartDate(int day) async {
    final userId = ref.read(userIdProvider);
    if (userId != null) {
      await ref.read(settingsRepositoryProvider).updateSettings(userId, {
        'monthlyStartDate': day,
      });
    }
  }

  Future<void> setFirstDayOfWeek(int day) async {
    final userId = ref.read(userIdProvider);
    if (userId != null) {
      await ref.read(settingsRepositoryProvider).updateSettings(userId, {
        'firstDayOfWeek': day,
      });
    }
  }

  Future<void> setCommaSeparator(bool value) async {
    final userId = ref.read(userIdProvider);
    if (userId != null) {
      await ref.read(settingsRepositoryProvider).updateSettings(userId, {
        'useCommaSeparator': value,
      });
    }
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometric, value);
    // Since this is local only, and we yield a stream, strictly speaking we should emit a new event.
    // However, StreamNotifier doesn't easily allow manual state emission mixed with stream.
    // We will force a rebuild/refresh to pick up the new local val.
    ref.invalidateSelf();
  }
}

final settingsProvider =
    StreamNotifierProvider<SettingsNotifier, SettingsState>(
      SettingsNotifier.new,
    );
