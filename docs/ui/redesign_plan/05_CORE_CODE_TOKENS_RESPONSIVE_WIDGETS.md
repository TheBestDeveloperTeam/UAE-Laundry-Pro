# LaundryPro UAE — Design System Core Implementation Code
## Complete Dart Code: Design Tokens, Responsive Layout & Core Widgets

This document contains the complete, battle-tested source code for the fundamental design tokens, adaptive layout engine, and core atomic widgets to be implemented directly into `lib/core/design_system/` and `lib/widgets/`.

---

### File 1: `lib/core/design_system/app_tokens.dart`

```dart
// lib/core/design_system/app_tokens.dart
import 'dart:ui';
import 'package:flutter/material.dart';

/// Centralized Design Tokens for LaundryPro UAE Business OS.
/// Derived from approved design pack and production visual benchmark.
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
```

---

### File 2: `lib/core/design_system/responsive_layout.dart`

```dart
// lib/core/design_system/responsive_layout.dart
import 'package:flutter/material.dart';

enum DeviceScreenType {
  wideDesktop,     // >= 1600 px (Full 260px sidebar, 4-col KPI, dual wide work panels)
  standardDesktop, // 1280 to 1599 px (260px sidebar, 4-col KPI, 70/30 split)
  compactDesktop,  // 1024 to 1279 px (76px icon rail, 2x2 KPI, stacked analytics)
  narrow           // < 1024 px (Drawer navigation, 1-col cards, tabbed views)
}

/// Dynamic constraint-based responsive wrapper widget.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.standard,
    this.wide,
    this.compact,
    this.narrow,
  });

  final Widget standard;
  final Widget? wide;
  final Widget? compact;
  final Widget? narrow;

  static DeviceScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1600) return DeviceScreenType.wideDesktop;
    if (width >= 1280) return DeviceScreenType.standardDesktop;
    if (width >= 1024) return DeviceScreenType.compactDesktop;
    return DeviceScreenType.narrow;
  }

  static bool isCompactOrNarrow(BuildContext context) {
    return MediaQuery.of(context).size.width < 1280;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1600 && wide != null) {
          return wide!;
        }
        if (constraints.maxWidth >= 1280) {
          return standard;
        }
        if (constraints.maxWidth >= 1024 && compact != null) {
          return compact!;
        }
        return narrow ?? compact ?? standard;
      },
    );
  }
}
```

---

### File 3: `lib/widgets/metric_card.dart`

```dart
// lib/widgets/metric_card.dart
import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';

/// Hero KPI Metric Card with Sparkline & Context Indicator.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.badgeText,
    this.isPositive = true,
    this.sparklinePoints,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String? badgeText;
  final bool isPositive;
  final List<double>? sparklinePoints;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      hoverColor: AppTokens.surfaceHover,
      child: Container(
        padding: const EdgeInsets.all(AppTokens.space20),
        decoration: AppTokens.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTokens.space8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: AppTokens.metricLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (sparklinePoints != null && sparklinePoints!.isNotEmpty)
                  SizedBox(
                    width: 70,
                    height: 28,
                    child: CustomPaint(
                      painter: _MiniSparklinePainter(
                        points: sparklinePoints!,
                        color: accentColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.space8),
            Row(
              children: [
                if (badgeText != null) ...[
                  Text(
                    badgeText!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? AppTokens.statusReady : AppTokens.statusCancelled,
                    ),
                  ),
                  const SizedBox(width: AppTokens.space4),
                ],
                Expanded(
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTokens.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniSparklinePainter extends CustomPainter {
  _MiniSparklinePainter({required this.points, required this.color});
  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final min = points.reduce((a, b) => a < b ? a : b);
    final max = points.reduce((a, b) => a > b ? a : b);
    final range = (max - min) == 0 ? 1.0 : (max - min);

    final path = Path();
    final stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - ((points[i] - min) / range * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) => false;
}
```

---

### File 4: `lib/widgets/status_badge.dart`

```dart
// lib/widgets/status_badge.dart
import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';

enum OrderStage { received, washing, drying, finishing, ready, delivered, cancelled }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.stage,
    this.compact = false,
  });

  final String label;
  final OrderStage stage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    Color fg;
    Color bg;

    switch (stage) {
      case OrderStage.received:
        fg = AppTokens.statusReceived;
        bg = AppTokens.statusBgReceived;
        break;
      case OrderStage.washing:
      case OrderStage.drying:
        fg = AppTokens.statusWashing;
        bg = AppTokens.statusBgWashing;
        break;
      case OrderStage.finishing:
        fg = AppTokens.statusFinishing;
        bg = AppTokens.statusBgFinishing;
        break;
      case OrderStage.ready:
      case OrderStage.delivered:
        fg = AppTokens.statusReady;
        bg = AppTokens.statusBgReady;
        break;
      case OrderStage.cancelled:
        fg = AppTokens.statusCancelled;
        bg = AppTokens.statusBgCancelled;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppTokens.space8 : AppTokens.space12,
        vertical: compact ? AppTokens.space2 : AppTokens.space4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: fg.withOpacity(0.3), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTokens.space6 ?? 6),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### File 5: `lib/widgets/hardware_status_bar.dart`

```dart
// lib/widgets/hardware_status_bar.dart
import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';

class HardwareStatusBar extends StatelessWidget {
  const HardwareStatusBar({
    super.key,
    required this.isDbConnected,
    required this.isPrinterReady,
    required this.isScannerReady,
    required this.lastSyncTime,
    required this.version,
  });

  final bool isDbConnected;
  final bool isPrinterReady;
  final bool isScannerReady;
  final String lastSyncTime;
  final String version;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16),
      decoration: const BoxDecoration(
        color: AppTokens.surfacePrimary,
        border: Border(top: BorderSide(color: AppTokens.borderSubtle, width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildIndicator(
                isOk: isDbConnected,
                okLabel: 'Local database connected',
                errLabel: 'Database disconnected',
              ),
              const SizedBox(width: AppTokens.space16),
              _buildIndicator(
                isOk: isPrinterReady,
                okLabel: 'Printer ready',
                errLabel: 'Printer offline',
              ),
              const SizedBox(width: AppTokens.space16),
              _buildIndicator(
                isOk: isScannerReady,
                okLabel: 'Scanner ready',
                errLabel: 'Scanner inactive',
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.sync_rounded, size: 14, color: AppTokens.textMuted),
              const SizedBox(width: AppTokens.space4),
              Text(
                'Last sync: $lastSyncTime',
                style: const TextStyle(fontSize: 11, color: AppTokens.textMuted),
              ),
              const SizedBox(width: AppTokens.space16),
              Text(
                version,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator({required bool isOk, required String okLabel, required String errLabel}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: isOk ? AppTokens.statusReady : AppTokens.statusCancelled,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppTokens.space6 ?? 6),
        Text(
          isOk ? okLabel : errLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isOk ? AppTokens.textSecondary : AppTokens.statusCancelled,
          ),
        ),
      ],
    );
  }
}
```

