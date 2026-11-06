# Custom Kinetic Widgets & Component Catalog
**Package:** `laundrypro_uae/widgets`  
**Standard:** Pure Flutter Custom Code Only. Zero External Widget Dependencies.

---

## 1. Widget Hierarchy & Component Index

### 1.1 `Futuristic3dCard` (`futuristic_3d_card.dart`)
- **Purpose:** Matrix4 3D perspective tilt container with cursor position tracking and animated specular sheen sweeps.
- **Properties:**
  - `accentColor`: Base accent for specular sheen and dynamic border highlight.
  - `borderRadius`: Uniform corner radius (default: `16.0`).
  - `maxTilt`: Maximum rotational deflection in radians (default: `0.08`).
- **Events:** `PointerEvent` hover tracking via `package:flutter/gestures.dart`.

### 1.2 `MetricCard` (`metric_card.dart`)
- **Purpose:** Hero KPI metric presentation with embedded Bézier vector sparkline and 3D kinetic tilt.
- **Properties:** `title`, `value`, `subtitle`, `icon`, `accentColor`, `sparklinePoints`, `badgeText`, `isPositive`.
- **Micro-Interactions:** Smooth hover elevation, endpoint circular pulse, tabular numbers rendering.

### 1.3 `BrandVectorEmblem` (`brand_vector_emblem.dart`)
- **Purpose:** Mathematically drawn scalable brand mark for LaundryPro UAE.
- **Composition:** Dual vortex Bézier curves, outer squircle gradient, and center Imperial Gold UAE star. Zero raster PNG/JPG dependencies.

### 1.4 `InteractiveRevenueChart` (`interactive_revenue_chart.dart`)
- **Purpose:** Custom-painted Bézier area chart with continuous pointer cursor tracking, vertical timeline guide, dynamic midnight-navy glass tooltips (`Sat-Fri`, `AED revenue`, `orders`), and drill-down navigation callbacks.

### 1.5 `AppDataTable` (`app_data_table.dart`)
- **Purpose:** High-density enterprise data table supporting 10,000+ records.
- **Architecture:** Dual synchronized vertical and horizontal `Scrollbar` widgets with dedicated, disposed `ScrollController` instances preventing competing controller assertions.

### 1.6 `GlobalSearchDialog` (`global_search_dialog.dart`)
- **Purpose:** Omnipresent `Ctrl+K` command palette.
- **Features:** Live SQLite multi-table fuzzy search (`orders`, `customers`, `inventory_items`), keyboard navigation, instant drill-down routing.

### 1.7 `OrderDetailDialog` (`order_detail_dialog.dart`)
- **Purpose:** Deep inspection modal for order line items, UAE VAT calculation breakdown, status badges, and ESC/POS thermal receipt printing.

