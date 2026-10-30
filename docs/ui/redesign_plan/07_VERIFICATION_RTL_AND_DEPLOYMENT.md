# LaundryPro UAE — Production Quality Gates & Verification Protocol
## Responsive Breakpoints, RTL Integrity, Offline Fault Tolerance & Deployment

---

# ⚠️ BOLD MANDATORY GOVERNANCE RULE: ZERO-TOLERANCE QUALITY AUDIT

> **IN EVERY SINGLE SESSION: SYSTEMATICALLY UPDATE ALL DOCS, DOUBLE-AUDIT AND RE-CHECK ALL TESTS, ALL CASES, ALL UI REFLOWS, AND ALL UX INTERACTIONS.**
> 
> **ZERO TOLERANCE: MINOR DEFECTS ARE NOT ALLOWED.**
> Every visual element, layout constraint, localization string, and interaction must pass exhaustive double-verification. Any clipped text, unhandled error, flex overflow, or cosmetic imperfection immediately fails the build gate.

---

### 1. Viewport Reflow Testing Matrix

Every screen must satisfy rigorous testing across 4 explicit desktop display resolutions without layout truncation, pixel overflow banners, or text clipping.

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              Responsive Test Matrix                                    │
├───────────────┬─────────────────────────┬──────────────────┬───────────────────────────┤
│ Tier          │ Resolution / Aspect     │ Sidebar Profile  │ Target Screen Assertions  │
├───────────────┼─────────────────────────┼──────────────────┼───────────────────────────┤
│ Tier 1: Wide  │ 1920 × 1080 (16:9 FHD)  │ 260px Expanded   │ • 4-Column Metric Cards   │
│               │ 2560 × 1440 (16:9 2K)   │ Full Brand Title │ • Dual 70/30 Mid Row      │
│               │                         │                  │ • Zero horizontal scroll  │
├───────────────┼─────────────────────────┼──────────────────┼───────────────────────────┤
│ Tier 2: Std   │ 1440 × 900 (16:10)      │ 260px Expanded   │ • 4-Column Metric Cards   │
│               │ 1366 × 768 (Commercial) │ Condensed padding│ • 70/30 Operational Row   │
│               │                         │                  │ • Tabular figures aligned │
├───────────────┼─────────────────────────┼──────────────────┼───────────────────────────┤
│ Tier 3: Comp  │ 1024 × 768 (POS Square) │ 76px Icon Rail   │ • 2×2 Grid Metric Cards   │
│               │ 1280 × 800 (Touch Term) │ Tooltips active  │ • Vertically Stacked Mid  │
│               │                         │                  │ • No RenderFlex overflow  │
├───────────────┼─────────────────────────┼──────────────────┼───────────────────────────┤
│ Tier 4: Touch │ 800 × 600 (Compact POS) │ Hidden Drawer    │ • 1-Column Metric Cards   │
│               │ Resized Window          │ Hamburger toggle │ • Tabbed Operational views│
└───────────────┴─────────────────────────┴──────────────────┴───────────────────────────┘
```

#### Automated Responsive Test Harness (`test/responsive_layout_test.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/core/design_system/responsive_layout.dart';

void main() {
  testWidgets('ResponsiveLayout selects correct tier across width transitions', (tester) async {
    // 1. Wide Desktop test
    tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveLayout(
          wide: Text('WIDE'),
          standard: Text('STANDARD'),
          compact: Text('COMPACT'),
          narrow: Text('NARROW'),
        ),
      ),
    );
    expect(find.text('WIDE'), findsOneWidget);

    // 2. Compact POS terminal test
    tester.binding.window.physicalSizeTestValue = const Size(1024, 768);
    await tester.pumpAndSettle();
    expect(find.text('COMPACT'), findsOneWidget);
  });
}
```

---

### 2. Bilingual RTL/LTR Integrity Protocols

When switching between English (`LTR`) and Arabic (`RTL`):

1. **Sidebar Mirroring:**
   - On English: Sidebar is pinned to the left edge of the screen (`0,0`).
   - On Arabic: Sidebar is pinned to the right edge (`Directionality(textDirection: TextDirection.rtl)`).
2. **Icon & Coordinate Orientation:**
   - Chevrons in table action rows, dropdowns, and navigation breadcrumbs automatically mirror (`Icons.chevron_right` -> `Icons.chevron_left`).
   - Breadcrumbs render as: `لوحة التحكم / مساحة العمل`.
3. **Tabular Numeral & Currency Invariance:**
   - Financial figures retain proper Western Arabic or Hindu-Arabic digit alignment with non-reversed decimal points: `AED 4,860.00` or `٤,٨٦٠.٠٠ د.إ`.
4. **Font Glyph Integrity:**
   - Swaps font family to `Noto Sans Arabic` without vertical ascender/descender clipping in buttons or inputs.

---

### 3. Local Offline Resilience & Error Isolation Contract

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        Local Fault Tolerance Lifecycle                                 │
├────────────────────────────┬─────────────────────────────┬─────────────────────────────┤
│ Fast Fetch (<500ms)        │ Degraded Latency (>2000ms)  │ Database/API Exception      │
├────────────────────────────┼─────────────────────────────┼─────────────────────────────┤
│ Direct UI update           │ Skeleton Shimmer Placeholder│ Load pre-cached SQLite data │
│ Full live metrics          │ Zero layout shift           │ Inline yellow warning dot   │
│ Zero visual disruption     │ Prevents UI freezing        │ Never shows red error banner│
└────────────────────────────┴─────────────────────────────┴─────────────────────────────┘
```

#### Absolute Rule for State Resilience:
- **No Global Error Overrides:** Never allow an unhandled API error in `Future.wait([today, period, inventory])` to throw a page-level red error banner.
- All service calls are wrapped with `.catchError((_) => DashboardMetricsModel.empty())` or cached fallback loaders.

---

### 4. Build, Packaging & Distribution Protocol

1. **Verify Static Code Analysis:**
   ```powershell
   flutter analyze
   ```
   Must pass with 0 errors and 0 critical warnings.
2. **Compile Windows Native Binary:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\build_windows.ps1
   ```
   Generates production bundle in `build\laundrypro_release\`.
3. **Package MSIX Installer:**
   - Automatically signs the Windows application package with the production manifest and certificates.

