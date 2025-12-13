import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import 'app_theme_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.pastelPink,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      extensions: const [
        AppThemeColors(
          background: AppColors.backgroundLight,
          surface: AppColors.surfaceCream,
          container: AppColors.containerBeige,
          buttonBackground: AppColors.buttonBeige,
          subtleBorder: AppColors.borderBeige,
          text: AppColors.textDark,
          textSubtle: Color(0xFF666666), // Dark Grey
          inputBackground: AppColors.inputBeige,
        ),
      ],
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pastelPink,
        brightness: Brightness.light,
        surface: AppColors.backgroundLight,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
        fontFamilyFallback: ['NotoSans', 'NotoColorEmoji', 'NotoSansSymbols'],
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textDark),
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.backgroundLight,
        indicatorColor: AppColors.pastelPink.withValues(alpha: 0.3),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.all(
          const IconThemeData(color: AppColors.textDark),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pastelPink,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textDark,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.pastelPurple,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      extensions: const [
        AppThemeColors(
          background: AppColors.backgroundDark,
          surface: AppColors.surfaceDark,
          container: AppColors.containerDark,
          buttonBackground: AppColors.buttonDark,
          subtleBorder: AppColors.borderDark,
          text: AppColors.textLight,
          textSubtle: Color(0xFFAAAAAA), // Light Grey
          inputBackground: AppColors.inputDark,
        ),
      ],
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pastelPurple,
        brightness: Brightness.dark,
        surface: AppColors.backgroundDark,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textLight,
        displayColor: AppColors.textLight,
        fontFamilyFallback: ['NotoSans', 'NotoColorEmoji', 'NotoSansSymbols'],
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textLight),
        titleTextStyle: TextStyle(
          color: AppColors.textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: AppColors.pastelPurple.withValues(alpha: 0.3),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.all(
          const IconThemeData(color: AppColors.textLight),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pastelPurple,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textLight,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
