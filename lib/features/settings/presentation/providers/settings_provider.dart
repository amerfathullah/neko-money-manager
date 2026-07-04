import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/settings_repository.dart';

// Settings State Model
class SettingsState {
  final Locale locale;
  final int monthlyStartDate; // 1-28
  final int firstDayOfWeek; // 1 (Mon) - 7 (Sun)
  final bool useCommaSeparator;

  const SettingsState({
    this.locale = const Locale('en'),
    this.monthlyStartDate = 1,
    this.firstDayOfWeek = 7, // Default Sunday
    this.useCommaSeparator = true,
  });

  SettingsState copyWith({
    Locale? locale,
    int? monthlyStartDate,
    int? firstDayOfWeek,
    bool? useCommaSeparator,
  }) {
    return SettingsState(
      locale: locale ?? this.locale,
      monthlyStartDate: monthlyStartDate ?? this.monthlyStartDate,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      useCommaSeparator: useCommaSeparator ?? this.useCommaSeparator,
    );
  }
}

// Settings Repository Provider
final settingsRepositoryProvider = Provider((ref) => SettingsRepository());

// Settings Notifier
class SettingsNotifier extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    var currentState = const SettingsState();

    final repository = ref.read(settingsRepositoryProvider);
    final data = await repository.getSettings();

    if (data.isNotEmpty) {
      currentState = currentState.copyWith(
        locale: data['locale'] != null ? Locale(data['locale']) : null,
        monthlyStartDate: data['monthlyStartDate'],
        firstDayOfWeek: data['firstDayOfWeek'],
        useCommaSeparator: data['useCommaSeparator'],
      );
    }

    return currentState;
  }

  Future<void> setLocale(String languageCode) async {
    await ref.read(settingsRepositoryProvider).updateSettings({
      'locale': languageCode,
    });
    ref.invalidateSelf();
  }

  Future<void> setMonthlyStartDate(int day) async {
    await ref.read(settingsRepositoryProvider).updateSettings({
      'monthlyStartDate': day,
    });
    ref.invalidateSelf();
  }

  Future<void> setFirstDayOfWeek(int day) async {
    await ref.read(settingsRepositoryProvider).updateSettings({
      'firstDayOfWeek': day,
    });
    ref.invalidateSelf();
  }

  Future<void> setCommaSeparator(bool value) async {
    await ref.read(settingsRepositoryProvider).updateSettings({
      'useCommaSeparator': value,
    });
    ref.invalidateSelf();
  }

}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, SettingsState>(
      SettingsNotifier.new,
    );
