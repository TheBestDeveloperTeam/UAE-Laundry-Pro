import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors (Laundry Pro UAE Design System)
  static const Color primaryNavy = Color(0xFF0A2540);
  static const Color primaryNavyLight = Color(0xFF1B4B6B);

  static const Color accentCyan = Color(0xFF00D4FF);
  static const Color accentGreen = Color(0xFF00E5A0);
  static const Color accentGold = Color(0xFFFFB800);

  // Neutrals
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color lightMist = Color(0xFFF5F7FA);
  static const Color coolGray = Color(0xFFB0BEC5);
  static const Color darkSlate = Color(0xFF263238);

  // Semantic Colors
  static const Color errorRed = Color(0xFFFF4D4F);
  static const Color warningOrange = Color(0xFFFAAD14);
  static const Color infoBlue = Color(0xFF1890FF);
  static const Color successGreen = Color(0xFF52C41A);

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

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryNavy, primaryNavyLight],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentCyan, accentGreen],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x26FFFFFF), // rgba(255,255,255,0.15)
      Color(0x0DFFFFFF), // rgba(255,255,255,0.05)
    ],
  );

  // Box Shadows (Futuristic Glow)
  static List<BoxShadow> get subtleGlow => [
    BoxShadow(
      color: accentCyan.withOpacity(0.2),
      blurRadius: 4,
      spreadRadius: 0,
      offset: const Offset(0, 0),
    )
  ];

  static ThemeData get lightTheme {
    final TextTheme interTextTheme = GoogleFonts.interTextTheme();
    final TextTheme poppinsTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryNavy,
      scaffoldBackgroundColor: lightMist,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryNavy,
        primary: primaryNavy,
        secondary: accentCyan,
        tertiary: accentGreen,
        surface: pureWhite,
        error: errorRed,
      ),

      // Typography
      textTheme: interTextTheme.copyWith(
        displayLarge: poppinsTextTheme.displayLarge?.copyWith(color: primaryNavy, fontWeight: FontWeight.bold),
        displayMedium: poppinsTextTheme.displayMedium?.copyWith(color: primaryNavy, fontWeight: FontWeight.bold),
        displaySmall: poppinsTextTheme.displaySmall?.copyWith(color: primaryNavy, fontWeight: FontWeight.bold),
        headlineLarge: poppinsTextTheme.headlineLarge?.copyWith(color: primaryNavy, fontWeight: FontWeight.w600),
        headlineMedium: poppinsTextTheme.headlineMedium?.copyWith(color: primaryNavy, fontWeight: FontWeight.w600),
        headlineSmall: poppinsTextTheme.headlineSmall?.copyWith(color: primaryNavy, fontWeight: FontWeight.w600),
        titleLarge: poppinsTextTheme.titleLarge?.copyWith(color: primaryNavy, fontWeight: FontWeight.w600),
        titleMedium: poppinsTextTheme.titleMedium?.copyWith(color: primaryNavy, fontWeight: FontWeight.w600),
        titleSmall: poppinsTextTheme.titleSmall?.copyWith(color: primaryNavy, fontWeight: FontWeight.w600),
        bodyLarge: interTextTheme.bodyLarge?.copyWith(color: darkSlate),
        bodyMedium: interTextTheme.bodyMedium?.copyWith(color: darkSlate),
        bodySmall: interTextTheme.bodySmall?.copyWith(color: coolGray),
      ),

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: primaryNavy,
        foregroundColor: pureWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: pureWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4), // Subtle rounding as per brief
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: pureWhite,
        elevation: 2,
        shadowColor: primaryNavy.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pureWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: coolGray, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: coolGray, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: accentCyan, width: 2),
        ),
        labelStyle: const TextStyle(color: darkSlate),
        hintStyle: const TextStyle(color: coolGray),
      ),
    );
  }
}
