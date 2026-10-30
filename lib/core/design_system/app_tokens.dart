import 'package:flutter/material.dart';

/// Centralized Design Tokens for LaundryPro UAE Business OS.
/// Zero-Tolerance Contract: No hardcoded hex colors, magic numbers, or arbitrary dimensions allowed.
abstract class AppTokens {
  // ==========================================
  // BRAND DARK PALETTE (Sidebar, Chrome, Modal)
  // ==========================================
  static const Color brandMidnight    = Color(0xFF081426); // Primary app background / window chrome
  static const Color brandNavy        = Color(0xFF0D1E36); // Sidebar base color
  static const Color brandNavyActive  = Color(0xFF132B4C); // Sidebar item hover / secondary dark
  static const Color brandSurfaceDark = Color(0xFF1E2E42); // Elevated dark cards / popovers
  static const Color brandNavyBorder  = Color(0xFF223854); // Subtle dark dividers

  // ==========================================
  // BRAND ACTION ACCENTS (Teal / Aqua / Mint)
  // ==========================================
  static const Color brandTeal        = Color(0xFF00A896); // Primary accessible action & active pill
  static const Color brandTealHover   = Color(0xFF029282); // Primary button hover
  static const Color brandAqua        = Color(0xFF02C39A); // Secondary accent & chart lines
  static const Color brandMint        = Color(0xFF65DFC2); // Positive progress indicators
  static const Color brandGold        = Color(0xFFF4A261); // Sparkle / attention accents

  // ==========================================
  // WORKSPACE NEUTRALS (Low-glare canvas)
  // ==========================================
  static const Color canvas           = Color(0xFFF4F7FB); // Main workspace body background
  static const Color surfacePrimary   = Color(0xFFFFFFFF); // Cards, tables, modals
  static const Color surfaceSubtle    = Color(0xFFF8FAFC); // Table header, inputs, secondary zones
  static const Color surfaceHover     = Color(0xFFF1F5F9); // Row hover state
  static const Color surfaceSelected  = Color(0xFFE8F6F5); // Selected item / row highlight

  // ==========================================
  // BORDERS & DIVIDERS
  // ==========================================
  static const Color borderSubtle     = Color(0xFFE2E8F0); // Default card & table borders
  static const Color borderStrong     = Color(0xFFCBD5E1); // Focused input & strong boundaries

  // ==========================================
  // TYPOGRAPHY COLOR PALETTE
  // ==========================================
  static const Color textPrimary      = Color(0xFF0F172A); // Main headings, metrics, high emphasis
  static const Color textSecondary    = Color(0xFF475569); // Labels, subtitles, table data
  static const Color textMuted        = Color(0xFF94A3B8); // Timestamps, captions, metadata
  static const Color textInverse      = Color(0xFFFFFFFF); // Text on dark navy or teal surfaces

  // ==========================================
  // OPERATIONAL PIPELINE & STATUS COLORS
  // ==========================================
  static const Color statusReceived   = Color(0xFF00A896); // Order intake
  static const Color statusWashing    = Color(0xFF3B82F6); // Wash cycle active
  static const Color statusFinishing  = Color(0xFFF59E0B); // Pressing / QC
  static const Color statusReady      = Color(0xFF10B981); // Bagged / Ready for pickup
  static const Color statusCancelled  = Color(0xFFEF4444); // Voided / Urgent alert
  static const Color statusOverdue    = Color(0xFFDC2626); // Late turnaround

  // Soft Background Tints for Status Pills
  static const Color statusBgReceived = Color(0xFFE6F7F5);
  static const Color statusBgWashing  = Color(0xFFEFF6FF);
  static const Color statusBgFinishing= Color(0xFFFFFBEB);
  static const Color statusBgReady    = Color(0xFFECFDF5);
  static const Color statusBgCancelled= Color(0xFFFEF2F2);

  // ==========================================
  // SPACING SCALE (Pixels)
  // ==========================================
  static const double space2  = 2.0;
  static const double space4  = 4.0;
  static const double space6  = 6.0;
  static const double space8  = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // ==========================================
  // CORNER RADII (Pixels)
  // ==========================================
  static const double radiusSmall  = 6.0;  // Tags, status pills, small inputs
  static const double radiusMedium = 10.0; // Standard buttons, nested containers
  static const double radiusLarge  = 14.0; // Major cards, modals, tables
  static const double radiusPill   = 999.0;// Full round pill tags

  // ==========================================
  // TYPOGRAPHY STYLES
  // ==========================================
  static const TextStyle metricLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    color: textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle pageHeading = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: textPrimary,
  );

  static const TextStyle sectionHeading = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: textPrimary,
  );

  static const TextStyle bodyRegular = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: textMuted,
  );

  static const TextStyle groupLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: textMuted,
  );

  // ==========================================
  // ELEVATION & CARD DECORATIONS
  // ==========================================
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surfacePrimary,
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: borderSubtle, width: 1.0),
    boxShadow: const [
      BoxShadow(
        color: Color(0x06081426),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration darkCardDecoration = BoxDecoration(
    color: brandSurfaceDark,
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: brandNavyBorder, width: 1.0),
    boxShadow: const [
      BoxShadow(
        color: Color(0x1A000000),
        blurRadius: 16,
        offset: Offset(0, 6),
      ),
    ],
  );
}

