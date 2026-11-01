# LAUNDRYPRO UAE — COMPREHENSIVE INTERACTIVE CONTROL & FUNCTIONALITY REGISTER

## 1. Overview
This register documents every visible, interactive control across all 33 views of LaundryPro UAE, tracking its event triggers, underlying data queries, and target business workflows.

---

## 2. Interactive Control Register

| Control ID | Screen / Location | Control Type | Event Trigger | Bound Data Source / Repository | Action & Navigation Destination | Status |
|---|---|---|---|---|---|---|
| `TOPBAR_SEARCH` | Topbar (`AppShell`) | Search Bar / Trigger | Tap / Click / `Ctrl+K` | SQLite `orders`, `customers`, `inventory_items` | Opens `GlobalSearchDialog` with autocomplete | Verified |
| `TOPBAR_BRANCH` | Topbar (`AppShell`) | PopupMenuButton | Tap / Click | Local Configuration / `BranchService` | Switches active branch context (`MAIN BRANCH`, `MARINA`, etc.) | Verified |
| `TOPBAR_TERMINAL` | Topbar (`AppShell`) | PopupMenuButton | Tap / Click | Local Configuration / `TerminalService` | Switches active POS terminal (`T01`, `T02`, `T03`) | Verified |
| `TOPBAR_LANG` | Topbar (`AppShell`) | InkWell Pill | Tap / Click | `LocaleProvider` | Switches UI between English LTR and Arabic RTL | Verified |
| `TOPBAR_NOTIF` | Topbar (`AppShell`) | IconButton | Tap / Click | `NotificationService` | Navigates to `/notifications` | Verified |
| `DASH_DATE_FILTER` | Dashboard Header | PopupMenuButton | Tap / Click | `ReportsService` / `LocalBusinessDatabase` | Filters KPIs: Today, Yesterday, Last 7 Days, Month | Verified |
| `DASH_NEW_ORDER` | Dashboard Header | ElevatedButton | Tap / Click | POS Workflow | Direct navigation to `/pos` | Verified |
| `KPI_REVENUE` | Dashboard Metric Grid | `MetricCard` | Click / Tap | `orders` table aggregation | Drill-down navigation to `/reports` | Verified |
| `KPI_ORDERS` | Dashboard Metric Grid | `MetricCard` | Click / Tap | `orders` table aggregation | Drill-down navigation to `/pending` | Verified |
| `KPI_PRODUCTION` | Dashboard Metric Grid | `MetricCard` | Click / Tap | `orders` status count | Drill-down navigation to `/production` | Verified |
| `KPI_PICKUP` | Dashboard Metric Grid | `MetricCard` | Click / Tap | `orders` status count | Drill-down navigation to `/pending?status=ready` | Verified |
| `REV_CHART_HOVER` | Revenue Overview Chart | `InteractiveRevenueChart` | Mouse hover | SQLite 7-day revenue dataset | Renders glass tooltip with AED revenue, day & order counts | Verified |
| `REV_CHART_CLICK` | Revenue Overview Chart | `InteractiveRevenueChart` | Mouse tap / click | `reports` service | Drill-down navigation to `/reports` | Verified |
| `REV_CHART_PERIOD`| Revenue Overview Card | PopupMenuButton | Tap / Click | Range filter policy | Updates period between 7 days, 30 days, quarter | Verified |
| `PIPE_SEG_RCV` | Order Pipeline Bar | `InkWell` segment | Click / Tap | `orders` status = received | Navigates to `/production` filtered by Received | Verified |
| `PIPE_SEG_WASH` | Order Pipeline Bar | `InkWell` segment | Click / Tap | `orders` status = washing | Navigates to `/production` filtered by Washing | Verified |
| `PIPE_SEG_FIN` | Order Pipeline Bar | `InkWell` segment | Click / Tap | `orders` status = finishing | Navigates to `/production` filtered by Finishing | Verified |
| `PIPE_SEG_RDY` | Order Pipeline Bar | `InkWell` segment | Click / Tap | `orders` status = ready | Navigates to `/pending` filtered by Ready | Verified |
| `ORDERS_TABLE_ROW`| Recent Orders Section | TableRow / `InkWell` | Click / Tap | `orders` & `order_items` | Opens `OrderDetailDialog` with VAT breakdown & receipt print | Verified |
| `ORDERS_VIEW_ALL` | Recent Orders Header | `InkWell` action | Click / Tap | Sales Repository | Navigates to `/pending` live orders grid | Verified |
| `QA_NEW_CUST` | Quick Actions Panel | `_QuickActionHoverTile` | Click / Tap | Customer workflow | Navigates to `/customers` | Verified |
| `QA_PAYMENT` | Quick Actions Panel | `_QuickActionHoverTile` | Click / Tap | Invoices workflow | Navigates to `/pending` | Verified |
| `QA_STOCK_RCV` | Quick Actions Panel | `_QuickActionHoverTile` | Click / Tap | Inventory workflow | Navigates to `/inventory` | Verified |
| `GRID_SCROLL_V` | All Data Tables | `AppDataTable` | Mousewheel / Touch | `DataTable` | Vertical scroll with persistent trackpad thumb | Verified |
| `GRID_SCROLL_H` | All Data Tables | `AppDataTable` | Trackpad / Drag | `DataTable` | Horizontal scroll for multi-column enterprise tables | Verified |
