# LaundryPro UAE — Screen-by-Screen Zero-Loss Re-Architecture Specifications
## Modules 1 through 11 (Workspace, Point of Sale, Core Operations & Catalog)

---

### 5.1 Dashboard Screen (`lib/views/dashboard_screen.dart`)

The Dashboard is the operational flight deck of the laundry business. It replaces all legacy hardcoded cards with dynamic, responsive, and resilient telemetry matching the benchmark image (`docs/ui/benchmark_target_dashboard.jpg`).

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ Good morning, Sarah               Here's your branch at a glance. [Today v] [+ New Order]│
├────────────────────────────────────────────────────────────────────────────────────────┤
│ [ $ Today's Revenue ] [ 目 Orders Today ] [ ⚙ In Production  ] [ 🛍 Ready for Pickup ] │
│   AED 4,860.00          42                  18                  7                      │
│   +12.8% vs yesterday   8 new since 9 AM    Across 4 stages     3 awaiting collection  │
│   [~~~Sparkline~~~]     [~~~Sparkline~~~]   [~~~Sparkline~~~]   [~~~Sparkline~~~]      │
├──────────────────────────────────────────────────────┬─────────────────────────────────┤
│ Revenue Overview [Last 7 days v]                     │ Order Pipeline (42 total today) │
│ AED 28,640   ↗ +8.4%                                 │ [====][======][========][=====] │
│ [ Smooth Gradient Area Chart - Sat to Fri ]          │ Received:  9 (21.4%)            │
│                                                      │ Washing:  12 (28.6%)            │
│                                                      │ Finishing: 14 (33.3%)           │
│                                                      │ Ready:     7 (16.7%)            │
├──────────────────────────────────────────────────────┼─────────────────────────────────┤
│ Recent Orders [View all ->]                          │ Quick Actions                   │
│ ORDER    CUSTOMER    SERVICE    DUE     STATUS TOTAL │ > New Customer                  │
│ LP-10482 Aisha Khan  Wash&Fold 10:30 AM Ready  86.00 │ > Record Payment                │
│ LP-10481 Omar Hassan Dry Clean 11:00 AM Finish 145.0 │ > Stock Receive                 │
│ LP-10480 Mariam Ali  Abaya Care11:30 AM Washing 72.0 │                                 │
│ LP-10479 Zayd Ahmed  Press     12:00 PM Receive 55.0 │                                 │
└──────────────────────────────────────────────────────┴─────────────────────────────────┘
```

#### Detailed Architecture & State Specifications
1. **Greeting & Control Bar:**
   - Dynamic time-aware greeting (`Good morning`, `Good afternoon`, `Good evening`, or localized Arabic equivalent `صباح الخير` / `مساء الخير`) combined with the logged-in user's first name.
   - Subtitle: `Here's your branch at a glance.`
   - Filter Control: Date-range selector dropdown (`Today`, `Yesterday`, `This week`, `Last 7 days`, `This month`).
   - Primary Call-to-Action: High-emphasis Teal button `+ New Order` navigating directly to `/pos`.
2. **Hero Metric Cards (4 Columns Fluid Reflow):**
   - **Card 1: Today's Revenue**:
     - Format: Tabular currency `AED 4,860.00`.
     - Context Pill: Positive green badge `+12.8% vs yesterday` (calculated from yesterday's closing sales).
     - Visual: Aqua trendline sparkline canvas embedded in the lower right.
     - OnClick: Navigates to `/reports` with date filtered to today.
   - **Card 2: Orders Today**:
     - Format: Tabular integer `42`.
     - Context Pill: Subtitle `8 new since 9 AM`.
     - Visual: Cyan upward sparkline.
     - OnClick: Navigates to `/pending` (Live Orders list).
   - **Card 3: In Production**:
     - Format: Tabular integer `18`.
     - Context Pill: Warning amber status indicator `Across 4 stages`.
     - Visual: Amber activity sparkline.
     - OnClick: Navigates to `/production`.
   - **Card 4: Ready for Pickup**:
     - Format: Tabular integer `7`.
     - Context Pill: Green badge `3 awaiting collection > 24h`.
     - Visual: Emerald completion sparkline.
     - OnClick: Navigates to `/pending?filter=ready`.
3. **Mid Workspace Analytics Grid (70% / 30% Flex Split):**
   - **Left Panel (70%): Revenue Overview**:
     - Card Header: Section title with total sum `AED 28,640` and net percentage trajectory `↗ +8.4%`.
     - Interactive Date Scope Pill: `Last 7 days ▾`.
     - Custom Painted Area Chart: Smooth cubic bezier curve with translucent teal-to-transparent vertical gradient fill. Day labels on X-axis (`Sat`, `Sun`, `Mon`, `Tue`, `Wed`, `Thu`, `Fri`), currency scale on Y-axis (`0`, `4K`, `8K`, `12K`). Tooltip overlay on hover showing exact day revenue.
   - **Right Panel (30%): Order Pipeline Breakdown**:
     - Card Header: Section title with total count badge `42 total today`.
     - Visual Segment Bar: Multi-colored continuous rounded progress bar segmented proportionately:
       - `Received`: Cyan `#00A896` (9 items / 21.4%)
       - `Washing`: Blue `#3B82F6` (12 items / 28.6%)
       - `Finishing`: Amber `#F59E0B` (14 items / 33.3%)
       - `Ready`: Emerald `#10B981` (7 items / 16.7%)
     - Breakdown List: Vertical items with color dot, stage title, absolute count, and percentage share.
4. **Lower Operational Grid (70% / 30% Flex Split):**
   - **Left Panel (70%): Recent Orders Queue**:
     - Clean modern data table with zero vertical borders, hover row highlight (`AppTokens.surfaceHover`).
     - Columns: `ORDER #` (Bold monospace `LP-10482`), `CUSTOMER` (Customer full name), `SERVICE` (Primary service name), `DUE TIME` (Time badge), `STATUS` (Pill badge matching stage color), `TOTAL` (Right-aligned tabular currency `AED 86.00`), `ACTION` (Chevron navigate to order modal).
     - Trailing link: `View all →` linking to `/pending`.
   - **Right Panel (30%): Quick Actions Panel**:
     - Section title with lightning bolt icon.
     - 3 prominent full-width action tiles with leading rounded icon containers, title, and trailing chevron:
       1. `New Customer` (Opens fast customer registration dialog).
       2. `Record Payment` (Opens receipt of payment dialog for outstanding balance).
       3. `Stock Receive` (Opens quick inventory replenishment intake).
5. **Resilient Failure Handling:**
   - Replaces the legacy full-screen red fatal banner with per-card inline retry badges.
   - If MySQL or local API is temporarily busy, previous metrics are loaded from local cache (`AppTokens.surfaceHover`) with a subtle yellow dot indicating `Cached Data`.

---

### 5.2 Point of Sale & Quick Billing Screen (`lib/views/pos_screen.dart`)

The POS screen is the revenue generation engine of the laundry workstation. It handles high-speed counter intake, barcode scanning, item categorization, pricing modifiers, fast payment settlement, and instant ESC/POS receipt generation.

```
┌────────────────────────────────────────────────────────────────────────┐
│ POS Counter Intake                     Order #LP-2026-9041 [Hold Order]│
├───────────────────────────────────┬────────────────────────────────────┤
│ [Search services or garments...]   │ Customer: Aisha Khan (+971 50 ...) │
├───────────────────────────────────┤ [ Change ] [ Balance: AED 0.00 ]   │
│ [ All ] [Men] [Women] [Household] ├────────────────────────────────────┤
│ ┌────────┐ ┌────────┐ ┌────────┐  │ Order Items (3)                    │
│ │ Shirt  │ │ Suit   │ │ Abaya  │  │ 1x Men Shirt (Wash & Press) 15.00 │
│ │Wash&Iron│ │Dry Clean│ │Special │  │ 1x Abaya Luxury Care       45.00 │
│ │AED 15  │ │AED 45  │ │AED 45  │  │ 1x Wool Blanket (Dry Clean)26.00 │
│ └────────┘ └────────┘ └────────┘  ├────────────────────────────────────┤
│ ┌────────┐ ┌────────┐ ┌────────┐  │ Subtotal:                 AED 86.00│
│ │ Trouser│ │ Kurta  │ │ Bedding│  │ VAT (5% FTA):              AED 4.30│
│ │Wash&Iron│ │Steam   │ │Wash&Dry│  │ Discount:                  AED 0.00│
│ │AED 18  │ │AED 25  │ │AED 35  │  │ ───────────────────────────────────│
│ └────────┘ └────────┘ └────────┘  │ Net Payable:              AED 90.30│
│                                   ├────────────────────────────────────┤
│ [ Barcode Input / Scale Weight ]  │ [ Cash ] [ Card ] [ Credit / Later]│
│                                   │ [ Pay & Print Receipt (F12) ]      │
└───────────────────────────────────┴────────────────────────────────────┘
```

#### Detailed Architecture & State Specifications
1. **Layout Splitting:**
   - **Left Panel (60%): Interactive Catalog Grid & Quick Select**:
     - Fast Search Header: Input field with barcode scanner integration (listens to direct USB scanner key strokes).
     - Category Pills: `All Services`, `Men's Wear`, `Women's Wear`, `Traditional & Abaya`, `Bedding & Household`, `Express Wash`.
     - Item Grid: Responsive card grid (3 to 5 columns depending on display width). Each card features a garment icon, service title, turnaround indicator, and pricing tag.
     - Fast Modifier Dialog: Clicking an item pops a frictionless overlay to toggle:
       - Service Type: `Normal Wash & Iron`, `Dry Clean Only`, `Steam Press Only`, `Stain Treatment`.
       - Special Instructions: `Heavy Starch`, `No Starch`, `Hanger`, `Folded`, `Fragile Fabric`.
   - **Right Panel (40%): Active Cart & Fast Checkout Drawer**:
     - Customer Header Tile: Displays assigned customer, phone number, loyalty stars, and credit balance. Includes a `+ New Customer` quick modal button.
     - Itemized Cart List: Clean list showing garment name, service variant, unit price, quantity stepper (`-`, `qty`, `+`), total line price, and item delete button.
     - Live Financial Summary:
       - Subtotal (Tax Exclusive)
       - UAE FTA VAT (5.00% automatically computed)
       - Promotional Discount Field (Coupon or manual authorized % markdown)
       - Total Amount Due in large, high-contrast tabular typography.
     - Fast Payment Method Selector:
       - `Cash` (With quick-denomination buttons: Exact, AED 50, AED 100, AED 200, AED 500, and change calculator).
       - `Card / POS Terminal` (Records card auth reference).
       - `Customer Credit / Account` (Checks available credit limit).
       - `Pay on Collection / Delivery`.
     - Action Buttons:
       - Primary: `Pay & Print Receipt` (Hot-keyed to `F12`, sends formatted ESC/POS raw bytes to configured thermal printer).
       - Secondary: `Save / Hold Order` (`F4`).
       - Tertiary: `Clear Cart` (`Esc`).

---

### 5.3 Live Orders & Pending Invoices (`lib/views/pending_invoices_screen.dart`)

The central dispatch and collection hub for all outstanding tickets.

```
┌────────────────────────────────────────────────────────────────────────┐
│ Live Orders & Pending Invoices            [ Export Excel ] [+ New Order]│
├────────────────────────────────────────────────────────────────────────┤
│ [Search order #, customer, phone...]  [All Stages v] [All Payments v]  │
├────────────────────────────────────────────────────────────────────────┤
│ ORDER ID  CUSTOMER    ITEMS INTAKE   DUE DATE   STAGE    PAYMENT TOTAL │
│ LP-10490  Hassan Ali    4   Today    Tomorrow   Washing  Unpaid  120.00│
│ LP-10489  Fatima Noor   8   Today    30 Oct     Finish   Paid    340.00│
│ LP-10488  Rashid Al-M   2   YesterdayToday      Ready    Partial  65.00│
│ LP-10487  Sarah Jenkins 1   28 Oct   Overdue    Ready    Unpaid   45.00│
└────────────────────────────────────────────────────────────────────────┘
```

#### Detailed Architecture & State Specifications
1. **Interactive Filter Toolbar:**
   - Multi-parameter search bar with debounce (Customer Name, Order Number, Phone Number, Garment Tag ID).
   - Stage Dropdown: `All Stages`, `Received`, `Washing`, `Drying`, `Finishing / Press`, `Ready for Pickup`, `Delivered`.
   - Payment Status Filter: `All`, `Fully Paid`, `Partially Paid`, `Unpaid / Credit`.
   - Date Filter: Range picker for due dates.
2. **Tabular Viewport with Inline Detail Expansion:**
   - Row indicators: Red left border highlight on overdue orders.
   - Status Badges: Distinct color pills with icon matching domain state.
   - Action Menu per Row: `View Details`, `Print Job Card`, `Reprint Receipt`, `Mark as Ready`, `Collect Payment`, `Cancel Order`.
3. **Batch Operations Bar:**
   - Multi-select checkbox column allowing operators to bulk transition 20+ orders simultaneously (e.g. `Mark Selected as Ready`, `Send Ready SMS / WhatsApp`).

---

### 5.4 Production Workflow Queue (`lib/views/production_screen.dart`)

Visual Kanban and batch processing interface for the industrial laundry floor.

```
┌────────────────────────────────────────────────────────────────────────┐
│ Production Workflow Floor              [ Floor View: Kanban | Batches ]│
├──────────────┬──────────────┬──────────────┬──────────────┬────────────┤
│ RECEIVED (9) │ WASHING (12) │ DRYING (6)   │ FINISHING(14)│ READY (7)  │
├──────────────┼──────────────┼──────────────┼──────────────┼────────────┤
│ [LP-10495]   │ [LP-10482]   │ [LP-10477]   │ [LP-10471]   │ [LP-10465] │
│ 5 items      │ Washer #02   │ Dryer #01    │ Press #03    │ Rack A-12  │
│ Normal Wash  │ Delicate Cyc │ Standard Heat│ Steam Press  │ Fully Paid │
│ Due: 2h      │ Due: 45m     │ Due: 30m     │ Due: 15m     │ Ready 10:00│
│              │              │              │              │            │
│ [LP-10494]   │ [LP-10481]   │ [LP-10476]   │ [LP-10470]   │ [LP-10464] │
│ 2 items      │ Washer #01   │ Dryer #03    │ Press #01    │ Rack B-04  │
│ Dry Clean    │ Heavy Stain  │ Low Temp     │ Abaya Press  │ Unpaid     │
└──────────────┴──────────────┴──────────────┴──────────────┴────────────┘
```

#### Detailed Architecture & State Specifications
1. **Dual Display Modes:**
   - **Kanban Board:** Drag-and-drop or one-click stage advancement across 5 vertical columns (`Received` -> `Washing` -> `Drying` -> `Finishing` -> `Ready`).
   - **Machine Batch View:** Organizes work orders grouped by industrial machine allocation (Washer 1, Washer 2, Dry Cleaner, Dryer 1, Steam Finisher).
2. **Ticket Card Anatomy:**
   - Bold Order Number + Garment Count.
   - Machine & Operator tag.
   - Turnaround timer countdown (color shifts from Green -> Amber -> Flashing Red when past due).
   - One-click advance button (`→ Next Stage`).

---

### 5.5 Advanced Industrial Cycles (`lib/views/advanced_cycle_screen.dart`)

Specialized industrial wash programs for hospitality linen, healthcare linens, and delicate garments.

#### Detailed Architecture & State Specifications
1. **Cycle Recipe Builder:**
   - Parameters: Water Temperature (°C), Water Level (Low/Med/High), Chemical Injections (Detergent, Alkaline Booster, Emulsifier, Chlorine/Oxygen Bleach, Neutralizer, Softener), Wash Time, Spin Speed (RPM), Drain Cycles.
2. **Live Machine Execution Telemetry:**
   - Real-time gauge rendering machine temperature curve, drum RPM, and cycle stage duration countdown.

---

### 5.6 Pickups, Deliveries & Van Manifests (`lib/views/delivery_screen.dart`)

Logistics and route dispatch for laundry driver fleets.

#### Detailed Architecture & State Specifications
1. **Driver Manifest Table:**
   - Driver assignment dropdown (Vans 1 through 5).
   - Stop sequence ordering with interactive re-ordering (drag handle).
   - Columns: Stop #, Customer Name, Address / Building / Flat, Contact Phone, Order Bags Count, Payment Collection Required (AED), Action Button (`Mark Delivered`, `Reschedule`).
2. **Route Summary Card:**
   - Total Pickups, Total Deliveries, Total Cash to Collect, Distance Estimation.

---

### 5.7 Customers & Loyalty Directory (`lib/views/customers_screen.dart`)

Complete CRM record management.

#### Detailed Architecture & State Specifications
1. **Customer Master Table:**
   - Fields: Customer ID, Full Name, Mobile Phone, Email, Delivery Address, Area / Zone, Total Orders Count, Lifetime Spend (AED), Outstanding Balance (AED), Loyalty Points, Status (`Active` / `Blocked`).
2. **Slide-Over Customer Dossier:**
   - Clicking a customer opens a right-side drawer showing order history, favorite garments, custom starch/folding preferences, credit limits, and invoice statements.

---

### 5.8 Customer Self-Service Portal (`lib/views/customer_portal_screen.dart`)

Clean, high-trust touch interface for customer lookups and order tracking.

#### Detailed Architecture & State Specifications
1. **Secure Phone Lookup:** Customer enters their registered UAE mobile number (`+971 5X XXX XXXX`) and receives an instant summary of active tickets.
2. **Visual Order Tracker:** Step-by-step progress indicator showing their garments flowing from Intake to Ready for Collection.

---

### 5.9 Vendors & Chemical Suppliers (`lib/views/vendors_screen.dart`)

Supplier directory for packaging, detergents, hangers, and dry-cleaning solvents.

#### Detailed Architecture & State Specifications
1. **Vendor Directory Table:**
   - Supplier Name, Contact Person, Phone, Email, Category (`Chemicals`, `Packaging`, `Machinery Parts`), Current Payable Balance (AED), Payment Terms (e.g. Net 30).
2. **Purchase Order History & Statement of Account:**
   - Integrated tab view showing historical invoices and supplier payments.

---

### 5.10 Service & Garment Catalog (`lib/views/catalog_screen.dart`)

Dynamic price list, garment classifications, and promotional add-ons.

#### Detailed Architecture & State Specifications
1. **Hierarchical Category Tree:**
   - Left Navigation: Service Categories (`Dry Cleaning`, `Wash & Iron`, `Ironing Only`, `Steam Press`, `Leather & Suede`, `Alterations`).
2. **Garment Matrix & Price Editor:**
   - Table displaying Garment Name (English & Arabic), SKU / Code, Default Price (AED), Express Markup (%), Default Turnaround Hours, Active Toggle.
   - Bulk Price Adjuster dialog (apply % increase/decrease across category).

---

### 5.11 Inventory, Stock & Batches (`lib/views/inventory_screen.dart`)

Raw materials, chemicals, plastic packaging bags, tags, and hangers tracking.

#### Detailed Architecture & State Specifications
1. **Stock Levels Table:**
   - Item Code, Description, Category, Current Quantity on Hand, Unit of Measure (`Liters`, `KG`, `Pieces`, `Rolls`), Reorder Threshold, Unit Cost (AED), Total Inventory Valuation.
2. **Visual Alert Badges:**
   - Low Stock warning badge on items below reorder threshold.
3. **Quick Stock Adjustment Modal:**
   - Record Goods Received, Spillage / Loss, or Manual Audit Count correction.

