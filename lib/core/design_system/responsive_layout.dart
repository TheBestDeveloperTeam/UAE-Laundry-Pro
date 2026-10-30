import 'package:flutter/material.dart';

enum DeviceScreenType {
  wideDesktop,     // >= 1600 px (Full 260px sidebar, 4-col KPI, dual wide work panels)
  standardDesktop, // 1280 to 1599 px (260px sidebar, 4-col KPI, 70/30 split)
  compactDesktop,  // 1024 to 1279 px (76px icon rail, 2x2 KPI, stacked analytics)
  narrow           // < 1024 px (Drawer navigation, 1-col cards, tabbed views)
}

/// Dynamic constraint-based responsive wrapper widget.
/// Zero-Tolerance Rule: Prevents unconstrained RenderFlex overflows and ensures fluid reflow across all desktop tiers.
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

