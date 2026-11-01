import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';

class AppTheme {
  // Brand Colors mapped directly to AppTokens
  static const Color primaryNavy = AppTokens.brandMidnight;
  static const Color primaryNavyLight = AppTokens.brandNavy;
  static const Color accentCyan = AppTokens.brandAqua;
  static const Color accentGreen = AppTokens.brandMint;
  static const Color accentGold = AppTokens.brandGold;

  // Neutrals
  static const Color pureWhite = AppTokens.surfacePrimary;
  static const Color lightMist = AppTokens.canvas;
  static const Color coolGray = AppTokens.borderSubtle;
  static const Color darkSlate = AppTokens.textPrimary;

  // Semantic Colors
  static const Color errorRed = AppTokens.statusCancelled;
  static const Color warningOrange = AppTokens.statusFinishing;
  static const Color infoBlue = AppTokens.statusWashing;
  static const Color successGreen = AppTokens.statusReady;

  // Semantic Aliases
  static const Color success = successGreen;
  static const Color info = infoBlue;
  static const Color pending = coolGray;
  static const Color warning = warningOrange;
  static const Color danger = errorRed;
  static const Color primary = primaryNavy;
  static const Color secondary = accentCyan;
  static const Color background = lightMist;
  static const Color cardColor = pureWhite;
  static const Color primaryDark = primaryNavy;
  static const Color primaryBlue = primaryNavyLight;
  static const Color accentTeal = AppTokens.brandTeal;
  static const Color secondaryGrey = darkSlate;

  // Box Shadows
  static List<BoxShadow> get subtleGlow => [
    BoxShadow(
      color: AppTokens.brandTeal.withValues(alpha: 0.15),
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    )
  ];

  static ThemeData get lightTheme {
    final TextTheme interTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      primaryColor: AppTokens.brandTeal,
      scaffoldBackgroundColor: AppTokens.canvas,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppTokens.brandTeal,
        onPrimary: Colors.white,
        secondary: AppTokens.brandAqua,
        onSecondary: Colors.white,
        error: AppTokens.statusCancelled,
        onError: Colors.white,
        surface: AppTokens.surfacePrimary,
        onSurface: AppTokens.textPrimary,
        surfaceContainerHighest: AppTokens.surfaceSubtle,
        outline: AppTokens.borderSubtle,
      ),

      // Typography
      textTheme: interTextTheme.copyWith(
        displayLarge: interTextTheme.displayLarge?.copyWith(color: AppTokens.textPrimary, fontWeight: FontWeight.bold),
        displayMedium: interTextTheme.displayMedium?.copyWith(color: AppTokens.textPrimary, fontWeight: FontWeight.bold),
        displaySmall: interTextTheme.displaySmall?.copyWith(color: AppTokens.textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: interTextTheme.headlineLarge?.copyWith(color: AppTokens.textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: interTextTheme.headlineMedium?.copyWith(color: AppTokens.textPrimary, fontWeight: FontWeight.w700),
        headlineSmall: interTextTheme.headlineSmall?.copyWith(color: AppTokens.textPrimary, fontWeight: FontWeight.w700),
        titleLarge: interTextTheme.titleLarge?.copyWith(color: AppTokens.textPrimary, fontWeight: FontWeight.w600),
        titleMedium: interTextTheme.titleMedium?.copyWith(color: AppTokens.textPrimary, fontWeight: FontWeight.w600),
        titleSmall: interTextTheme.titleSmall?.copyWith(color: AppTokens.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: interTextTheme.bodyLarge?.copyWith(color: AppTokens.textPrimary),
        bodyMedium: interTextTheme.bodyMedium?.copyWith(color: AppTokens.textSecondary),
        bodySmall: interTextTheme.bodySmall?.copyWith(color: AppTokens.textMuted),
      ),

      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.surfacePrimary,
        foregroundColor: AppTokens.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppTokens.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppTokens.textSecondary),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.brandTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppTokens.brandTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppTokens.surfacePrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          side: const BorderSide(color: AppTokens.borderSubtle, width: 1.0),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surfaceSubtle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.brandTeal, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppTokens.textSecondary, fontSize: 13),
        hintStyle: const TextStyle(color: AppTokens.textMuted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
