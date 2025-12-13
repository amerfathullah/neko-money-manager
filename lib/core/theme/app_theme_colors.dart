import 'package:flutter/material.dart';

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color background;
  final Color surface;
  final Color container;
  final Color buttonBackground;
  final Color subtleBorder;
  final Color text;
  final Color textSubtle;
  final Color inputBackground;

  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.container,
    required this.buttonBackground,
    required this.subtleBorder,
    required this.text,
    required this.textSubtle,
    required this.inputBackground,
  });

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? container,
    Color? buttonBackground,
    Color? subtleBorder,
    Color? text,
    Color? textSubtle,
    Color? inputBackground,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      container: container ?? this.container,
      buttonBackground: buttonBackground ?? this.buttonBackground,
      subtleBorder: subtleBorder ?? this.subtleBorder,
      text: text ?? this.text,
      textSubtle: textSubtle ?? this.textSubtle,
      inputBackground: inputBackground ?? this.inputBackground,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }
    return AppThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      container: Color.lerp(container, other.container, t)!,
      buttonBackground: Color.lerp(
        buttonBackground,
        other.buttonBackground,
        t,
      )!,
      subtleBorder: Color.lerp(subtleBorder, other.subtleBorder, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
    );
  }
}
