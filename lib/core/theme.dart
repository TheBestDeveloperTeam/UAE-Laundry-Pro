import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: primaryDark,
        surface: cardColor,
        background: background,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
      ),
    );
  }
}
