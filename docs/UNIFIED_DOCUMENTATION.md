# Unified Documentation: docs



## --- FILE: ALGORITHMS_AND_FEATURE_REVIEW.md ---

﻿# LaundryPro UAE: Algorithms & Feature Review

## 1. Core Algorithms

### 1.1 Financial Precision Engine (`bcmath`)
All financial aggregations in the API strictly avoid native floating-point math to prevent IEEE-754 precision drift.

**Algorithm:**
1. Fetch lines from DB as `DECIMAL(18,2)` strings.
2. Initialize `grand_total = '0.00'`.
3. Loop lines:
   - `line_total = bcmul(qty_string, price_string, 2)`
   - `line_total = bcsub(line_total, discount_string, 2)`
   - `grand_total = bcadd(grand_total, line_total, 2)`
4. Apply VAT (5%):
   - `tax_amount = bcmul(grand_total, '0.05', 2)`
   - `final_grand_total = bcadd(grand_total, tax_amount, 2)`
5. Return JSON payload encapsulating values as strings.

### 1.2 Offline-First Sync Backoff Algorithm
When pushing local changes to the cloud from `sync_outbox`, network failures trigger an exponential backoff to preserve system resources.

**Algorithm:**
1. Daemon queries `SELECT * FROM sync_outbox WHERE status IN ('pending', 'failed') AND next_retry_at <= NOW() LIMIT 100`.
2. For each record, `POST` to cloud.
3. If `200 OK`, `UPDATE status = 'synced'`.
4. If Network Timeout or `5xx`:
   - `attempts = attempts + 1`
   - If `attempts > 10`: `status = 'dead_letter'`
   - Else: `delay = power(2, attempts) * 60` seconds.
   - `next_retry_at = NOW() + delay`

### 1.3 Inventory Concurrency Lock
To prevent negative inventory when two terminals sell the same product simultaneously.

**Algorithm:**
1. `BEGIN TRANSACTION;`
2. `SELECT qty_on_hand FROM products WHERE id = X FOR UPDATE;` (Locks row)
3. If `qty_on_hand - req_qty < 0`: Rollback & throw `InsufficientStockException`.
4. `UPDATE products SET qty_on_hand = qty_on_hand - req_qty;`
5. `INSERT INTO inventory_movements ...`
6. `COMMIT;` (Releases lock)

---

## 2. Feature Review & Screen Index

| UI Screen | Feature Set | State |
|---|---|---|
| **AppShell** | Navigation rail, localized RTL/LTR, sync status indicator, dynamic theming. | Production Ready |
| **Dashboard** | 60s auto-refresh, top KPIs, financial trend arrows, quick actions. | Production Ready |
| **POS Screen** | Barcode scanning integration, split payments panel, `bcmath` mirrored calculations. | Production Ready |
| **Catalog** | `AppDataTable` integration, 2000+ item pagination, image attachment mapping. | Production Ready |
| **Customers** | CRM tracking, outstanding balance calculations, WhatsApp quick-link integration. | Production Ready |
| **Peripherals** | Epson/Citizen thermal printer integration via ESC/POS protocol, cash drawer pulse testing. | Production Ready |
| **Shift Close** | Blind cash entry, variance calculation logic, forced Z-Report printing. | Production Ready |
| **Settings** | UI bindings to `system_settings` table, dynamic VAT adjustments, licensing UMAC verifications. | Production Ready |

### Final Readiness Assessment
The runtime features operate accurately. The frontend is fully decoupled from the backend state via offline repositories. All components meet strict deployment specifications.


## --- FILE: API_DOCS.md ---

# LaundryPro UAE - API Documentation

This document outlines the architecture and endpoints of the LaundryPro UAE PHP 8.2 micro-framework backend.

## Framework Architecture

The backend is a custom, zero-dependency PHP micro-framework designed for maximum performance and explicit control.

- **Routing**: Regex-based URI matching mapped to controller methods.
- **Dependency Injection**: Custom `Container` mapping interfaces to implementations via closures.
- **Middleware Pipeline**: Request/Response lifecycle intercepted by a chain (e.g., `CorsMiddleware`, `RateLimitMiddleware`, `AuthMiddleware`, `PermissionMiddleware`, `AuditMiddleware`).
- **Standardized Envelope**: All JSON responses adhere to a strict envelope format:
  ```json
  {
    "success": true,
    "code": "OPERATION_SUCCESS_CODE",
    "message_key": "localization.key",
    "data": { ... },
    "errors": [],
    "meta": {
      "request_id": "hex_string",
      "server_time": "ISO8601",
      "version": "1.2.0"
    }
  }
  ```

## Security & Authentication

- **JWT Bearer Auth**: Stateless authentication using short-lived Access Tokens and long-lived Refresh Tokens.
- **RBAC (Role-Based Access Control)**: Enforced via `PermissionMiddleware`. Users require specific permissions (e.g., `sales.create`, `reports.view`) encoded in their JWT scope.
- **Rate Limiting**: IP-based limiting enforced on sensitive routes (e.g., `/auth/login` is limited to 5 attempts per minute).
- **Prepared Statements**: Absolute prevention of SQL injection via PDO.
- **Data Integrity**: Monetary values processed via `bcmath` and stored as `DECIMAL(18,2)`.

## Sync Engine Mechanics

The offline-first architecture relies on the **Sync Outbox Pattern**:
1. When the client executes an offline mutation, it writes to a local outbox.
2. The `SyncService` polls the outbox and pushes changes to the `/sync/push` endpoint.
3. The server processes the mutation and returns a synchronized state.
4. Failed syncs implement **Exponential Backoff**, incrementing the `sync_attempts` counter up to a hard limit, preventing network storms.

## Endpoint Reference

### Health & Installation (`HealthController`, `InstallController`)
- `GET /api/v1/health` - Basic connectivity and database health check.
- `GET /api/v1/install/status` - Returns installation and configuration state.
- `POST /api/v1/install/migrate` - Executes SQL schema migrations (Requires `X-Install-Token`).
- `POST /api/v1/install/seed` - Seeds database with default roles, branches, and admin user.
- `POST /api/v1/install/complete` - Finalizes installation and locks the system.

### Authentication (`AuthController`)
- `POST /api/v1/auth/login` - Authenticates user and returns JWT pair. Rate limited.
- `POST /api/v1/auth/refresh` - Issues a new access token using a valid refresh token.
- `POST /api/v1/auth/logout` - Revokes current refresh token.
- `GET /api/v1/auth/me` - Retrieves authenticated user profile.

### Sales & Point of Sale (`SalesController`)
- `GET /api/v1/sales` - Lists sales orders with pagination and filtering.
- `POST /api/v1/sales/draft` - Creates a draft sales order.
- `PUT /api/v1/sales/{id}/confirm` - Confirms a draft order, finalizing prices.
- `POST /api/v1/sales/{id}/payment` - Records a payment against an order.
- `PUT /api/v1/sales/{id}/status` - Updates order processing status (e.g., Ready for Collection).
- `GET /api/v1/sales/summary` - Retrieves aggregated sales data for reports.

### Catalog & Pricing (`CatalogController`)
- `GET /api/v1/catalog/services` - Lists available services and modifiers.
- `POST /api/v1/catalog/services` - Creates a new service definition.
- `PUT /api/v1/catalog/services/{id}` - Updates a service definition.
- `GET /api/v1/catalog/products` - Lists retail products.
- `POST /api/v1/catalog/products` - Creates a new retail product.

### Inventory (`InventoryController`)
- `GET /api/v1/inventory/movements` - Lists stock movements.
- `POST /api/v1/inventory/receipt` - Records a stock receipt against a purchase order.
- `POST /api/v1/inventory/adjustment` - Processes manual stock adjustments.

### Human Resources (`HrController`, `PayrollController`)
- `GET /api/v1/hr/employees` - Lists employees.
- `POST /api/v1/hr/employees` - Registers a new employee.
- `POST /api/v1/hr/attendance` - Records clock-in/out events.
- `POST /api/v1/hr/leave` - Submits a leave request.
- `POST /api/v1/payroll/advance` - Issues a salary advance.
- `POST /api/v1/payroll/run` - Generates payroll run for a period, deducting advances automatically.

### Delivery & Logistics (`DeliveryController`, `ChallanController`)
- `GET /api/v1/delivery/tasks` - Lists active delivery tasks.
- `POST /api/v1/delivery/tasks/{id}/complete` - Marks a task as completed.
- `POST /api/v1/challans` - Generates a batch transfer document (Challan) for factory processing.

### Reporting & Analytics (`ReportsController`, `AnalyticsController`)
- `GET /api/v1/reports/inventory` - Current stock valuation.
- `GET /api/v1/reports/payroll` - Payroll summary.
- `GET /api/v1/reports/expenses` - Expense breakdown.
- `GET /api/v1/reports/production` - Factory output metrics.
- `GET /api/v1/analytics/summary` - High-level executive dashboard metrics.

### System Settings & Backup (`SettingsController`, `BackupController`)
- `GET /api/v1/settings` - Retrieves global configurations.
- `PUT /api/v1/settings` - Bulk updates settings.
- `GET /api/v1/backup/history` - Lists available backups.
- `POST /api/v1/backup/run` - Triggers an encrypted ZIP backup of the database and files.

### Synchronization (`SyncController`)
- `GET /api/v1/sync/status` - Returns unpushed outbox counts and sync health.
- `POST /api/v1/sync/push` - Receives offline mutations from the client and applies them.
- `GET /api/v1/sync/pull` - Returns changes originating from the server since the last sync.

## Error Handling

Standard HTTP status codes are used alongside domain-specific error keys:
- `401 Unauthorized` - Missing or expired JWT.
- `403 Forbidden` - Insufficient RBAC permissions.
- `404 Not Found` - Resource does not exist.
- `422 Unprocessable Entity` - Validation failure.
- `429 Too Many Requests` - Rate limit exceeded.
- `500 Internal Server Error` - Unhandled exception (safely obfuscated in production).

## Hardware Integration

### RFID HardwareAdapterInterface Fallback
The `HardwareAdapterInterface` provides an abstraction layer for RFID scanners. In cases where the primary hardware bridge (e.g., native SDK or COM port) becomes unavailable or disconnected:
1. **Fallback to Keyboard Wedge**: The interface automatically degrades to accept standard HID keyboard inputs if a scanner supports it.
2. **Offline Buffering**: Scans captured while the network is offline are buffered locally in the Flutter app's internal queue.
3. **Reconciliation**: Once connection restores, buffered scans are pushed through the standard sync outbox to ensure no tags are missed during brief disconnects.


## --- FILE: BLUEPRINT_WORKFLOWS_USE_CASES.md ---



## --- FILE: CHANGELOG.md ---

﻿# Changelog - LaundryPro UAE

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- Complete .ai/ agent ecosystem (181 files)
- Complete docs/ documentation universe
- Initial project scaffolding

## [0.1.0] - 2026-09-21

### Added
- Project initialization
- Database baseline schema (001_baseline.sql)
- Flutter project structure
- PHP API project structure

## --- FILE: CLOSEOUT_CHECKLIST.md ---

# LaundryPro UAE — Final Closeout Checklist

**Version:** 1.2.1+4  
**Date:** 2026-09-05  
**Quality gate:** `powershell scripts\dev.ps1 gate`

## Consolidation

| Item | Status |
|------|--------|
| `001_baseline.sql` greenfield migration | Done |
| Incremental migrations archived | Done |
| `001_all_seeds.sql` + `run_dev_seed.php` | Done |
| `scripts/dev.ps1` unified CLI | Done |
| API tests → 4 phase suites (182 cases) | Done |
| Legacy DB baseline shim in MigrationService | Done |

## Test evidence

| Suite | Pass | Skip |
|-------|------|------|
| API (`run_api_tests.php`) | 173 | 9 |
| Flutter (`flutter test`) | 116 | 0 |
| OpenAPI routes | 148 | — |

## Phase gap audit

| Track | Status | Notes |
|-------|--------|-------|
| Phase 0 | VERIFIED | Platform + quality gate |
| Phase 1 | VERIFIED | CRM, catalog, POS, sales, sync local |
| Phase 1C | VERIFIED | License, backup verify/restore |
| Phase 2 | VERIFIED | Production, delivery, challans, purchasing, HR, payroll, expenses, reports, notifications |
| Phase 2 P2-13 | DEFERRED | Print template designer UI — peripheral template DB exists, no visual designer |
| Phase 3 | VERIFIED | Branches, terminals, LAN, analytics, KSA, channels, accounting, storefront, portal |
| CR-2026-09-02-001 | PARALLEL | Cloud scaffold; tenant tests optional (skip on 404) |
| CR-2026-09-05-002 | VERIFIED | Phase 3 completion |
| CR-2026-09-05-003 | VERIFIED | POS peripheral framework merge |
| POS hardware | VERIFIED | Print, scan, drawer; printer must be selected in Peripherals |

## Documentation synced

| Document | Updated |
|----------|---------|
| CR-2026-09-05-003.md | Yes |
| EDGE_CASES.md (AC-031..035) | Yes |
| QUALITY_GATE.md | Yes |
| api-contract.md | Yes |
| docs/peripherals/README.md | Yes |
| Roadmap (key sections) | Yes |

## Git closeout

- [x] Commit 1: `feat(peripherals): merge POS peripheral framework`
- [x] Commit 2: `chore: consolidate artifacts and sync v1.2.1 docs`
- [x] Quality gate green
- [x] `git push origin main` (`9a3eeb2`)

## Known optional skips (not blockers)

- Cloud tenant registration tests (cloud-api not on localhost)
- `p3_branch_create` / `p3_terminal_create` optional 500 in some envs
- MSIX build requires VS C++ ATL + `scripts/peripherals/stage_missing_dlls.ps1`


## --- FILE: DATABASE_ER_DIAGRAM.md ---

﻿# LaundryPro UAE: Database Entity-Relationship (ER) Diagram

This document defines the core relational data model underpinning the LaundryPro UAE offline-first system.

## Core Schema

```mermaid
erDiagram
    BUSINESS ||--o{ BRANCHES : "owns"
    BRANCHES ||--o{ TERMINALS : "contains"
    
    ROLES ||--o{ USERS : "defines permissions for"
    USERS ||--o{ REFRESH_TOKENS : "issues"
    USERS ||--o{ AUDIT_LOGS : "performs"
    
    CUSTOMERS ||--o{ SALES_ORDERS : "places"
    
    CATEGORIES ||--o{ SERVICES : "groups"
    SERVICES ||--o{ SERVICE_PRODUCT_MAP : "consumes"
    PRODUCTS ||--o{ SERVICE_PRODUCT_MAP : "is consumed by"
    
    SALES_ORDERS ||--o{ SALES_ORDER_LINES : "contains"
    SALES_ORDERS ||--o{ PAYMENT_TRANSACTIONS : "paid via"
    
    PRODUCTS ||--o{ INVENTORY_MOVEMENTS : "tracked by"
    VENDORS ||--o{ PURCHASE_ORDERS : "receives"
    PURCHASE_ORDERS ||--o{ INVENTORY_MOVEMENTS : "restocks via"
    
    TERMINALS ||--o{ SYNC_OUTBOX : "queues data to"
    SYNC_OUTBOX ||--o{ SYNC_STATE : "monitored by"
    
    BUSINESS {
        int id PK
        string name
        string trn
        boolean is_active
    }
    
    USERS {
        int id PK
        string uuid
        int role_id FK
        string username
        string password_hash
    }
    
    ROLES {
        int id PK
        string name
        json permissions
    }
    
    CUSTOMERS {
        int id PK
        string uuid
        string name
        string phone
        decimal outstanding_balance
    }
    
    SALES_ORDERS {
        int id PK
        string uuid
        int customer_id FK
        string status
        string payment_status
        decimal grand_total
        decimal balance_due
    }
    
    SALES_ORDER_LINES {
        int id PK
        int sales_order_id FK
        int service_id FK
        int quantity
        decimal unit_price
        decimal subtotal
    }
    
    PRODUCTS {
        int id PK
        string sku
        string name
        int qty_on_hand
        int reorder_point
    }
    
    INVENTORY_MOVEMENTS {
        int id PK
        int product_id FK
        string type
        int quantity_change
    }
    
    SYNC_OUTBOX {
        int id PK
        string entity_type
        string entity_uuid
        string action
        json payload
        string status
        int attempts
        timestamp next_retry_at
    }
```

## Design Constraints
- All primary keys (`id`) are unsigned integers auto-incremented for local database speed.
- All replicated tables possess a `uuid` `CHAR(36)` used as the global primary key when synchronizing to the central cloud.
- Monetary values (`grand_total`, `subtotal`, etc.) are STRICTLY typed as `DECIMAL(18,2)`.
- The `sync_outbox` acts as an event-store for the offline-first replication engine.


## --- FILE: DESIGN_BRIEF.md ---

# Professional Design Brief & Prompt: Laundry Pro UAE — Icon Set, Logo & Visual Identity

**Document Version:** 1.0  
**Date:** September 2026  
**Prepared For:** Magnificent Solution — Brand, Product, Engineering  
**Project:** Laundry Pro UAE — Commercial Laundry Management Platform  
**Deliverable:** Complete asset icon set, logo suite, and visual identity system  
**Style Direction:** Elegant, Futuristic, Professional, Clear, Premium, Fully Furnished  
**Output Formats:** SVG, PNG (multiple resolutions), PDF, AI/EPS, Figma/Sketch libraries  
**Purpose:** To provide a single, comprehensive, production-ready design brief and prompt that can be handed to a world-class brand identity designer or used to drive AI-assisted asset generation for the entire Laundry Pro UAE ecosystem.

---

## 1. Brand Overview & Context

**Brand Name:** Laundry Pro UAE  
**Tagline (optional):** *Professional Laundry Management Platform for the UAE*  
**Industry:** Commercial Laundry, Dry Cleaning, Garment Care, POS/ERP for Laundry Businesses  
**Target Audience:** Laundry owners, franchise operators, store managers, cashiers, delivery drivers, advanced garment-care specialists, QA/compliance officers, super-admins.  
**Platform:** Flutter desktop (Windows/Linux), Android, iOS; web portal; cloud API; local XAMPP API.  
**Brand Attributes:**
- **Elegant:** Refined, premium, sophisticated, not cartoonish.
- **Futuristic:** Forward-looking, tech-savvy, subtle sci-fi touches (glassmorphism, soft glow, geometric precision) without being gimmicky.
- **Professional:** Trustworthy, enterprise-grade, reliable, clean.
- **Clear:** Highly legible at small sizes, unambiguous iconography, strong silhouette recognition.
- **Furnished:** Complete, comprehensive, every possible icon and variant is provided; no gaps.
- **Localized:** Works in English (LTR) and Arabic (RTL); culturally neutral but with subtle UAE-inspired geometric motifs (optional).

---

## 2. Visual Identity Principles

1. **Minimalist Geometry:** Icons built from simple geometric primitives (circles, squares, lines, arcs) with a consistent 2px stroke on a 24×24 grid.
2. **Consistent Stroke & Corner Radius:** All icons share the same stroke weight, cap style (rounded), join style (rounded), and corner radius (2px).
3. **Duotone & Monochrome Variants:** Every icon has a monochrome version and a duotone version using the primary and accent colors.
4. **Subtle Depth:** Icons may use very subtle gradients (linear, 2-stop) to add a futuristic feel, but must remain flat when reduced to monochrome.
5. **Negative Space:** Clever use of negative space to imply motion, cleanliness, or fabric flow.
6. **Optical Alignment:** Icons are optically balanced, not just mathematically centered.
7. **Pixel Perfect:** Icons align to the pixel grid at 24×24, 32×32, 48×48, and 64×64.
8. **Semantic Clarity:** Each icon has a single, unambiguous meaning; no abstract shapes that require a label to understand.
9. **Futuristic Accents:** Optional subtle glow, thin outer ring, or micro-dot patterns on active/selected states.
10. **Brand Consistency:** All icons feel like they belong to the same family; no outliers.

---

## 3. Color Palette

| Role | Hex | Usage |
|---|---|---|
| **Primary** | `#0A2540` (Deep Navy) | Backgrounds, headers, primary text |
| **Primary Gradient** | `#0A2540` → `#1B4B6B` | Hero sections, active states |
| **Accent 1** | `#00D4FF` (Electric Cyan) | Highlights, active icons, futuristic glow |
| **Accent 2** | `#00E5A0` (Aqua Green) | Success, cleanliness, water |
| **Accent 3** | `#FFB800` (Warm Gold) | Premium accents, loyalty, warnings |
| **Neutral 1** | `#FFFFFF` (Pure White) | Backgrounds, icon fills |
| **Neutral 2** | `#F5F7FA` (Light Mist) | Cards, surfaces |
| **Neutral 3** | `#B0BEC5` (Cool Gray) | Secondary text, inactive icons |
| **Neutral 4** | `#263238` (Dark Slate) | Body text, dark mode backgrounds |
| **Error** | `#FF4D4F` | Errors, destructive actions |
| **Warning** | `#FAAD14` | Warnings, pending states |
| **Info** | `#1890FF` | Informational states |
| **Success** | `#52C41A` | Success, synced, completed |

**Gradients:**
- **Primary Gradient:** Linear 135°, `#0A2540` → `#1B4B6B`
- **Accent Gradient:** Linear 135°, `#00D4FF` → `#00E5A0`
- **Glass Gradient:** Linear 135°, `rgba(255,255,255,0.15)` → `rgba(255,255,255,0.05)`

**Futuristic Glow:** Use `#00D4FF` at 20% opacity as a soft outer glow on active icons.

---

## 4. Typography

| Usage | Font | Weight | Notes |
|---|---|---|---|
| **Logo Wordmark** | Custom geometric sans (e.g., Poppins, Montserrat, or custom) | Bold (700) | Tight letter-spacing, clean |
| **Headings** | Poppins / Inter | Semi-Bold (600) | Clear, modern |
| **Body** | Inter / Roboto | Regular (400) | Highly legible |
| **Arabic** | Cairo / Tajawal | Regular/Bold | RTL support |
| **Monospace** | JetBrains Mono | Regular | For codes, IDs |

**Logo Typography:** The wordmark should use a custom or highly refined geometric sans-serif. Letters should have consistent stroke width, subtle rounded terminals, and a futuristic feel. Consider a subtle ligature or custom cut on the "L" and "P".

---

## 5. Logo Suite

### 5.1 Primary Logo (Horizontal)
- **Composition:** Icon mark on the left, wordmark "LAUNDRY PRO" on the right, with "UAE" as a smaller tagline or integrated.
- **Icon Mark:** Abstract, geometric representation of a washing machine drum combined with a water droplet and a subtle sparkle/star to imply cleanliness and premium service. Futuristic: the drum could be a hexagon or circular ring with segmented arcs.
- **Wordmark:** "LAUNDRY PRO" in bold geometric sans, with "UAE" in a lighter weight or smaller size, possibly in accent color.
- **Clear Space:** Minimum clear space equal to the height of the "L" on all sides.
- **Minimum Size:** 120px wide for digital, 30mm for print.

### 5.2 Secondary Logo (Vertical/Stacked)
- Icon mark centered above the wordmark.
- Used for app icons, social media profiles, merchandise.

### 5.3 Icon-Only Mark (App Icon / Favicon)
- The icon mark alone, simplified for small sizes.
- Must be recognizable at 16×16.
- Use a solid background with the mark in white or accent gradient.

### 5.4 Monogram (LP)
- A stylized "LP" ligature that can be used as a watermark, pattern, or compact identifier.
- Futuristic: geometric, sharp, with a subtle cut or overlap.

### 5.5 Color Variants
- **Full Color:** Primary gradient + accent.
- **Monochrome Dark:** All dark navy.
- **Monochrome Light:** All white.
- **Inverted:** White mark on dark background.
- **Gold Premium:** For loyalty/premium tier.

### 5.6 Usage Guidelines
- Do not stretch, rotate, or alter proportions.
- Do not change colors outside the palette.
- Do not add effects (drop shadows, bevels) except the defined subtle glow.
- Always use the provided SVG for digital, EPS/AI for print.

---

## 6. Icon Set Specification

### 6.1 Grid & Construction
- **Grid:** 24×24 px, with 1px padding (live area 22×22).
- **Stroke:** 2px, rounded caps, rounded joins.
- **Corner Radius:** 2px for rectangles, full round for circles.
- **Alignment:** Snap to pixel grid; use half-pixel for curves if needed.
- **Optical Corrections:** Slightly overshoot curves for optical balance.

### 6.2 Style Variants
- **Outline (default):** 2px stroke, no fill.
- **Filled:** Solid fill, no stroke, for active states.
- **Duotone:** Two colors (primary + accent) with 20% opacity for secondary shapes.
- **Glass/Futuristic:** Subtle gradient fill + thin white stroke + soft glow for hero/active states.

### 6.3 Icon Categories & Complete List

#### A. Navigation & Shell (20 icons)
1. Dashboard  
2. POS / Sales  
3. Catalog  
4. Inventory  
5. Customers  
6. HR  
7. Delivery  
8. Challans  
9. Reports  
10. Analytics  
11. Settings  
12. Admin  
13. Advanced (garment care)  
14. Sync  
15. Backup  
16. Storefront  
17. Channels  
18. Branches  
19. Terminals  
20. Logout  

#### B. Core Actions (30 icons)
21. Add / Create  
22. Edit  
23. Delete / Trash  
24. Search  
25. Filter  
26. Sort  
27. Export  
28. Import  
29. Print  
30. Share  
31. Sync / Refresh  
32. Save  
33. Cancel  
34. Back  
35. Next  
36. Home  
37. Menu  
38. Login  
39. Lock  
40. Unlock  
41. User / Profile  
42. Notifications  
43. Help  
44. Info  
45. Warning  
46. Error  
47. Success  
48. Copy  
49. Paste  
50. Undo  

#### C. POS & Payment (20 icons)
51. Cash  
52. Credit Card  
53. Split Payment  
54. Refund / Correction Memo  
55. Invoice  
56. Receipt  
57. Barcode Scanner  
58. RFID  
59. Cash Drawer  
60. Thermal Printer  
61. Scale  
62. Express Service  
63. Fragrance  
64. Starch  
65. Stain Treatment  
66. Loyalty Points  
67. Discount  
68. Tax / VAT  
69. Change Due  
70. Hold Cart  

#### D. Inventory & Purchasing (20 icons)
71. Stock / Box  
72. Receipt of Goods  
73. Transfer  
74. Adjustment  
75. Low Stock Alert  
76. Purchase Order  
77. Vendor / Supplier  
78. Warehouse  
79. Barcode  
80. QR Code  
81. Chemical / Detergent  
82. Reagent  
83. PPE  
84. Consumable  
85. Expiry Date  
86. Lot Number  
87. Reorder Point  
88. Shrinkage  
89. Damage  
90. Cycle Count  

#### E. HR & Payroll (20 icons)
91. Employee  
92. Attendance / Clock  
93. Leave  
94. Payroll  
95. Salary Advance  
96. Shift  
97. Clock In  
98. Clock Out  
99. Overtime  
100. WPS / Bank  
101. Payslip  
102. Contract  
103. Certification  
104. Training  
105. ID Card  
106. Department  
107. Designation  
108. Joining Date  
109. Resignation  
110. Appraisal  

#### F. Delivery & Challans (15 icons)
111. Delivery Truck  
112. Driver  
113. Route  
114. Package  
115. Handover  
116. Signature  
117. Proof of Delivery  
118. Cold Chain  
119. Temperature Log  
120. Challan  
121. Dispatch  
122. Receive  
123. Batch Transfer  
124. Factory  
125. Storefront  

#### G. Advanced Garment Care (30 icons)
126. Advanced Cycle  
127. Washing Machine  
128. Dry Cleaning  
129. Ironing  
130. Folding  
131. Packaging  
132. Sterilization  
133. Autoclave  
134. Cleanroom  
135. Garment  
136. Gowning  
137. Degowning  
138. ISO Class  
139. pH Level  
140. Temperature  
141. Pressure  
142. Detergent Ratio  
143. Spin Speed  
144. Chemical Dosage  
145. Equipment  
146. Calibration  
147. Maintenance  
148. Out of Service  
149. Certificate  
150. Compliance  
151. GMP  
152. Validation  
153. Electronic Signature  
154. Audit Trail  
155. Batch / Lot  

#### H. Reports & Analytics (15 icons)
156. Chart / Graph  
157. Bar Chart  
158. Pie Chart  
159. Line Chart  
160. Trend  
161. KPI  
162. Aging Report  
163. P&L  
164. Sales Summary  
165. Payment Breakdown  
166. Employee Report  
167. Branch Performance  
168. Top Services  
169. Top Customers  
170. Export to Excel  

#### I. System & Infrastructure (25 icons)
171. Cloud  
172. Server  
173. Database  
174. API  
175. License  
176. Security / Shield  
177. Key  
178. Backup  
179. Restore  
180. Migration  
181. Log  
182. Health Check  
183. Connectivity  
184. Offline  
185. Online  
186. LAN  
187. Terminal  
188. Branch  
189. Tenant  
190. Super Admin  
191. Data Explorer  
192. Services Control  
193. Registry  
194. UMAC  
195. Clock Tamper  

#### J. Status & Feedback (15 icons)
196. Pending  
197. In Progress  
198. Completed  
199. Cancelled  
200. Failed  
201. Synced  
202. Offline  
203. Online  
204. Warning  
205. Error  
206. Success  
207. Info  
208. Loading / Spinner  
209. Empty State  
210. No Data  

#### K. Miscellaneous (20 icons)
211. Calendar  
212. Time  
213. Location / Map  
214. Phone  
215. Email  
216. WhatsApp  
217. SMS  
218. Notification Bell  
219. Chat  
220. Attachment  
221. Image  
222. File  
223. Folder  
224. Link  
225. QR Code  
226. Barcode  
227. Printer  
228. Scanner  
229. Camera  
230. Microphone  

**Total Icons:** 230+ unique icons, each with 4 style variants (Outline, Filled, Duotone, Glass) = 920+ assets.

### 6.4 Icon Naming Convention
- `lp_icon_{category}_{name}_{variant}.svg`
- Example: `lp_icon_nav_dashboard_outline.svg`, `lp_icon_action_add_filled.svg`

### 6.5 Icon Delivery Formats
- **SVG:** Optimized, minified, with `viewBox="0 0 24 24"`.
- **PNG:** 24, 32, 48, 64, 128, 256, 512 px, transparent background.
- **PDF:** Vector, for print.
- **Figma/Sketch Library:** Organized by category, with components and variants.
- **Icon Font:** Optional, for web usage.

---

## 7. Futuristic & Elegant Accents

- **Subtle Glow:** Active icons may have a soft outer glow using `#00D4FF` at 20% opacity, 4px blur.
- **Glassmorphism:** For hero icons, use a translucent white fill (`rgba(255,255,255,0.1)`) with a 1px white stroke and backdrop blur.
- **Micro-Dots:** Optional pattern of tiny dots (1px) in the background of hero icons.
- **Gradient Strokes:** For premium icons (e.g., loyalty, advanced), use a gradient stroke from `#00D4FF` to `#00E5A0`.
- **Motion:** Icons should be designed with potential for subtle animation (e.g., rotating drum, pulsing glow) in mind, but static versions must stand alone.

---

## 8. Logo & Icon Usage Guidelines

- **Clear Space:** Minimum clear space around logo = height of the "L" in the wordmark.
- **Minimum Sizes:** Digital: 120px wide (horizontal), 32px (icon-only). Print: 30mm wide (horizontal), 10mm (icon-only).
- **Backgrounds:** Use the full-color logo on light backgrounds; use the inverted (white) logo on dark backgrounds. Ensure sufficient contrast.
- **Do Not:** Distort, rotate, recolor, add effects, outline, or place on busy backgrounds without a solid container.
- **Accessibility:** Ensure icons have a contrast ratio of at least 4.5:1 against their background. Provide text labels where possible.

---

## 9. Deliverables Checklist

- [ ] Primary logo (horizontal, full color)
- [ ] Secondary logo (vertical/stacked)
- [ ] Icon-only mark (app icon, favicon)
- [ ] Monogram (LP)
- [ ] Color variants (monochrome dark, monochrome light, inverted, gold premium)
- [ ] Logo usage guidelines (PDF)
- [ ] 230+ unique icons in 4 variants each (Outline, Filled, Duotone, Glass)
- [ ] SVG, PNG, PDF, AI/EPS for all assets
- [ ] Figma/Sketch library with organized components
- [ ] Icon font (optional)
- [ ] Brand guidelines document (PDF) covering logo, colors, typography, iconography, spacing, motion, and usage examples
- [ ] Mockups: App UI, web portal, print collateral, merchandise, vehicle branding

---

## 10. Prompt for AI Image Generation (Midjourney / DALL-E / Stable Diffusion)

If using an AI image generator to create initial concepts, use the following prompt (adapt as needed):

```
Professional brand identity design for "Laundry Pro UAE", a premium commercial laundry management platform. Elegant, futuristic, clear, and professional. Create a comprehensive icon set and logo. Style: minimalist geometric, 2px stroke, rounded caps, 24x24 grid, consistent visual weight. Color palette: deep navy #0A2540, electric cyan #00D4FF, aqua green #00E5A0, warm gold #FFB800, white, light mist #F5F7FA, cool gray #B0BEC5, dark slate #263238. Logo: abstract washing machine drum combined with water droplet and sparkle, geometric, futuristic. Wordmark "LAUNDRY PRO" in bold geometric sans, "UAE" smaller. Icons: navigation, POS, inventory, customers, HR, delivery, challans, reports, settings, admin, advanced garment care (cycles, sterilization, cleanroom, calibration, certification, e-signature), sync, backup, licensing, status, actions. Include duotone and monochrome variants. Futuristic accents: subtle glow, glassmorphism, gradients. Deliver as SVG, PNG, PDF. Ultra-detailed, high resolution, vector style, clear silhouettes, premium enterprise look. --ar 16:9 --v 6
```

---

## 11. Conclusion

This brief provides a complete, production-ready specification for the Laundry Pro UAE logo and icon set. The resulting visual identity will be elegant, futuristic, professional, and clear, fully furnished with every icon needed across the entire platform. It will scale from app icons to large-format print, support both English and Arabic, and reinforce the brand's premium, enterprise-grade positioning.


## --- FILE: DEVELOPMENT_ROADMAP.md ---

﻿# Unified Development Roadmap â€” LaundryPro UAE
> **Version:** 1.0.0 | **Last Updated:** 2026-09-21
> **Owner:** LP-AGENT-EXEC-PM (Program Manager)
> **Status:** Active â€” Sprint 1 Ready

---

## Phase 1: Foundation (Sprints 1-3) â€” Weeks 1-6

### Sprint 1: Core Infrastructure (Weeks 1-2)
| # | Task | Owner | Status | Priority |
|---|------|-------|--------|----------|
| 1.1 | XAMPP server setup and configuration | ENG-DEVOPS | To Do | P0 |
| 1.2 | Run baseline migration (001_baseline.sql) | ENG-DB | To Do | P0 |
| 1.3 | Flutter project scaffold (MVVM + Riverpod) | ENG-FLUTTER | To Do | P0 |
| 1.4 | PHP API scaffold (Slim/Lumen + Repository) | ENG-PHP | To Do | P0 |
| 1.5 | JWT auth middleware implementation | ENG-PHP | To Do | P0 |
| 1.6 | RBAC PermissionChecker middleware | ENG-PHP | To Do | P0 |
| 1.7 | API error handling and envelope structure | ENG-API | To Do | P0 |
| 1.8 | .env configuration for dev/staging/prod | ENG-DEVOPS | To Do | P0 |
| 1.9 | Localization setup (en.json + ar.json skeleton) | PROD-UID | To Do | P0 |
| 1.10 | Design system tokens (colors, typography, spacing) | PROD-UID | To Do | P0 |

### Sprint 2: Auth & User Management (Weeks 3-4)
| # | Task | Owner | Status | Priority |
|---|------|-------|--------|----------|
| 2.1 | Login screen (Flutter) | ENG-FLUTTER | To Do | P0 |
| 2.2 | Login API endpoint (POST /auth/login) | ENG-PHP | To Do | P0 |
| 2.3 | Token refresh endpoint (POST /auth/refresh) | ENG-PHP | To Do | P0 |
| 2.4 | Logout endpoint (POST /auth/logout) | ENG-PHP | To Do | P0 |
| 2.5 | User management CRUD (API) | ENG-PHP | To Do | P0 |
| 2.6 | User management screens (Flutter) | ENG-FLUTTER | To Do | P0 |
| 2.7 | RBAC scope enforcement on all auth routes | SEC-APPSEC | To Do | P0 |
| 2.8 | JWT token storage (secure local storage) | ENG-FLUTTER | To Do | P1 |
| 2.9 | Unit tests for auth services | QA-AUTO | To Do | P0 |
| 2.10 | UMAC license validation (basic) | SEC-UMAC | To Do | P1 |

### Sprint 3: Dashboard & Navigation Shell (Weeks 5-6)
| # | Task | Owner | Status | Priority |
|---|------|-------|--------|----------|
| 3.1 | App shell with sidebar navigation | ENG-FLUTTER | To Do | P0 |
| 3.2 | go_router route configuration (all 42+ routes) | ENG-FLUTTER | To Do | P0 |
| 3.3 | Dashboard screen with KPI placeholders | ENG-FLUTTER | To Do | P0 |
| 3.4 | Dashboard API endpoints (summary data) | ENG-PHP | To Do | P1 |
| 3.5 | LTR/RTL toggle and locale switching | ENG-FLUTTER | To Do | P0 |
| 3.6 | Theme implementation (design system tokens) | ENG-FLUTTER | To Do | P0 |
| 3.7 | Sidebar role-based menu filtering | ENG-FLUTTER | To Do | P0 |
| 3.8 | SQLite local database setup (drift) | ENG-FLUTTER | To Do | P1 |
| 3.9 | API client service (dio + interceptors) | ENG-FLUTTER | To Do | P0 |
| 3.10 | Integration tests for auth flow | QA-AUTO | To Do | P0 |

---

## Phase 2: Core Business Modules (Sprints 4-8) â€” Weeks 7-16

### Sprint 4: Customer Management (Weeks 7-8)
| # | Task | Owner | Status | Priority |
|---|------|-------|--------|----------|
| 4.1 | Customer CRUD API | ENG-PHP | To Do | P0 |
| 4.2 | Customer list screen (search, pagination) | ENG-FLUTTER | To Do | P0 |
| 4.3 | Customer detail/edit screen | ENG-FLUTTER | To Do | P0 |
| 4.4 | Corporate account support | ENG-PHP | To Do | P1 |
| 4.5 | Customer form validation (UAE phone format) | ENG-FLUTTER | To Do | P0 |
| 4.6 | Customer API integration tests | QA-AUTO | To Do | P0 |

### Sprint 5: Service Catalog & Pricing (Weeks 9-10)
| # | Task | Owner | Status | Priority |
|---|------|-------|--------|----------|
| 5.1 | Service CRUD API | ENG-PHP | To Do | P0 |
| 5.2 | Price list management API | ENG-PHP | To Do | P0 |
| 5.3 | Service catalog screen | ENG-FLUTTER | To Do | P0 |
| 5.4 | Price list configuration screen | ENG-FLUTTER | To Do | P0 |
| 5.5 | Per-item, per-kg, per-piece pricing logic | ENG-PHP | To Do | P0 |
| 5.6 | DECIMAL(18,2) validation for all prices | FIN-BILLING | To Do | P0 |

### Sprint 6: Order Management (Weeks 11-12)
| # | Task | Owner | Status | Priority |
|---|------|-------|--------|----------|
| 6.1 | Order CRUD API | ENG-PHP | To Do | P0 |
| 6.2 | Order item management API | ENG-PHP | To Do | P0 |
| 6.3 | Order list screen | ENG-FLUTTER | To Do | P0 |
| 6.4 | Order detail screen | ENG-FLUTTER | To Do | P0 |
| 6.5 | New order screen (walk-in flow) | ENG-FLUTTER | To Do | P0 |
| 6.6 | Order status tracking API | ENG-PHP | To Do | P0 |
| 6.7 | Sequential order numbering (ORD-YYYY-NNNNNN) | ENG-PHP | To Do | P0 |
| 6.8 | Line-item discount calculation | ENG-PHP | To Do | P1 |
| 6.9 | Order management tests | QA-AUTO | To Do | P0 |

### Sprint 7: POS & Payments (Weeks 13-14)
| # | Task | Owner | Status | Priority |
|---|------|-------|--------|----------|
| 7.1 | POS screen (quick order creation) | ENG-FLUTTER | To Do | P0 |
| 7.2 | Payment processing API | ENG-PHP | To Do | P0 |
| 7.3 | Cash, card, split payment support | ENG-PHP | To Do | P0 |
| 7.4 | VAT calculation (5% on subtotal after discounts) | FIN-VAT | To Do | P0 |
| 7.5 | Invoice generation API | FIN-BILLING | To Do | P0 |
| 7.6 | Sequential invoice numbering (INV-YYYY-NNNNNN) | FIN-BILLING | To Do | P0 |
| 7.7 | Payment confirmation screen | ENG-FLUTTER | To Do | P0 |
| 7.8 | POS flow tests (< 30s end-to-end) | QA-MANUAL | To Do | P0 |
| 7.9 | Financial precision tests (DECIMAL) | QA-EDGE | To Do | P0 |

### Sprint 8: Invoicing & Receipts (Weeks 15-16)
| # | Task | Owner | Status | Priority |
|---|------|-------|--------|----------|
| 8.1 | Invoice detail screen | ENG-FLUTTER | To Do | P0 |
| 8.2 | Invoice list screen | ENG-FLUTTER | To Do | P0 |
| 8.3 | Immutable posted invoice enforcement | FIN-BILLING | To Do | P0 |
| 8.4 | Correction memo workflow | FIN-BILLING | To Do | P1 |
| 8.5 | Receipt print template (57mm + 80mm) | ENG-HW | To Do | P0 |
| 8.6 | Print preview screen | ENG-FLUTTER | To Do | P1 |
| 8.7 | TRN display on all invoices | FIN-VAT | To Do | P0 |

---

## Phase 3: Operations Modules (Sprints 9-12) â€” Weeks 17-24

### Sprint 9: Inventory Management (Weeks 17-18)
| # | Task | Owner | Priority |
|---|------|-------|----------|
| 9.1 | Inventory CRUD API | ENG-PHP | P0 |
| 9.2 | Stock-in/stock-out transaction API | ENG-PHP | P0 |
| 9.3 | Inventory list screen | ENG-FLUTTER | P0 |
| 9.4 | Stock transaction screens | ENG-FLUTTER | P0 |
| 9.5 | Low stock threshold alerts | ENG-PHP | P1 |

### Sprint 10: Production Management (Weeks 19-20)
| # | Task | Owner | Priority |
|---|------|-------|----------|
| 10.1 | Production stage tracking API | ENG-PHP | P0 |
| 10.2 | Production queue screen | ENG-FLUTTER | P0 |
| 10.3 | Quality check pass/fail workflow | ENG-PHP | P0 |
| 10.4 | Rewash/reclean workflow | ENG-PHP | P1 |
| 10.5 | Operator assignment | ENG-PHP | P0 |

### Sprint 11: Delivery Management (Weeks 21-22)
| # | Task | Owner | Priority |
|---|------|-------|----------|
| 11.1 | Delivery CRUD API | ENG-PHP | P0 |
| 11.2 | Delivery list and detail screens | ENG-FLUTTER | P0 |
| 11.3 | Driver assignment workflow | ENG-PHP | P0 |
| 11.4 | Delivery confirmation | ENG-FLUTTER | P0 |
| 11.5 | Route view screen | ENG-FLUTTER | P1 |

### Sprint 12: HR & Payroll (Weeks 23-24)
| # | Task | Owner | Priority |
|---|------|-------|----------|
| 12.1 | Employee CRUD API | ENG-PHP | P0 |
| 12.2 | Attendance tracking API | HR-ATTEND | P0 |
| 12.3 | Payroll calculation with UAE overtime rules | HR-PAYROLL | P0 |
| 12.4 | SIF file export for WPS | HR-PAYROLL | P0 |
| 12.5 | Leave management | HR-ATTEND | P1 |
| 12.6 | HR screens (employee, attendance, payroll) | ENG-FLUTTER | P0 |

---

## Phase 4: Hardware & Sync (Sprints 13-15) â€” Weeks 25-30

### Sprint 13: Printer Integration (Weeks 25-26)
| # | Task | Owner | Priority |
|---|------|-------|----------|
| 13.1 | ESC/POS adapter (thermal printers) | ENG-HW | P0 |
| 13.2 | Windows Spooler adapter (inkjet/laser) | ENG-HW | P0 |
| 13.3 | Auto-discovery algorithm | ENG-HW | P0 |
| 13.4 | Print template engine | ENG-HW | P0 |
| 13.5 | Cash drawer control (RJ11) | ENG-HW | P0 |
| 13.6 | Hardware config screen | ENG-FLUTTER | P0 |

### Sprint 14: Scanner & RFID (Weeks 27-28)
| # | Task | Owner | Priority |
|---|------|-------|----------|
| 14.1 | USB HID barcode scanner adapter | ENG-HW | P0 |
| 14.2 | Keyboard wedge input detection | ENG-FLUTTER | P0 |
| 14.3 | RFID UHF reader adapter (basic) | ENG-HW | P2 |
| 14.4 | Garment tag management | ENG-PHP | P1 |
| 14.5 | Hardware health monitoring | ENG-HW | P1 |

### Sprint 15: Sync Engine (Weeks 29-30)
| # | Task | Owner | Priority |
|---|------|-------|----------|
| 15.1 | Sync outbox table and local SQLite mirror | ENG-SYNC | P0 |
| 15.2 | Push protocol (local to cloud) | ENG-SYNC | P0 |
| 15.3 | Pull protocol (cloud to local) | ENG-SYNC | P0 |
| 15.4 | Conflict resolution (LWW) | ENG-SYNC | P0 |
| 15.5 | Dead-letter queue | ENG-SYNC | P1 |
| 15.6 | Sync status screen | ENG-FLUTTER | P0 |
| 15.7 | Idempotency middleware | ENG-PHP | P0 |

---

## Phase 5: Reports, Security & Polish (Sprints 16-18) â€” Weeks 31-36

### Sprint 16: Reports & Analytics (Weeks 31-32)
| # | Task | Owner | Priority |
|---|------|-------|----------|
| 16.1 | Dashboard KPI calculations | DATA-ANALYTICS | P0 |
| 16.2 | Sales report API and screen | DATA-REPORT | P0 |
| 16.3 | Financial reports (P&L, cash flow) | DATA-REPORT | P0 |
| 16.4 | Production reports | DATA-REPORT | P1 |
| 16.5 | HR reports (attendance, payroll) | DATA-REPORT | P1 |
| 16.6 | PDF/CSV export | DATA-REPORT | P0 |

### Sprint 17: Security Hardening & Licensing (Weeks 33-34)
| # | Task | Owner | Priority |
|---|------|-------|----------|
| 17.1 | UMAC full implementation | SEC-UMAC | P0 |
| 17.2 | Audit trail hash chaining | SEC-AUDIT | P0 |
| 17.3 | Input validation hardening (all forms) | SEC-APPSEC | P0 |
| 17.4 | Full RBAC endpoint audit | QA-SECTEST | P0 |
| 17.5 | Tenant isolation verification | QA-SECTEST | P0 |
| 17.6 | Backup automation and SHA-256 verification | DATA-BACKUP | P0 |
| 17.7 | License management screen | ENG-FLUTTER | P0 |

### Sprint 18: Polish, UAT & Release Prep (Weeks 35-36)
| # | Task | Owner | Priority |
|---|------|-------|----------|
| 18.1 | Full regression suite execution | QA-REGRESS | P0 |
| 18.2 | WCAG 2.1 AA accessibility audit | QA-A11Y | P0 |
| 18.3 | Performance profiling and optimization | ENG-PERF | P0 |
| 18.4 | Edge case testing (all 5 categories) | QA-EDGE | P0 |
| 18.5 | LTR/RTL full audit (all 42+ screens) | QA-A11Y | P0 |
| 18.6 | MSIX package build and signing | ENG-MSIX | P0 |
| 18.7 | Install/uninstall testing | QA-MANUAL | P0 |
| 18.8 | Training materials finalization | OPS-TRAIN | P1 |
| 18.9 | UAT with pilot customer | QA-MANUAL | P0 |
| 18.10 | Go-live authorization (CTO + CEO) | Program Manager | P0 |

---

## Release Milestones
| Milestone | Sprint | Target | Deliverable |
|-----------|--------|--------|-------------|
| Alpha | Sprint 8 | Week 16 | Core business modules functional |
| Beta | Sprint 15 | Week 30 | Hardware + sync operational |
| RC1 | Sprint 17 | Week 34 | Security hardened, licensed |
| GA 1.0 | Sprint 18 | Week 36 | Production release |

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial unified development roadmap |

## --- FILE: GLOSSARY.md ---

﻿# Glossary - LaundryPro UAE

| Term | Definition |
|------|-----------|
| AED | United Arab Emirates Dirham (currency) |
| BPMN | Business Process Model and Notation |
| CDO | Chief Data Officer |
| CISO | Chief Information Security Officer |
| CQO | Chief Quality Officer |
| CRUD | Create, Read, Update, Delete |
| DTO | Data Transfer Object |
| ERP | Enterprise Resource Planning |
| ESC/POS | Epson Standard Code for Point of Sale (thermal printer protocol) |
| FTA | Federal Tax Authority (UAE) |
| HMAC | Hash-based Message Authentication Code |
| JWT | JSON Web Token |
| LTR | Left-to-Right (text direction) |
| MSIX | Modern Windows installer package format |
| MVVM | Model-View-ViewModel |
| PDPL | Personal Data Protection Law (UAE) |
| POS | Point of Sale |
| RBAC | Role-Based Access Control |
| RFID | Radio-Frequency Identification |
| RTL | Right-to-Left (text direction) |
| SIF | Salary Information File (UAE WPS) |
| SLA | Service Level Agreement |
| TRN | Tax Registration Number (UAE) |
| UMAC | Unique Machine Authentication Code |
| UHF | Ultra High Frequency (RFID band) |
| UUID | Universally Unique Identifier |
| VAT | Value Added Tax |
| WPS | Wage Protection System (UAE) |
| XAMPP | Cross-platform Apache MariaDB PHP Perl stack |

## --- FILE: LAUNDRYPRO_MANUAL.md ---

# LaundryPro UAE: Comprehensive Application Manual & Walkthrough

Welcome to the **LaundryPro UAE Complete Handbook**. This manual is designed for owners, managers, cashiers, and technical staff to understand the complete functionality, architecture, workflows, and rules of the system. 

LaundryPro UAE is an offline-first POS (Point of Sale) and ERP (Enterprise Resource Planning) system explicitly tailored for modern laundry businesses.

## 1. System Overview and Assumptions

### What is LaundryPro UAE?
LaundryPro UAE is designed for environments where the internet might be unstable. It operates on a Windows Desktop machine locally. 
- The **backend** is powered by a high-performance PHP 8.2 micro-framework with a local MariaDB database.
- The **frontend** is a responsive Flutter application designed for touch screens and keyboard/mouse setups.
- A **cloud synchronization engine** works in the background to push data to the main server when the internet is restored.

### Core Assumptions & Non-Negotiable Rules
- **No Monetary Data Loss:** The system calculates money using high-precision decimal math. No floats are used anywhere.
- **Audit Trails:** Everything from deleting an invoice to changing the temperature on a washing cycle is logged.
- **Additive Migrations:** The database is designed so data is never truly "lost" when updates happen.
- **Offline First:** The cashier must be able to ring up customers, print invoices, and open the cash drawer even if the internet is completely disconnected.

### UI & Brand Identity
The platform features a premium, futuristic, glassmorphic UI characterized by Deep Navy, Electric Cyan, and Aqua Green. With an extensive set of minimalist geometric icons and highly legible typography (Poppins and Inter), the interface ensures efficient high-density data management without cognitive overload.

## 2. User Roles and Permissions

LaundryPro uses a robust Role-Based Access Control (RBAC) system. Every user logs in with an explicit token. 

### Roles
1. **Admin / Owner** 
   - *Permissions:* Can access all settings, create new users, modify inventory, run backups, and override prices.
   - *Use Case:* Setting up the business initially, closing the register at the end of the day, reviewing the Profit & Loss (P&L) statements.

2. **Manager**
   - *Permissions:* Can approve expenses, manage employees, view payroll, and refund customers. Cannot alter the core settings or run database migrations.
   - *Use Case:* Overseeing daily operations, managing customer complaints, handling cash drop-offs.

3. **Cashier**
   - *Permissions:* Can create sales drafts, confirm orders, accept payments, and add new customers. 
   - *Restrictions:* Cannot view business analytics, cannot delete invoices, cannot perform backups.
   - *Use Case:* The person standing at the front desk greeting customers and taking clothes.

4. **Operator / Driver**
   - *Permissions:* Specifically tailored for managing production cycles or delivery routes. 
   - *Use Case:* The delivery driver checking off "Challans" (delivery batches) on their tablet or the washing machine operator recording the pH levels of a wash.

## 3. Core Workflows with Examples

### A. The Front-Desk Workflow: Creating a Sale
*Scenario:* A customer walks in with 3 shirts for dry cleaning.

1. **Customer Selection:** The cashier clicks "New Order." They search for the customer by phone number. If the customer is new, they quickly add them (Name and Phone required).
2. **Item Entry:** The cashier taps "Dry Cleaning" -> "Shirt". They change the quantity to 3.
3. **Drafting:** The system creates a "Sales Draft." The items are not yet confirmed, allowing the cashier to modify quantities or apply a discount if the manager approves.
4. **Confirmation:** The cashier hits "Confirm Order." The system locks the prices. The order is now an official invoice.
5. **Payment:** The customer hands over cash. The cashier enters the amount received. The system calculates change, records a "Payment Transaction," and triggers the receipt printer.

### B. The Production Workflow: Advanced Garment Care
*Scenario:* The 3 shirts need to go through a specialized "Delicate Wash" cycle.

![Advanced Cycles Dashboard](docs/assets/advanced_cycles_dashboard.png)

1. **Starting the Cycle:** The Operator goes to the "Advanced Cycles" screen. They scan the barcode on the garment tag (Sale ID). They select "Delicate Wash Preset" and the specific washing machine (Equipment ID).
2. **Recording Metrics:** Halfway through the wash, the system prompts for a quality check. The operator checks the water and logs a "pH Level" of 7.2 in the "Process Logs" tab.
3. **Completion:** The wash is done. The operator marks the cycle as "Completed." The system automatically logs who did the wash, on what machine, and the exact timestamp.

### C. The Inventory Workflow: Receiving Detergent
*Scenario:* A vendor drops off 10 bottles of specialized detergent.

1. **Purchase Order (PO):** The Manager goes to "Purchasing" and creates a PO for the vendor.
2. **Receiving Items:** When the delivery arrives, the Manager clicks "Receive Items" against the PO. 
3. **Stock Update:** The system adds 10 bottles to the local inventory. This transaction is permanently recorded in the "Inventory Movements" ledger.
4. **Usage:** As cycles are run, detergent is automatically deducted from stock based on the preset configurations. 

## 4. Feature Deep Dives

### Multi-Branch and Cloud Sync
- **How it works:** The `sync_outbox` table securely queues every transaction. When the background sync worker runs (every few minutes), it securely pushes these to the central cloud.
- **Example:** If branch A creates a new customer, Branch B will see that customer once both branches sync with the cloud.

### Deliveries & Challans
- **Challans:** A Challan is a manifest of items being moved. If you are sending 50 garments to a central factory for washing, you create a Challan. The driver signs it, and the factory acknowledges receipt. This ensures zero lost garments.
- **Route Delivery:** Drivers use the "Delivery Tasks" feature to see a prioritized list of customer locations for drop-offs, optimized by the system.

### Payroll & HR
- **Attendance:** Staff clock in and out using a PIN or RFID card.
- **Salary Advances:** If an employee requests an advance, the manager can approve it. 
- **Payroll Run:** At the end of the month, the system automatically calculates salaries, deducts the approved advances, adds overtime, and generates a payroll report.

### Offline Resilience & Backups
- **Local Database:** You never see a "Connecting to server..." loading spinner when ringing up a customer. 
- **Automatic Backups:** The system creates encrypted `.zip` backups locally. If the computer crashes, a new computer can be restored instantly using this file.
- **Verification:** The "Backup Verify" feature ensures the backup file isn't corrupted before relying on it.

## 5. Security & Licensing

- **Tamper Protection:** If a user tries to modify the local SQLite/MariaDB database directly using a third-party tool, the sync engine will detect the signature mismatch and flag the branch for an audit.
- **Rate Limiting:** To prevent brute-force attacks on the manager's password, the system locks login attempts after 5 failures in 1 minute.
- **Licensing:** The software requires a valid license key (checked against the cloud). If the license expires, the system drops into a "Read-Only" mode where sales are blocked but historical data is still accessible.

## 6. End-to-End Walkthrough (The "Perfect Day")

1. **8:00 AM:** The manager opens the store, turns on the computer. The system boots in 2 seconds. The manager checks the **Health Screen** to ensure the receipt printer and cloud sync are green.
2. **8:15 AM - 12:00 PM:** Cashiers take 50 orders. The system works flawlessly offline even when the local ISP goes down at 10 AM.
3. **1:00 PM:** The driver arrives. The manager generates a **Challan** for 100 dirty garments. The driver takes them to the factory.
4. **3:00 PM:** The factory receives the garments, runs **Advanced Cycles**, and logs the metrics.
5. **5:00 PM:** The clean garments return. They are scanned in via the **Barcode Scanner**. The system automatically sends a WhatsApp/SMS notification to the 50 customers: "Your clothes are ready!"
6. **6:00 PM - 8:00 PM:** Customers pick up their clothes and pay the remaining balances.
7. **9:00 PM:** The manager runs the **End of Day Report**. It matches the cash drawer perfectly. The manager triggers a **Manual Backup** to a USB drive and closes the store.

---
*Generated by Antigravity AI - System Documentation Module*


## --- FILE: MANIFEST.md ---

﻿# Documentation Manifest - LaundryPro UAE
> **Version:** 1.0.0 | **Total Documents:** 200+

## Document Standards
- Every document has: Title, Version, Last Updated, Owner
- Markdown format (.md) for all documentation
- No placeholders, no TODOs, no stubs
- Cross-referenced via relative links
- Version controlled alongside source code

## --- FILE: MANUAL_ADMIN_SUPERADMIN_BOOK.md ---

﻿# LaundryPro UAE — Super-Admin & Cloud Portal Guide

**Document Version:** 2.0 (Production Release)  
**Target Audience:** Magnificent Solution System Administrators, Cloud Operators, Franchise IT Heads  

---

## Table of Contents
1. [Cloud Architecture & Security Overview](#1-cloud-architecture--security-overview)
2. [Accessing the Super-Admin Web Portal](#2-accessing-the-super-admin-web-portal)
3. [Dashboard Metrics & Operational Telemetry](#3-dashboard-metrics--operational-telemetry)
4. [Tenant & Client Laundry Node Management](#4-tenant--client-laundry-node-management)
5. [Cryptographic License Issuance & Management](#5-cryptographic-license-issuance--management)
6. [Offline License Request Processing (laundrypro_req.lic)](#6-offline-license-request-processing-laundrypro_reqlic)
7. [Remote Revocation & Kill-Switch](#7-remote-revocation--kill-switch)
8. [Real-time Sync Payload Stream Inspector](#8-real-time-sync-payload-stream-inspector)
9. [System Audit Trail & Security Logs](#9-system-audit-trail--security-logs)
10. [Database Backup & Maintenance](#10-database-backup--maintenance)
11. [Backup & Restore Procedures](#11-backup--restore-procedures)
12. [Rate Limiting & Security Monitoring](#12-rate-limiting--security-monitoring)
13. [Sync Engine Monitoring](#13-sync-engine-monitoring)
14. [RBAC Role Management](#14-rbac-role-management)
15. [Financial Precision Notes (bcmath)](#15-financial-precision-notes-bcmath)

---

## 1. Cloud Architecture & Security Overview

The Central Cloud API & Super-Admin Web Portal resides in cloud-api/ and is designed for standard cPanel shared hosting or Linux Apache servers:
- **Framework:** Pure PHP 8.2 with PDO MariaDB/MySQL.
- **Frontend UI:** AdminLTE v4 (Bootstrap 5, FontAwesome/Bootstrap Icons).
- **Public Root:** cloud-api/public/ (accessible via VirtualHost or sub-folder).
- **Database:** laundrypro_cloud.

---

## 2. Accessing the Super-Admin Web Portal

1. Navigate to:
   http://localhost/cloud-api/public/admin or http://cloud-api/admin  
   (Production URL: https://www.laundrypro-cloudapi.magnificentsolution.co.in/admin)
2. Enter your super-admin credentials:
   - **Username:** superadmin
   - **Password:** SuperAdmin@LaundryPro2026!
3. The session is protected by cryptographic cookie signatures and CSRF tokens.

---

## 3. Dashboard Metrics & Operational Telemetry

The executive dashboard displays:
- **Total Registered Tenants:** Count of laundry business nodes.
- **Active Licenses:** Count of valid, unexpired licenses.
- **Total Sync Events:** All-time ingested data records.
- **24-Hour Telemetry:** Pushes, orders, and pings received in the last 24 hours.
- **Recent Tenants Table:** Quick links to client profiles and activation statuses.

---

## 4. Tenant & Client Laundry Node Management

Navigate to **Tenants** in the sidebar:
1. **View Tenants:** View all registered laundry owners, trade license numbers, contact info, and node status.
2. **Cloud Tokens:** Each tenant has an auto-generated high-entropy Bearer token (	oken_...) used by their local XAMPP node for authentication.
3. **Status Control:** Toggle status between **Active**, **Suspended**, or **Archived**.

---

## 5. Cryptographic License Issuance & Management

Navigate to **Licenses** in the sidebar:
1. Click **Issue New License**.
2. Select the client **Tenant / Business**.
3. Choose Plan:
   - **Standard** (Full features, 1 year validity)
   - **Enterprise** (Multi-branch, unlimited terminals)
   - **Trial / Evaluation** (7 days, 9 invoices quota)
4. Enter target hardware **UMAC Code** (e.g., UMAC-8F2A-49C1-77B0).
5. Click **Generate License**.
6. The system generates a cryptographically signed license key:
   LP-1A2B3C4D-5E6F-7G8H
   which is returned to the client.

---

## 6. Offline License Request Processing (laundrypro_req.lic)

For client machines without internet access:
1. Client generates laundrypro_req.lic from the Flutter License Screen.
2. Client sends this file to Magnificent Solution support.
3. Super-Admin opens the License Generator, inputs the client details and hardware UMAC from the file.
4. Download the signed laundrypro_license.lic file and return it to the client.
5. Client imports the file into their desktop app to unlock permanent operation.

---

## 7. Remote Revocation & Kill-Switch

If a client terminates their contract or fails payment:
1. Navigate to **Licenses**.
2. Locate the client license and click **Revoke License**.
3. On the next cloud handshake (or sync attempt), the local node receives the revocation signal and locks POS transaction capabilities.

---

## 8. Real-time Sync Payload Stream Inspector

Navigate to **Sync Records** in the sidebar:
- Inspect inbound JSON payloads stream pushed by client workstations.
- Filter by Tenant, Entity Type (customer, sales_order, payment, expense).
- View exact timestamps, local record IDs, and payload snapshots for technical troubleshooting.

---

## 9. System Audit Trail & Security Logs

Navigate to **Audit Logs**:
- Every super-admin login, tenant creation, license issuance, and revocation is recorded with:
  - Admin User ID
  - Action Name
  - Timestamp
  - Client IP Address
  - Action Details

---

## 10. Database Backup & Maintenance

The cloud database laundrypro_cloud should be backed up using mysqldump:
`ash
mysqldump -u root -p laundrypro_cloud > laundrypro_cloud_backup_.sql
`

---

## 11. Backup & Restore Procedures

All system backups are executed via the local PHP API to ensure consistency.

1. **Creating a Backup:** 
   - A cron job or manual trigger calls POST /api/v1/backup/run.
   - The system executes mysqldump, packages the .sql file into a .zip, and generates a SHA-256 cryptographic manifest.
2. **Restoring a Backup:**
   - Call POST /api/v1/backup/restore.
   - The system unpacks the .zip, validates the SHA-256 signature against the manifest to prevent payload tampering, and overwrites the active database.
   - **Never manually restore a raw SQL dump** in a production environment as it bypasses the audit and integrity checks.

---

## 12. Rate Limiting & Security Monitoring

The RateLimitMiddleware protects all /auth/* endpoints against brute-force attacks using an IP-based sliding window throttle.

- **Rule:** Maximum 5 attempts per 1-minute window per IP.
- **Enforcement:** If exceeded, the API returns 429 Too Many Requests.
- **Monitoring:** Check the system_settings table for keys prefixed with 
ate_limit:. These keys store the hit count and expiry timestamp. Admins can manually clear these rows if a legitimate terminal is locked out.

---

## 13. Sync Engine Monitoring

The offline-first sync engine relies on the sync_outbox table and the SyncService background daemon.

- **Monitoring:** Call GET /api/v1/sync/status to check the outbox depth.
- **Outbox States:**
  - pending: Record is queued for the next push cycle.
  - synced: Record successfully received by the cloud.
  - ailed: Push failed. The engine applies an exponential backoff (up to 10 attempts) before parking the record.
- **Alerts:** Set up a monitoring threshold. If pending records exceed 500, or if any record is stuck in ailed for more than 24 hours, an alert should be dispatched to the IT team.

---

## 14. RBAC Role Management

The system uses granular Role-Based Access Control (RBAC). Roles are strictly defined in the 
oles and 
ole_permissions tables.

- **Creating Roles:** Use the **Role Editor Screen** in the Flutter UI or POST /api/v1/roles to create custom roles (e.g., "Junior Cashier", "Inventory Manager").
- **Granular Permissions:** Permissions follow the 
esource.action convention (e.g., sales.read, sales.write, catalog.write, users.manage).
- **Enforcement:** All permissions are validated server-side by the PHP controllers using the JWT payload claims.

---

## 15. Financial Precision Notes (bcmath)

**CRITICAL:** LaundryPro UAE entirely forbids the use of native PHP floating-point numbers (loat / double) for monetary calculations.

- **Why?** Native floats introduce precision loss (e.g.,  .1 + 0.2 = 0.30000000000000004), which compounds into massive discrepancies over thousands of sales and tax calculations.
- **The Standard:** All monetary values are strictly cast to DECIMAL(18,2) in MariaDB and transported as **strings** in JSON payloads.
- **PHP Calculations:** Whenever the API must perform math (e.g., tax calculation, discounts), it strictly uses the cmath extension (cadd, csub, cmul, cdiv) with a scale of 2.
- **Admin Action:** Ensure extension=bcmath is enabled in php.ini on all edge terminals. If disabled, the API will crash on any financial mutation.



## --- FILE: MANUAL_OPERATOR_BOOK.md ---

# LaundryPro UAE — Operator & Cashier User Manual

**Document Version:** 2.1 (Production Release)
**Product Version:** 1.2.1+4
**Target Audience:** Front-desk Cashiers, Store Operators, Laundry Floor Staff, Delivery Drivers

---

## Table of Contents
1. [Starting the Application](#1-starting-the-application)
2. [Splash Screen & Self-Healing Boot](#2-splash-screen--self-healing-boot)
3. [Logging In & Profile Switching](#3-logging-in--profile-switching)
4. [Instant Sale / Counter Point of Sale (POS)](#4-instant-sale--counter-point-of-sale-pos)
5. [Customer CRM & Walk-In Customers](#5-customer-crm--walk-in-customers)
6. [Thermal Receipt Printing & Cash Drawer](#6-thermal-receipt-printing--cash-drawer)
7. [Order Tracking & Processing Movement](#7-order-tracking--processing-movement)
8. [Factory Challans & Delivery Tasks](#8-factory-challans--delivery-tasks)
9. [Staff Attendance Clock-In / Clock-Out](#9-staff-attendance-clock-in--clock-out)
10. [End of Day Closing & Reports](#10-end-of-day-closing--reports)
11. [Offline Resilience & Recovery](#11-offline-resilience--recovery)
12. [Split Payments (Multi-Tender)](#12-split-payments-multi-tender)
13. [Hold & Resume Sales](#13-hold--resume-sales)
14. [Refunds & Correction Memos](#14-refunds--correction-memos)
15. [Keyboard Shortcuts](#15-keyboard-shortcuts)
16. [WhatsApp Receipt Sharing](#16-whatsapp-receipt-sharing)

---

## 1. Starting the Application

Launch LaundryPro UAE from your Windows Desktop shortcut or executable:

`
build\\windows\\x64\\runner\\Release\\laundrypro_uae.exe
`

Ensure that XAMPP (Apache and MySQL) is running on the computer before launching.

---

## 2. Splash Screen & Self-Healing Boot

When the program opens, a modern splash screen validates the system environment:

1. **Verifying Local Node Connectivity:** Checks if the local database and local web server are active.
   - *If offline:* The screen clearly displays: *Unable to connect to local database engine. Please verify XAMPP is running.* You can click **Retry** or **Exit Application**.
2. **Applying Database Upgrades:** Silently checks for pending database migrations and executes them automatically without operator intervention.
3. **Evaluating License & Machine ID:** Checks hardware UMAC and active license quotas.
4. **Cloud Background Handshake:** In the background, contacts the central cloud server to check for sync updates (never blocks offline usage).
5. **Dashboard Transition:** Opens the Login screen smoothly.

---

## 3. Logging In & Profile Switching

1. Enter your operator username and password:
   - **Default Admin:** dmin / dmin123
   - Passwords are case-sensitive. Contact your system administrator if locked out.
2. Select your preferred language:
   - **English (LTR)** or **العربية (Arabic RTL)**.
   - You can toggle language at any time from the top navigation bar.
3. To switch operator profiles mid-shift, click your name avatar in the top-right corner and select **Switch User** without closing the application.

---

## 4. Instant Sale / Counter Point of Sale (POS)

The POS interface is optimised for keyboard, mouse, and touchscreen operation:

1. **Select or Scan Customer:**
   - Use the Customer Search bar (by phone number, name, or code) or click **Walk-in Customer**.
2. **Add Laundry Items:**
   - Tap category buttons (Dry Clean, Wash & Fold, Steam Press, Curtain Care).
   - Click services or scan item barcodes.
   - Adjust quantities using the on-screen keypad (+ / -).
3. **Apply Modifiers & Urgency:**
   - Express Service (+50%), Fragrance, Stiff Starch, Stain Treatment.
4. **Collect Payment:**
   - Choose Payment Method: **Cash**, **Card / Terminal**, **Credit (Account)**, or **Split** (see Section 12).
   - If paying Cash, enter tender amount; the system calculates exact change in AED & Fils.
5. **Finalize Order:**
   - Click **Confirm & Print**. The thermal receipt prints immediately and the cash drawer kicks open.

---

## 5. Customer CRM & Walk-In Customers

1. Navigate to **Customers** on the left navigation rail.
2. Click **New Customer** (F2):
   - Enter Full Name, UAE Mobile Number (+971 50 ...), TRN (if corporate), Delivery Address, Villa/Flat No.
3. View order history, unpaid ledger balances, and loyalty points.

---

## 6. Thermal Receipt Printing & Cash Drawer

- **Printer Models Supported:** Standard 80 mm and 58 mm ESC/POS thermal receipt printers (Epson, Citizen, Bixolon, Xprinter).
- **Cash Drawer:** Automatically pops open via RJ11 pulse on cash transactions.
- **Reprint Receipt:** Open any past order and click **Reprint Receipt** (Ctrl+P).
- **Test Print:** Navigate to **Settings > Peripherals > Test Print** to verify printer alignment.

---

## 7. Order Tracking & Processing Movement

Track order progress through 4 standard stages:

1. **Received (Counter):** Items tagged and bagged.
2. **In Processing (Washing/Dry Cleaning):** Items in wash or dry clean cycle.
3. **Ready for Pickup / Delivery:** Ironed, packaged, and inspected by QC.
4. **Delivered / Completed:** Customer collected or driver delivered.

Status changes are logged with operator name and timestamp for full auditability.

---

## 8. Factory Challans & Delivery Tasks

- **Challans:** For laundries with an off-site central factory, generate a batch transfer Challan with line counts and barcodes for the transport driver.
- **Home Deliveries:** View scheduled deliveries, assign to drivers, and mark completed upon drop-off.

---

## 9. Staff Attendance Clock-In / Clock-Out

1. Navigate to **HR & Attendance**.
2. Staff member selects their profile or scans their employee barcode badge.
3. Tap **Clock In** at the start of shift and **Clock Out** at the end of shift.
4. Records are automatically compiled for monthly UAE Labour Law compliant payroll.

---

## 10. End of Day Closing & Reports

At the end of your shift:
1. Navigate to **Reports** > **Daily Sales Summary**.
2. Verify:
   - Total Cash in Drawer
   - Total Card Payments
   - Total Outstanding Invoices
3. Print the **Shift End / Z-Report** for the store manager.
4. For full shift reconciliation with variance logging, see Section 13: Hold & Resume Sales actually see Shift Close (UC-13 in Blueprint).

---

## 11. Offline Resilience & Recovery

- **Zero Cloud Dependence:** You can continue booking orders, printing receipts, and collecting payments even if the internet is completely disconnected.
- When internet returns, the background sync engine seamlessly uploads records to the central cloud.
- The status bar at the bottom of every screen shows a **Sync Status** indicator:
  - Green dot: All records synced.
  - Amber dot: Pending records in outbox (syncing shortly).
  - Red dot: Offline; records queued locally.

---

## 12. Split Payments (Multi-Tender)

Use Split Payment when a customer wants to settle an invoice with more than one payment method (e.g., part cash, part card).

**Steps:**

1. Build the cart and proceed to **Checkout** as normal.
2. Instead of selecting a single payment method, click **Split Payment**.
3. The Split Payment panel opens showing the full invoice total.
4. Enter the **Cash amount** the customer is paying (e.g., 100.00 AED).
   - The panel automatically shows the **Remaining Balance** (e.g., 110.00 AED).
5. Select the second method for the remaining balance: **Card / Terminal**, **Credit (Account)**, or a third split.
6. For Card: confirm the physical terminal has approved the charge, then click **Card Approved**.
7. Verify the running total matches the invoice total (the **Finalize** button only activates when fully balanced).
8. Click **Finalize Split Payment**.
9. A **single consolidated receipt** prints listing all payment legs.
10. The cash drawer opens only if a cash leg was included.

> **Note:** Change is only calculated and given on the **cash leg**. Card and account legs must be exact amounts.

---

## 13. Hold & Resume Sales

Hold an in-progress cart without losing its contents — useful when a customer needs to step aside or fetch more items.

**To Hold a Sale:**

1. While on the active cart screen, press **Ctrl+H** or click the **Hold Cart** icon (pause symbol) in the toolbar.
2. Enter an optional **Hold Note** (e.g., “customer fetching more garments”).
3. Click **Hold**. The cart is saved and the POS clears to accept a new customer.

**To Resume a Held Sale:**

1. Click the **Held Orders** tray icon in the top navigation bar (shows count badge).
2. Select the held cart from the list.
3. Click **Resume** — the cart reloads with all items, customer details, and modifiers intact.
4. Continue checkout as normal.

> **Important:** Held carts do not generate an invoice or reserve stock. They are session-level holds. If the application is closed, held carts are discarded.

---

## 14. Refunds & Correction Memos

LaundryPro UAE never modifies or deletes an original invoice. All refunds and corrections are handled through a **Correction Memo** (Credit Memo) that links back to the original order.

**Steps to Issue a Correction Memo:**

1. Navigate to **Orders** and search for the original order by number, customer name, or date.
2. Open the order detail view.
3. Click **Issue Correction Memo** (requires Manager role or above).
4. In the dialog:
   - Select the line items to refund (full or partial lines).
   - Enter the **refund reason** (mandatory field).
   - Choose the **refund method**: Cash Return, Account Credit, or Voucher.
5. Click **Confirm Memo**.
6. The system creates a **Credit Memo** (e.g., #CM-2026-00019) with a negative total referencing the original order.
7. A **Correction Memo receipt** prints automatically, clearly headed:

   `
   CORRECTION MEMO — NOT AN INVOICE
   Ref. Original Order: LP-2026-00109
   `

8. Return cash to the customer or apply the credit to their account.

> **Key Rules:**
> - The original invoice remains unchanged and visible in history.
> - Only managers and above can issue correction memos.
> - Partial refunds are allowed; you cannot refund more than the original line quantity.

---

## 15. Keyboard Shortcuts

Keyboard shortcuts accelerate high-volume counter operations. All shortcuts are active when the POS or Orders screen is in focus.

| Shortcut | Action |
|---|---|
| **F1** | Open Help / This Manual |
| **F2** | New Customer |
| **F3** | Customer Search |
| **F4** | New Order / Open Cart |
| **F5** | Refresh Current Screen |
| **F6** | Apply Express (+50%) modifier to selected line |
| **F8** | Void / Remove selected cart line |
| **F9** | Open Cash Drawer (manual pulse) |
| **F10** | Proceed to Checkout |
| **F11** | Toggle Full-Screen Mode |
| **F12** | Reprint Last Receipt |
| **Ctrl+H** | Hold Current Cart |
| **Ctrl+P** | Print / Reprint Receipt |
| **Ctrl+R** | Open Refund / Correction Memo |
| **Ctrl+Z** | Undo Last Item Add (cart only) |
| **Ctrl+S** | Save Draft (hold cart silently) |
| **Ctrl+Shift+S** | Shift Close Screen |
| **Ctrl+W** | Send WhatsApp Receipt (see Section 16) |
| **Escape** | Cancel current dialog / close panel |
| **Enter** | Confirm active dialog / proceed |
| **+** / **-** | Increase / Decrease selected item quantity |
| **Numpad 0–9** | Quick quantity entry on focused line |

---

## 16. WhatsApp Receipt Sharing

Send a digital receipt directly to the customer\'s WhatsApp number immediately after payment.

**After completing a sale:**

1. The post-payment confirmation screen shows a **Send WhatsApp Receipt** button (or press **Ctrl+W**).
2. Verify the customer\'s UAE mobile number displayed (pre-filled from the customer record).
3. Click **Send via WhatsApp**.
4. The system constructs a WhatsApp deep-link with the receipt summary pre-filled in the message body:
   `
   https://wa.me/971501234567?text=LaundryPro+UAE+Receipt+%23LP-2026-00109...
   `
5. Windows opens the WhatsApp Desktop app (or WhatsApp Web in browser).
6. Review the pre-filled message and click **Send** in WhatsApp.

**To share a receipt for a past order:**

1. Open the order in **Orders > Order Detail**.
2. Click the **WhatsApp** icon in the action bar.
3. Follow steps 2–6 above.

> **Note:** WhatsApp sharing uses the standard wa.me deep-link protocol and requires WhatsApp Desktop or WhatsApp Web to be installed and logged in on the workstation. An active internet connection is required for WhatsApp delivery; the local POS operates fully without it.


## --- FILE: README.md ---

﻿# LaundryPro UAE - Documentation Universe
> **Version:** 1.0.0 | **Last Updated:** 2026-09-21
> **Company:** Magnificent Solution
> **Product:** LaundryPro UAE Multi-Tenant Offline-First ERP/CRM/POS

## Purpose
This documentation covers every aspect of LaundryPro UAE: requirements, architecture, data models, workflows, API specifications, UI/UX, testing, deployment, security, compliance, and operational procedures.

## Directory Structure
| Directory | Contents |
|-----------|----------|
| requirements/ | Business and functional requirements |
| architecture/ | System architecture and design patterns |
| blueprints/ | Module blueprints and feature specifications |
| data/ | Database schema, ER diagrams, data dictionary |
| workflows/ | Business workflow documentation |
| use-cases/ | Actor-based use case documentation |
| user-journeys/ | End-to-end user journey maps |
| ui/ | Screen specifications and design system |
| api/ | REST API documentation and specifications |
| forms/ | Form specifications and validation rules |
| edge-cases/ | Edge case catalog and boundary conditions |
| testing/ | Test plans, strategies, and reports |
| dependencies/ | Technology stack and dependency documentation |
| flows/ | Data flow and process flow diagrams |
| integrations/ | Hardware and third-party integration docs |
| operations/ | Deployment, backup, monitoring, runbooks |
| security/ | Security architecture and policies |
| compliance/ | UAE regulatory compliance documentation |
| marketing/ | Product marketing and sales materials |
| training/ | User training materials and guides |
| licensing/ | UMAC licensing documentation |
| multitenancy/ | Multi-tenant architecture documentation |
| sync/ | Offline-first sync engine documentation |
| reference/ | Quick reference cards and cheat sheets |
| appendices/ | Glossary, acronyms, bibliography |

## --- FILE: SPRINT_ROADMAP.md ---

# Full Project Audit & Unified Sprint Roadmap — LaundryPro UAE
> **Audit Date:** 2026-09-21 | **Auditor:** AI Principal Architect
> **Status:** Production Development — Sprint 1 Ready

---

## Part 1: Complete Project Audit

### 1.1 Source Code Inventory

| Layer | Files | Lines | Status |
|-------|-------|-------|--------|
| Flutter (lib/) | 148 .dart | 16,026 | Active development |
| PHP API (api/) | 120 .php | 11,065 | Active development |
| Cloud API (cloud-api/) | 16 .php | 1,360 | Basic scaffold |
| SQL Migrations | 66 .sql | ~7,500 | Baseline + 30 archived |
| Tests | 22 .dart | ~1,200 | Peripherals only |
| .ai/ Ecosystem | 182 .md | ~15,000 | **COMPLETE** |
| docs/ Universe | 115 .md | ~8,000 | **COMPLETE** |
| Scripts | 12 | ~800 | Utility scripts |
| **TOTAL** | **681** | **~60,000** | |

### 1.2 Flutter Architecture Audit

#### Existing Screens (42 views) ✅
| Screen | File | Status |
|--------|------|--------|
| Login | login_screen.dart | ✅ Built |
| Dashboard | dashboard_screen.dart | ✅ Built |
| POS | pos_screen.dart | ✅ Built |
| Customers | customers_screen.dart | ✅ Built |
| Catalog/Services | catalog_screen.dart | ✅ Built |
| Orders/Sales | (via pos_screen) | ✅ Built |
| Employees | employees_screen.dart | ✅ Built |
| Attendance | attendance_screen.dart | ✅ Built |
| Payroll | payroll_screen.dart | ✅ Built |
| Leave | leave_screen.dart | ✅ Built |
| Delivery | delivery_screen.dart | ✅ Built |
| Branches | branches_screen.dart | ✅ Built |
| Invoices | pending_invoices_screen.dart | ✅ Built |
| Inventory/Equipment | equipment_screen.dart | ✅ Built |
| Expenses | expenses_screen.dart | ✅ Built |
| Reports | reports_screen.dart | ✅ Built |
| Analytics | analytics_screen.dart | ✅ Built |
| Settings | settings_screen.dart | ✅ Built |
| Production | production_screen.dart | ✅ Built |
| Operators | operator_screen.dart | ✅ Built |
| License | license_screen.dart | ✅ Built |
| Peripherals | peripherals_screen.dart | ✅ Built |
| Sync Settings | sync_settings_screen.dart | ✅ Built |
| Vendors | vendors_screen.dart | ✅ Built |
| Purchasing | purchasing_screen.dart | ✅ Built |
| Challans | challans_screen.dart | ✅ Built |
| Notifications | notifications_screen.dart | ✅ Built |
| Channels | channels_screen.dart | ✅ Built |
| RFID Tracking | rfid_tracking_screen.dart | ✅ Built |
| Sterilization | sterilization_screen.dart | ✅ Built |
| Storefront | storefront_screen.dart | ✅ Built |
| Customer Portal | customer_portal_screen.dart | ✅ Built |
| Accounting | accounting_screen.dart | ✅ Built |
| Setup Wizard | setup_wizard_screen.dart | ✅ Built |
| App Shell | app_shell.dart | ✅ Built |
| Splash | splash_screen.dart | ✅ Built |
| Business | business_screen.dart | ✅ Built |
| Localization | localization_screen.dart | ✅ Built |
| Role Editor | role_editor_screen.dart | ✅ Built |
| Terminals | terminals_screen.dart | ✅ Built |
| Global Config | global_config_screen.dart | ✅ Built |
| Salary Advances | salary_advances_screen.dart | ✅ Built |
| Advanced Cycle | advanced_cycle_screen.dart | ✅ Built |

#### Existing Services (37 services) ✅
All 37 API service clients are built covering auth, sales, customers, employees, payroll, delivery, inventory, reports, sync, and more.

#### Existing Core (9 files) ✅
Theme, localization, receipt model/renderer, document renderer, phone normalizer, constants, API exception.

---

### 1.3 PHP API Architecture Audit

#### Controllers (37) ✅
Full CRUD controllers for all modules including Auth, Sales, Customers, HR, Delivery, Inventory, Reports, Sync, License, Settings, and specialized controllers (RFID, Sterilization, Storefront, Portal).

#### Repositories (34) ✅
Complete repository layer with data access for all entities.

#### Security (4 files) ✅
- JwtService.php ✅
- PasswordHasher.php ✅
- PermissionChecker.php ✅
- UmacService.php ✅

#### Middleware (2 files)
- Middleware.php ✅
- RateLimitMiddleware.php ✅

#### Services (11 files)
- AuthService ✅, BackupService ✅, InstallService ✅, LicenseService ✅
- MessagingService ✅, MigrationService ✅, SeedService ✅, SyncService ✅
- AccountingExportService ✅, TwilioSmsAdapter ✅, SmsAdapterInterface ✅

---

### 1.4 Critical Gap Analysis

> [!IMPORTANT]
> The following items are **MISSING** and required for production readiness.

#### Flutter — Missing Models (14 files)
| Model | Purpose | Priority |
|-------|---------|----------|
| order_model.dart | Order data class with fromJson/toJson | P0 |
| customer_model.dart | Customer data class | P0 |
| invoice_model.dart | Invoice data class (immutable posted) | P0 |
| product_model.dart | Service/product catalog model | P0 |
| employee_model.dart | Employee data class | P0 |
| payment_model.dart | Payment transaction model | P0 |
| branch_model.dart | Branch data class | P0 |
| service_model.dart | Laundry service type model | P0 |
| delivery_model.dart | Delivery assignment model | P1 |
| inventory_model.dart | Inventory item model | P1 |
| attendance_model.dart | Attendance record model | P1 |
| payroll_model.dart | Payroll calculation model | P1 |
| sync_entry_model.dart | Sync outbox entry model | P1 |
| garment_tag_model.dart | Garment barcode/RFID tag model | P2 |

#### Flutter — Missing Core Utilities (6 files)
| File | Purpose | Priority |
|------|---------|----------|
| validators.dart | Form validation functions (UAE phone, TRN, email) | P0 |
| formatters.dart | Currency, date, number formatters | P0 |
| money_utils.dart | Decimal-safe money arithmetic | P0 |
| date_utils.dart | Date helpers, business day calc | P1 |
| database/local_database.dart | SQLite local DB setup (drift) | P1 |
| sync/sync_engine.dart | Offline sync outbox engine | P1 |

#### Flutter — Missing Localization (2 files)
| File | Purpose | Priority |
|------|---------|----------|
| l10n/en.json | English locale strings | P0 |
| l10n/ar.json | Arabic locale strings | P0 |

#### PHP — Missing Business Services (5 files)
| Service | Purpose | Priority |
|---------|---------|----------|
| VatCalculator.php | UAE VAT 5% calculation (bcmath) | P0 |
| InvoiceNumberGenerator.php | Sequential INV-YYYY-NNNNNN | P0 |
| OrderNumberGenerator.php | Sequential ORD-YYYY-NNNNNN | P0 |
| PayrollCalculator.php | UAE overtime rules (1.25x/1.5x/2x) | P1 |
| SifExporter.php | WPS SIF file generation | P1 |

#### PHP — Missing Middleware (2 files)
| Middleware | Purpose | Priority |
|-----------|---------|----------|
| IdempotencyMiddleware.php | Prevent duplicate writes via UUID key | P0 |
| AuditLogMiddleware.php | Auto-log all state changes | P0 |

#### Configuration — Missing (2 files)
| File | Purpose | Priority |
|------|---------|----------|
| .env.example | Environment variable template | P0 |
| api/.env.example | API environment template | P0 |

---

### 1.5 Module Readiness Matrix

| Module | Screen | Service | Controller | Repository | Model | Tests | **Ready** |
|--------|:------:|:-------:|:----------:|:----------:|:-----:|:-----:|:---------:|
| Auth | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | 80% |
| Dashboard | ✅ | ✅ | ✅ | ✅ | N/A | ❌ | 80% |
| POS/Sales | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 70% |
| Customers | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 70% |
| Catalog | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 70% |
| Employees | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 70% |
| Attendance | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 70% |
| Payroll | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 60% |
| Leave | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 70% |
| Delivery | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 70% |
| Inventory | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 70% |
| Production | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 70% |
| Invoicing | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 60% |
| Reports | ✅ | ✅ | ✅ | ✅ | N/A | ❌ | 75% |
| Sync | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 50% |
| License/UMAC | ✅ | ✅ | ✅ | N/A | N/A | ❌ | 70% |
| Peripherals | ✅ | ✅ | N/A | N/A | N/A | ✅ | 85% |
| Settings | ✅ | ✅ | ✅ | ✅ | N/A | ❌ | 80% |

### 1.6 Architecture Compliance

| Rule | Status | Notes |
|------|--------|-------|
| DECIMAL(18,2) for money | ✅ | Enforced in 001_baseline.sql |
| business_owner_id on data tables | ✅ | Present in baseline schema |
| RBAC PermissionChecker | ✅ | api/src/Security/PermissionChecker.php exists |
| JWT Auth | ✅ | JwtService.php + auth middleware |
| MVVM + Riverpod | ⚠️ | Screens exist but models layer is thin (only user_model) |
| Clean Architecture (PHP) | ✅ | Controller -> Service -> Repository -> PDO |
| Offline-first sync outbox | ⚠️ | Table exists, SyncService.php exists, Flutter sync_engine missing |
| LTR/RTL support | ⚠️ | Localization core exists but en.json/ar.json missing |
| Audit logging | ⚠️ | AuditLogRepository exists, auto-middleware missing |
| Sequential numbering | ❌ | InvoiceNumberGenerator + OrderNumberGenerator missing |
| UMAC licensing | ✅ | UmacService.php + license_screen.dart exist |
| SHA-256 backups | ✅ | BackupService.php exists |

---

## Part 2: Unified Sprint Roadmap — Remaining Development

> [!NOTE]
> Based on the audit, the project is approximately **65-70% complete**. The remaining work focuses on: models, utilities, localization, missing middleware/services, comprehensive tests, and production hardening.

---

### Sprint R1: Models & Core Utilities (Week 1-2)
> **Goal:** Complete the data model layer and core utilities that every module depends on.

| # | Task | File(s) | Owner | Est. | Priority | Depends On |
|---|------|---------|-------|------|----------|------------|
| R1.01 | Create `customer_model.dart` with fromJson/toJson, Equatable, copyWith | lib/models/customer_model.dart | ENG-FLUTTER | 2h | P0 | — |
| R1.02 | Create `order_model.dart` + `order_item_model.dart` | lib/models/order_model.dart, lib/models/order_item_model.dart | ENG-FLUTTER | 3h | P0 | — |
| R1.03 | Create `invoice_model.dart` with immutability flag | lib/models/invoice_model.dart | ENG-FLUTTER | 2h | P0 | — |
| R1.04 | Create `payment_model.dart` | lib/models/payment_model.dart | ENG-FLUTTER | 1h | P0 | — |
| R1.05 | Create `employee_model.dart` | lib/models/employee_model.dart | ENG-FLUTTER | 2h | P0 | — |
| R1.06 | Create `branch_model.dart` | lib/models/branch_model.dart | ENG-FLUTTER | 1h | P0 | — |
| R1.07 | Create `service_model.dart` (catalog) | lib/models/service_model.dart | ENG-FLUTTER | 1h | P0 | — |
| R1.08 | Create `delivery_model.dart` | lib/models/delivery_model.dart | ENG-FLUTTER | 2h | P1 | — |
| R1.09 | Create `inventory_model.dart` | lib/models/inventory_model.dart | ENG-FLUTTER | 1h | P1 | — |
| R1.10 | Create `attendance_model.dart` | lib/models/attendance_model.dart | ENG-FLUTTER | 1h | P1 | — |
| R1.11 | Create `payroll_model.dart` | lib/models/payroll_model.dart | ENG-FLUTTER | 2h | P1 | — |
| R1.12 | Create `sync_entry_model.dart` | lib/models/sync_entry_model.dart | ENG-FLUTTER | 2h | P1 | — |
| R1.13 | Create `garment_tag_model.dart` | lib/models/garment_tag_model.dart | ENG-FLUTTER | 1h | P2 | — |
| R1.14 | Create `money_utils.dart` (Decimal-safe math, ROUND_HALF_UP) | lib/core/money_utils.dart | ENG-FLUTTER | 3h | P0 | — |
| R1.15 | Create `validators.dart` (UAE phone +971, TRN 15-digit, email, required) | lib/core/validators.dart | ENG-FLUTTER | 3h | P0 | — |
| R1.16 | Create `formatters.dart` (currency AED, date DD/MM/YYYY, number) | lib/core/formatters.dart | ENG-FLUTTER | 2h | P0 | — |
| R1.17 | Create `date_utils.dart` (business days, overtime calc support) | lib/core/date_utils.dart | ENG-FLUTTER | 2h | P1 | — |
| R1.18 | Create `.env.example` at project root | .env.example | ENG-DEVOPS | 1h | P0 | — |
| R1.19 | Create `api/.env.example` | api/.env.example | ENG-DEVOPS | 1h | P0 | — |
| R1.20 | Update all 37 services to use typed models instead of raw Maps | lib/services/*.dart | ENG-FLUTTER | 8h | P0 | R1.01-R1.13 |

> **Sprint R1 Total: ~38 hours | 20 tasks | Exit: All models compile, all services typed**

---

### Sprint R2: Localization & RTL (Week 3-4)
> **Goal:** Full bilingual support (English + Arabic) across all 42 screens.

| # | Task | File(s) | Owner | Est. | Priority | Depends On |
|---|------|---------|-------|------|----------|------------|
| R2.01 | Create `en.json` with all UI strings (~500+ keys) | lib/l10n/en.json | PROD-UID | 6h | P0 | — |
| R2.02 | Create `ar.json` with Arabic translations (~500+ keys) | lib/l10n/ar.json | PROD-UID | 8h | P0 | R2.01 |
| R2.03 | Integrate flutter_localizations + intl in pubspec.yaml | pubspec.yaml | ENG-FLUTTER | 1h | P0 | — |
| R2.04 | Create localization delegate and app_localizations.dart | lib/core/app_localizations.dart | ENG-FLUTTER | 3h | P0 | R2.01 |
| R2.05 | Replace all hardcoded strings in 42 screens with locale keys | lib/views/*.dart | ENG-FLUTTER | 12h | P0 | R2.04 |
| R2.06 | Add RTL layout testing for all screens | test/l10n/ | QA-A11Y | 6h | P0 | R2.05 |
| R2.07 | Add Arabic font (Noto Sans Arabic) to assets | pubspec.yaml, fonts/ | PROD-UID | 1h | P0 | — |
| R2.08 | Implement locale toggle in app shell (EN/AR switch) | lib/views/app_shell.dart | ENG-FLUTTER | 2h | P0 | R2.04 |
| R2.09 | Ensure all padding/margin uses start/end (not left/right) | lib/views/*.dart | ENG-FLUTTER | 4h | P0 | — |
| R2.10 | Ensure number display stays LTR in RTL context | lib/core/formatters.dart | ENG-FLUTTER | 2h | P1 | R2.04 |

> **Sprint R2 Total: ~45 hours | 10 tasks | Exit: App fully usable in Arabic RTL**

---

### Sprint R3: PHP Business Services & Middleware (Week 5-6)
> **Goal:** Complete missing server-side business logic and security middleware.

| # | Task | File(s) | Owner | Est. | Priority | Depends On |
|---|------|---------|-------|------|----------|------------|
| R3.01 | Create `VatCalculator.php` (5% VAT, bcmath, ROUND_HALF_UP) | api/src/Services/VatCalculator.php | FIN-VAT | 3h | P0 | — |
| R3.02 | Create `InvoiceNumberGenerator.php` (INV-YYYY-NNNNNN, gap-free) | api/src/Services/InvoiceNumberGenerator.php | FIN-BILLING | 4h | P0 | — |
| R3.03 | Create `OrderNumberGenerator.php` (ORD-YYYY-NNNNNN, gap-free) | api/src/Services/OrderNumberGenerator.php | ENG-PHP | 3h | P0 | — |
| R3.04 | Create `PayrollCalculator.php` (UAE overtime 1.25x/1.5x/2x, gratuity) | api/src/Services/PayrollCalculator.php | HR-PAYROLL | 6h | P0 | — |
| R3.05 | Create `SifExporter.php` (WPS SIF file format) | api/src/Services/SifExporter.php | HR-PAYROLL | 4h | P1 | R3.04 |
| R3.06 | Create `IdempotencyMiddleware.php` (UUID dedup on write ops) | api/src/Middleware/IdempotencyMiddleware.php | ENG-PHP | 4h | P0 | — |
| R3.07 | Create `AuditLogMiddleware.php` (auto-log all POST/PATCH/DELETE) | api/src/Middleware/AuditLogMiddleware.php | SEC-AUDIT | 4h | P0 | — |
| R3.08 | Integrate VatCalculator into SalesController + InvoiceController | api/src/Controllers/ | ENG-PHP | 3h | P0 | R3.01 |
| R3.09 | Integrate sequential numbering into Sales + Invoice flows | api/src/Controllers/ | ENG-PHP | 3h | P0 | R3.02, R3.03 |
| R3.10 | Register IdempotencyMiddleware on all write endpoints | api/src/routes.php or equivalent | ENG-PHP | 2h | P0 | R3.06 |
| R3.11 | Register AuditLogMiddleware on all state-changing endpoints | api/src/routes.php or equivalent | ENG-PHP | 2h | P0 | R3.07 |
| R3.12 | Implement immutable invoice enforcement (block UPDATE on status=posted) | api/src/Services/ | FIN-BILLING | 3h | P0 | — |
| R3.13 | Add correction memo endpoint (POST /invoices/:id/correction) | api/src/Controllers/SalesController.php | FIN-BILLING | 4h | P1 | R3.12 |
| R3.14 | Implement hash-chained audit logs (SHA-256 chain) | api/src/Repositories/AuditLogRepository.php | SEC-AUDIT | 4h | P1 | — |

> **Sprint R3 Total: ~49 hours | 14 tasks | Exit: All business services operational, middleware enforced**

---

### Sprint R4: Offline Sync Engine (Week 7-8)
> **Goal:** Complete offline-first sync between Flutter SQLite and PHP/MariaDB.

| # | Task | File(s) | Owner | Est. | Priority | Depends On |
|---|------|---------|-------|------|----------|------------|
| R4.01 | Setup drift (SQLite ORM) in Flutter project | pubspec.yaml, lib/core/database/ | ENG-FLUTTER | 4h | P0 | — |
| R4.02 | Create local database schema mirroring key MariaDB tables | lib/core/database/local_database.dart | ENG-FLUTTER | 6h | P0 | R4.01 |
| R4.03 | Create `sync_outbox.dart` (local outbox table + CRUD) | lib/core/sync/sync_outbox.dart | ENG-SYNC | 4h | P0 | R4.01 |
| R4.04 | Create `sync_engine.dart` (push/pull coordinator) | lib/core/sync/sync_engine.dart | ENG-SYNC | 8h | P0 | R4.03 |
| R4.05 | Implement connectivity detection (online/offline status) | lib/core/sync/connectivity_monitor.dart | ENG-SYNC | 3h | P0 | — |
| R4.06 | Implement push protocol (batch POST to /sync/push) | lib/core/sync/push_protocol.dart | ENG-SYNC | 4h | P0 | R4.04 |
| R4.07 | Implement pull protocol (GET /sync/pull?since=) | lib/core/sync/pull_protocol.dart | ENG-SYNC | 4h | P0 | R4.04 |
| R4.08 | Implement conflict resolution (LWW by updated_at) | lib/core/sync/conflict_resolver.dart | ENG-SYNC | 4h | P0 | R4.06, R4.07 |
| R4.09 | Create sync status UI widget (pending/synced/failed counts) | lib/widgets/sync_status_widget.dart | ENG-FLUTTER | 3h | P1 | R4.04 |
| R4.10 | Integrate sync engine into all write operations across services | lib/services/*.dart | ENG-SYNC | 6h | P0 | R4.04 |
| R4.11 | Dead-letter queue management screen | lib/views/sync_settings_screen.dart | ENG-FLUTTER | 3h | P1 | R4.04 |
| R4.12 | Sync engine unit tests (offline, online, conflict scenarios) | test/sync/ | QA-AUTO | 6h | P0 | R4.04 |

> **Sprint R4 Total: ~55 hours | 12 tasks | Exit: App works 30+ days offline, syncs correctly**

---

### Sprint R5: Unit Tests — Auth, Models, Core (Week 9-10)
> **Goal:** 80%+ test coverage on models, core utilities, and auth flow.

| # | Task | File(s) | Owner | Est. | Priority | Depends On |
|---|------|---------|-------|------|----------|------------|
| R5.01 | Unit tests for all 14 model classes (fromJson, toJson, equality) | test/models/ | QA-AUTO | 8h | P0 | R1 |
| R5.02 | Unit tests for money_utils.dart (precision, rounding, edge cases) | test/core/money_utils_test.dart | QA-AUTO | 4h | P0 | R1.14 |
| R5.03 | Unit tests for validators.dart (UAE phone, TRN, email) | test/core/validators_test.dart | QA-AUTO | 3h | P0 | R1.15 |
| R5.04 | Unit tests for formatters.dart (currency, date, number) | test/core/formatters_test.dart | QA-AUTO | 3h | P0 | R1.16 |
| R5.05 | Unit tests for VatCalculator.php (5% calc, rounding, zero, max) | test/php/VatCalculatorTest.php | QA-AUTO | 3h | P0 | R3.01 |
| R5.06 | Unit tests for InvoiceNumberGenerator.php (sequential, no gaps) | test/php/InvoiceNumberTest.php | QA-AUTO | 3h | P0 | R3.02 |
| R5.07 | Unit tests for OrderNumberGenerator.php (sequential, no gaps) | test/php/OrderNumberTest.php | QA-AUTO | 2h | P0 | R3.03 |
| R5.08 | Unit tests for PayrollCalculator.php (overtime, gratuity) | test/php/PayrollCalculatorTest.php | QA-AUTO | 4h | P0 | R3.04 |
| R5.09 | Unit tests for auth_service.dart (login, refresh, logout, error) | test/services/auth_service_test.dart | QA-AUTO | 4h | P0 | — |
| R5.10 | Unit tests for AuthService.php + JwtService.php | test/php/AuthServiceTest.php | QA-AUTO | 4h | P0 | — |
| R5.11 | Unit tests for PermissionChecker.php (all 6 roles, scope combos) | test/php/PermissionCheckerTest.php | QA-AUTO | 4h | P0 | — |
| R5.12 | Unit tests for UmacService.php (hash, validate, grace period) | test/php/UmacServiceTest.php | QA-AUTO | 3h | P1 | — |
| R5.13 | Unit tests for SyncService.php (push, pull, conflict, idempotency) | test/php/SyncServiceTest.php | QA-AUTO | 4h | P0 | — |
| R5.14 | Unit tests for AuditLogRepository (hash chain integrity) | test/php/AuditLogTest.php | QA-AUTO | 3h | P1 | R3.14 |
| R5.15 | Run flutter test with coverage report, verify >= 80% | — | QA-AUTO | 2h | P0 | R5.01-R5.04 |

> **Sprint R5 Total: ~52 hours | 15 tasks | Exit: 80%+ unit test coverage, all tests green**

---

### Sprint R6: Integration Tests & API Tests (Week 11-12)
> **Goal:** End-to-end API testing and cross-module integration verification.

| # | Task | File(s) | Owner | Est. | Priority | Depends On |
|---|------|---------|-------|------|----------|------------|
| R6.01 | API integration test: Auth flow (login -> token -> refresh -> logout) | test/integration/auth_flow_test.dart | QA-AUTO | 4h | P0 | R5 |
| R6.02 | API integration test: Order lifecycle (create -> update -> complete) | test/integration/order_flow_test.dart | QA-AUTO | 6h | P0 | R5 |
| R6.03 | API integration test: Invoice lifecycle (create -> post -> immutable) | test/integration/invoice_flow_test.dart | QA-AUTO | 4h | P0 | R5 |
| R6.04 | API integration test: Payment flow (full, partial, split) | test/integration/payment_flow_test.dart | QA-AUTO | 4h | P0 | R5 |
| R6.05 | API integration test: Tenant isolation (cross-tenant blocked) | test/integration/tenant_isolation_test.dart | QA-SECTEST | 4h | P0 | — |
| R6.06 | API integration test: RBAC enforcement (6 roles x key endpoints) | test/integration/rbac_test.dart | QA-SECTEST | 6h | P0 | — |
| R6.07 | API integration test: Sync push/pull (batch, idempotency, conflict) | test/integration/sync_test.dart | QA-AUTO | 6h | P0 | R4 |
| R6.08 | API integration test: Payroll + SIF export | test/integration/payroll_test.dart | QA-AUTO | 4h | P1 | R3.04 |
| R6.09 | API integration test: Backup + SHA-256 verify + restore | test/integration/backup_test.dart | QA-AUTO | 3h | P1 | — |
| R6.10 | Widget integration test: POS flow (select -> pay -> receipt) | test/widget/pos_flow_test.dart | QA-AUTO | 6h | P0 | R1, R2 |
| R6.11 | Widget integration test: Login -> Dashboard -> Navigate | test/widget/navigation_test.dart | QA-AUTO | 4h | P0 | R2 |
| R6.12 | Edge case test suite: monetary precision (zero, max, negative) | test/edge/monetary_edge_test.dart | QA-EDGE | 4h | P0 | R1.14 |
| R6.13 | Edge case test suite: offline 30-day scenario | test/edge/offline_edge_test.dart | QA-EDGE | 4h | P0 | R4 |
| R6.14 | PHPUnit test suite setup and CI runner script | scripts/run_php_tests.ps1 | QA-AUTO | 3h | P0 | — |

> **Sprint R6 Total: ~62 hours | 14 tasks | Exit: All integration tests green, edge cases validated**

---

### Sprint R7: Production Hardening & Security (Week 13-14)
> **Goal:** Security hardening, performance optimization, and production readiness.

| # | Task | File(s) | Owner | Est. | Priority | Depends On |
|---|------|---------|-------|------|----------|------------|
| R7.01 | SQL injection audit: verify all queries use prepared statements | api/src/Repositories/*.php | SEC-APPSEC | 6h | P0 | — |
| R7.02 | XSS prevention: sanitize all user inputs in API responses | api/src/Controllers/*.php | SEC-APPSEC | 4h | P0 | — |
| R7.03 | RBAC endpoint coverage: verify every route has PermissionChecker | api/src/routes.php | SEC-APPSEC | 4h | P0 | — |
| R7.04 | Rate limiting configuration for auth endpoints (brute-force) | api/src/Middleware/RateLimitMiddleware.php | SEC-APPSEC | 2h | P0 | — |
| R7.05 | Account lockout after 5 failed login attempts | api/src/Services/AuthService.php | SEC-APPSEC | 3h | P0 | — |
| R7.06 | UMAC full flow test (bind, validate, grace period, read-only) | test/security/ | QA-SECTEST | 4h | P0 | — |
| R7.07 | PII encryption at rest for sensitive fields | api/src/Core/Encryption.php | SEC-APPSEC | 6h | P1 | — |
| R7.08 | Database query optimization: add missing composite indexes | api/database/migrations/003_indexes.sql | ENG-DB | 4h | P0 | — |
| R7.09 | API response time profiling (target P95 < 500ms) | scripts/api_benchmark.ps1 | ENG-PERF | 4h | P0 | — |
| R7.10 | Flutter widget rebuild profiling (eliminate unnecessary rebuilds) | lib/views/*.dart | ENG-PERF | 6h | P1 | — |
| R7.11 | Memory leak detection and fix | — | ENG-PERF | 4h | P1 | — |
| R7.12 | Create SECURITY.md (vulnerability disclosure process) | SECURITY.md | SEC-APPSEC | 2h | P1 | — |
| R7.13 | Dependency vulnerability scan (pub audit, composer audit) | — | SEC-APPSEC | 2h | P0 | — |

> **Sprint R7 Total: ~51 hours | 13 tasks | Exit: Security audit clean, perf targets met**

---

### Sprint R8: MSIX Packaging & Release (Week 15-16)
> **Goal:** Production MSIX build, code signing, install testing, go-live.

| # | Task | File(s) | Owner | Est. | Priority | Depends On |
|---|------|---------|-------|------|----------|------------|
| R8.01 | Configure msix_config.yaml with production values | msix_config.yaml | ENG-MSIX | 2h | P0 | — |
| R8.02 | Code signing certificate setup (.pfx) | — | ENG-MSIX | 4h | P0 | — |
| R8.03 | Build release Flutter Windows executable | — | ENG-MSIX | 2h | P0 | R7 |
| R8.04 | Build and sign MSIX package | — | ENG-MSIX | 2h | P0 | R8.02, R8.03 |
| R8.05 | Install test on clean Windows 10 machine | — | QA-MANUAL | 3h | P0 | R8.04 |
| R8.06 | Install test on clean Windows 11 machine | — | QA-MANUAL | 3h | P0 | R8.04 |
| R8.07 | Uninstall + reinstall test (data preservation) | — | QA-MANUAL | 2h | P0 | R8.04 |
| R8.08 | Auto-update mechanism via AppInstaller | — | ENG-MSIX | 4h | P1 | R8.04 |
| R8.09 | Full regression suite on release build | — | QA-REGRESS | 8h | P0 | R8.04 |
| R8.10 | WCAG 2.1 AA accessibility audit (all 42 screens) | — | QA-A11Y | 6h | P0 | R2 |
| R8.11 | Create CHANGELOG.md with v1.0.0 release notes | CHANGELOG.md | PROD-PO | 2h | P0 | — |
| R8.12 | Create README.md install/quickstart guide | README.md | OPS-TRAIN | 3h | P0 | — |
| R8.13 | Version bump: pubspec.yaml, msix_config.yaml (1.0.0) | — | ENG-MSIX | 1h | P0 | — |
| R8.14 | CTO + CEO sign-off for GA release | — | EXEC | 2h | P0 | R8.09 |
| R8.15 | Tag v1.0.0 in Git and push release | — | ENG-DEVOPS | 1h | P0 | R8.14 |

> **Sprint R8 Total: ~45 hours | 15 tasks | Exit: v1.0.0 MSIX signed, tested, released**

---

## Part 3: Summary Dashboard

### Sprint Overview

| Sprint | Focus | Tasks | Hours | Weeks | Deps |
|--------|-------|-------|-------|-------|------|
| **R1** | Models & Core Utilities | 20 | 38h | 1-2 | — |
| **R2** | Localization & RTL | 10 | 45h | 3-4 | R1 |
| **R3** | PHP Business Services | 14 | 49h | 5-6 | — |
| **R4** | Offline Sync Engine | 12 | 55h | 7-8 | R1 |
| **R5** | Unit Tests | 15 | 52h | 9-10 | R1,R3 |
| **R6** | Integration Tests | 14 | 62h | 11-12 | R4,R5 |
| **R7** | Security & Performance | 13 | 51h | 13-14 | R6 |
| **R8** | MSIX & Release | 15 | 45h | 15-16 | R7 |
| **TOTAL** | | **113 tasks** | **397h** | **16 weeks** | |

### Parallel Execution Opportunities
- **R1 + R3** can run in parallel (Flutter models + PHP services, different developers)
- **R2** can start once R1 is 50% done (screens exist, just need locale keys)
- **R4** can start once R1 is complete (needs models)
- **R5 + R6** sequential (unit before integration)

### Optimized Timeline (with parallelism)
```
Week 1-2:  R1 (Models)  +  R3 (PHP Services)     [PARALLEL]
Week 3-4:  R2 (L10n)    +  R3 cont.               [PARALLEL]
Week 5-6:  R4 (Sync)    +  R2 cont.               [PARALLEL]
Week 7-8:  R5 (Unit Tests)
Week 9-10: R6 (Integration Tests)
Week 11-12: R7 (Security & Perf)
Week 13-14: R8 (MSIX & Release)
```
**Optimized: 14 weeks to GA v1.0.0**

### Milestone Gates

| Milestone | Sprint | Criteria |
|-----------|--------|----------|
| **M1: Feature Complete** | R4 | All models, services, sync, localization operational |
| **M2: Test Complete** | R6 | 80%+ coverage, all integration tests green |
| **M3: Release Candidate** | R7 | Security clean, perf targets met |
| **M4: GA v1.0.0** | R8 | MSIX signed, install tested, CTO approved |


## --- FILE: UNIFIED_REMAINING_TASKS.md ---

# LaundryPro UAE — Unified Remaining Tasks & Development Plan

*Consolidated master plan for the final sprint to production.*

## 1. Flutter Frontend (Desktop + Android)
- [x] **API Integration:** Connect the `ApiClient` (Dio) to the Local PHP API.
- [x] **State Management:** Map Riverpod providers to real API responses (e.g., `CatalogProvider`, `PosCartProvider`).
- [x] **Hardware Abstraction Layer:** Implement native ESC/POS thermal printing over Bluetooth/LAN.
- [x] **Offline Resilience:** Implement SQLite local caching for offline POS capabilities when the local server is unreachable (or ensure the local XAMPP server runs seamlessly on the same machine).
- [x] **UI Polish:** Complete the data-table implementations for historical records (Invoices, Customers, HR).

## 2. Local Micro-Services (PHP API)
- [x] **Controller Logic:** Flesh out the CRUD operations in `HrController`, `SalesController`, and `InventoryController`.
- [x] **POS Checkout Engine:** Implement the complex `bcmath` taxation and discount calculations within `SalesRepository->createOrder()`.
- [x] **Sync Outbox:** Ensure every single repository modification triggers a `SyncOutboxRepository::insert()` call to queue the change for the cloud.
- [x] **Local Web Admin:** Wire the newly created `dashboard.php` AdminLTE portal to read actual database metrics.

## 3. Cloud Super-Admin (PHP API)
- [x] **Ingestion Engine:** Implement `SyncController->push()` to accept and merge local tenant data into the master cloud database.
- [x] **Conflict Resolution:** Implement Last-Write-Wins (LWW) or version-based merging for sync conflicts.
- [x] **Global Dashboard:** Wire the `dashboard.php` Super-Admin portal to aggregate metrics across all `admin_id` tenants.
- [x] **License Manager:** Build the API to issue and revoke RSA-signed license keys for local nodes.

## 4. Infrastructure & CI/CD
- [x] **Windows Installer:** Package the XAMPP stack + Local API + Flutter Desktop app into a single MSIX installer using InnoSetup or MSIX packaging tools.
- [x] **Cron Jobs:** Configure the Windows Task Scheduler to run `sync_scheduler.php` every 5 minutes.
- [x] **Android APK:** Generate the signed release bundle for Google Play.
- [x] **Security:** Finalize JWT rotation and ensure complete multi-tenant (`admin_id`) isolation on the cloud server.

---
**Status:** Unified schemas (`schema.sql`) and seeds (`seed.sql`) are at the project root. All legacy archives have been purged. The codebase is clean and ready for final execution.


## --- FILE: README.md ---

﻿# API Documentation - LaundryPro UAE
> **Version:** 1.0.0

## Base URL
`http://localhost/api/v1/`

## Authentication
All endpoints (except login/refresh) require: `Authorization: Bearer {access_token}`

## Response Format
```json
{
  "success": true,
  "data": { ... },
  "meta": { "page": 1, "limit": 20, "total": 100 },
  "error": null
}
```

## Error Format
```json
{
  "success": false,
  "data": null,
  "meta": null,
  "error": {
    "code": "LP-ERR-AUTH-1001",
    "message": "Invalid credentials",
    "details": []
  }
}
```

## Common Headers
| Header | Required | Description |
|--------|----------|-------------|
| Authorization | Yes* | Bearer JWT access token |
| X-Idempotency-Key | Yes (writes) | UUID for write operations |
| Content-Type | Yes | application/json |
| Accept-Language | No | en or ar (default: en) |

## Endpoint Groups
| Group | Base Path | Description |
|-------|-----------|-------------|
| Auth | /auth | Login, refresh, logout |
| Orders | /orders | Order CRUD and status |
| Customers | /customers | Customer CRUD |
| Services | /services | Service catalog |
| Inventory | /inventory | Stock management |
| Invoices | /invoices | Invoice management |
| Payments | /payments | Payment processing |
| Employees | /employees | Employee management |
| Attendance | /attendance | Clock in/out |
| Payroll | /payroll | Payroll calculations |
| Reports | /reports | Report generation |
| Sync | /sync | Push/pull sync |
| Settings | /settings | System configuration |

## --- FILE: acronyms.md ---

﻿# Acronyms - LaundryPro UAE
> **Version:** 1.0.0

| Acronym | Expansion |
|---------|-----------|
| AED | UAE Dirham |
| API | Application Programming Interface |
| BA | Business Analyst |
| BPMN | Business Process Model and Notation |
| CDO | Chief Data Officer |
| CEO | Chief Executive Officer |
| CFO | Chief Financial Officer |
| CHRO | Chief Human Resources Officer |
| CISO | Chief Information Security Officer |
| COO | Chief Operating Officer |
| CPO | Chief Product Officer |
| CQO | Chief Quality Officer |
| CRO | Chief Revenue Officer |
| CTO | Chief Technology Officer |
| ER | Entity-Relationship |
| ERP | Enterprise Resource Planning |
| FK | Foreign Key |
| FTA | Federal Tax Authority |
| JWT | JSON Web Token |
| LTR | Left-to-Right |
| MSIX | Modern Windows App Package |
| MVVM | Model-View-ViewModel |
| PDPL | Personal Data Protection Law |
| PK | Primary Key |
| POS | Point of Sale |
| RBAC | Role-Based Access Control |
| REST | Representational State Transfer |
| RFID | Radio-Frequency Identification |
| RTL | Right-to-Left |
| SIF | Salary Information File |
| TRN | Tax Registration Number |
| UAT | User Acceptance Testing |
| UHF | Ultra High Frequency |
| UMAC | Unique Machine Authentication Code |
| UUID | Universally Unique Identifier |
| VAT | Value Added Tax |
| WPS | Wage Protection System |
| XAMPP | Cross-Platform Apache MariaDB PHP Perl |

## --- FILE: README.md ---

﻿# Appendices - LaundryPro UAE
> **Version:** 1.0.0

Glossary, acronyms, and supplementary reference.

## --- FILE: design_patterns.md ---

﻿# Design Patterns - LaundryPro UAE
> **Version:** 1.0.0

## Architectural Patterns
| Pattern | Where Used | Description |
|---------|-----------|-------------|
| MVVM | Flutter frontend | Model-View-ViewModel with Riverpod |
| Clean Architecture | PHP backend | Controller -> Service -> Repository layers |
| Repository Pattern | PHP + Flutter | Abstract data access behind interfaces |
| Adapter Pattern | Hardware layer | Generic interfaces for all hardware |
| Offline-First | System-wide | Local-first with sync outbox |
| Sync Outbox | Sync engine | Append-only queue for offline writes |

## Design Patterns
| Pattern | Where Used | Description |
|---------|-----------|-------------|
| Factory Pattern | DTOs, Models | fromJson/toJson data transformation |
| Observer Pattern | Riverpod | Reactive state management |
| Middleware Pattern | PHP API | Request pipeline (auth, RBAC, idempotency) |
| Strategy Pattern | Pricing | Different pricing strategies (per-item, per-kg) |
| Template Method | Reports | Common report structure with variable content |
| Singleton Pattern | Database | Single DB connection per request |

## Anti-Patterns Explicitly Forbidden
| Anti-Pattern | Why Forbidden | Guard |
|-------------|---------------|-------|
| Floating-point money | Precision loss | money_precision_guard bot |
| God Object | Maintainability | Clean Architecture enforcement |
| N+1 Queries | Performance | Performance agent review |
| Raw SQL in controllers | Testability | Repository Pattern enforcement |
| Client-only auth | Security | rbac_enforcer bot |

## --- FILE: README.md ---

﻿# Architecture - LaundryPro UAE
> **Version:** 1.0.0

## Documents
| Document | Description |
|----------|-------------|
| system_overview.md | High-level system architecture |
| technology_stack.md | Complete technology stack details |
| design_patterns.md | Architectural and design patterns used |
| data_flow.md | System data flow diagrams |
| deployment_architecture.md | Deployment topology and configuration |

## --- FILE: system_overview.md ---

﻿# System Architecture Overview - LaundryPro UAE
> **Version:** 1.0.0

## Architecture Layers

```
+------------------------------------------+
|        PRESENTATION LAYER                |
|  Flutter Windows Desktop (Dart)          |
|  MVVM + Riverpod + go_router             |
|  LTR/RTL + Offline-capable UI            |
+------------------------------------------+
           |                |
     [REST API]        [SQLite]
           |           (local cache)
+------------------------------------------+
|        APPLICATION LAYER                 |
|  PHP 8.2 REST API (Slim/Lumen)           |
|  Controllers -> Services -> Repositories |
|  JWT Auth + RBAC + Idempotency           |
+------------------------------------------+
           |
+------------------------------------------+
|        DATA LAYER                        |
|  MariaDB 10.4 (InnoDB)                  |
|  Multi-tenant (business_owner_id)        |
|  DECIMAL(18,2) for money                 |
+------------------------------------------+

+------------------------------------------+
|        SYNC LAYER                        |
|  Sync Outbox (append-only)               |
|  Push/Pull Protocols                     |
|  Conflict Resolution (LWW)              |
+------------------------------------------+

+------------------------------------------+
|        HARDWARE LAYER                    |
|  ESC/POS Printers | Barcode Scanners    |
|  Cash Drawers | RFID Readers | Scales   |
|  Auto-Discovery + Adapter Pattern        |
+------------------------------------------+

+------------------------------------------+
|        SECURITY LAYER                    |
|  UMAC Licensing | RBAC Scopes           |
|  Audit Trail (hash-chained)             |
|  AES-256 Encryption | SHA-256 Backup    |
+------------------------------------------+
```

## Key Architectural Decisions
1. **Offline-First**: Local XAMPP server is primary; cloud sync is secondary.
2. **Multi-Tenant**: business_owner_id on all data tables; strict isolation.
3. **Zero-Float Money**: DECIMAL(18,2) everywhere; bcmath in PHP.
4. **Clean Architecture**: Presentation -> Domain -> Data layer separation.
5. **Adapter Pattern**: All hardware behind generic interfaces.

## --- FILE: technology_stack.md ---

﻿# Technology Stack - LaundryPro UAE
> **Version:** 1.0.0

## Frontend
| Technology | Version | Purpose |
|-----------|---------|---------|
| Flutter | >= 3.3 | Windows desktop UI framework |
| Dart | >= 3.0 | Programming language |
| Riverpod | latest | State management |
| go_router | latest | Navigation and routing |
| sqflite/drift | latest | Local SQLite database |
| intl | latest | Internationalization |

## Backend
| Technology | Version | Purpose |
|-----------|---------|---------|
| PHP | 8.2 | Server-side language |
| Slim/Lumen | 4.x | Micro-framework for REST API |
| PDO | built-in | Database access (prepared statements) |
| bcmath | built-in | Decimal arithmetic |
| Firebase JWT | latest | JWT token handling |

## Database
| Technology | Version | Purpose |
|-----------|---------|---------|
| MariaDB | 10.4 | Primary relational database |
| SQLite | 3.x | Local client-side cache |

## Server
| Technology | Version | Purpose |
|-----------|---------|---------|
| XAMPP | latest | Apache + MariaDB + PHP bundle |
| Apache | 2.4 | HTTP server |

## Packaging
| Technology | Version | Purpose |
|-----------|---------|---------|
| MSIX | latest | Windows installer format |

## Hardware Protocols
| Protocol | Purpose |
|----------|---------|
| ESC/POS | Thermal printer communication |
| ESC/P | Dot-matrix printer communication |
| Windows Spooler | Inkjet/laser PDF printing |
| USB HID | Barcode scanner input |
| RS-232 Serial | Cash drawer, scale, scanner |
| RFID UHF | Garment/linen tracking |

## --- FILE: auth_blueprint.md ---

﻿# Blueprint: auth Module - LaundryPro UAE
> **Version:** 1.0.0

## Overview
Authentication & Authorization module. JWT-based login with access/refresh tokens. RBAC with 6 roles and scope-based permissions. UMAC machine-bound licensing. Session management with forced logout. Password hashing with bcrypt. Account locking after 5 failed attempts.

## Key Business Rules
- All monetary values use DECIMAL(18,2).
- All operations scoped to business_owner_id.
- All state changes logged to audit_logs.
- All screens support LTR (English) and RTL (Arabic).
- All operations available in offline mode.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial blueprint |

## --- FILE: customers_blueprint.md ---

﻿# Blueprint: customers Module - LaundryPro UAE
> **Version:** 1.0.0

## Overview
Customer Management module. Customer profile (name, phone, email, address, TRN for corporate). Order history and spending analysis. Corporate account management with monthly billing. Customer preferences (starch level, fold style, packaging). Loyalty/credit balance. Customer notes and communication log.

## Key Business Rules
- All monetary values use DECIMAL(18,2).
- All operations scoped to business_owner_id.
- All state changes logged to audit_logs.
- All screens support LTR (English) and RTL (Arabic).
- All operations available in offline mode.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial blueprint |

## --- FILE: delivery_blueprint.md ---

﻿# Blueprint: delivery Module - LaundryPro UAE
> **Version:** 1.0.0

## Overview
Delivery Management module. Route planning with customer addresses. Driver assignment and reassignment. Delivery status tracking (assigned, en-route, delivered, failed). Delivery confirmation (signature capture or photo). Customer notification on delivery. Route optimization suggestions. Return pickup support.

## Key Business Rules
- All monetary values use DECIMAL(18,2).
- All operations scoped to business_owner_id.
- All state changes logged to audit_logs.
- All screens support LTR (English) and RTL (Arabic).
- All operations available in offline mode.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial blueprint |

## --- FILE: finance_blueprint.md ---

﻿# Blueprint: finance Module - LaundryPro UAE
> **Version:** 1.0.0

## Overview
Finance and Invoicing module. Invoice generation with TRN and VAT (5%). Immutable posted invoices (correction memo only). Sequential invoice numbering (INV-YYYY-NNNNNN). Payment tracking (cash, card, bank transfer). Daily cash register reconciliation. Expense tracking. Financial reports (P&L, cash flow, aging, VAT return).

## Key Business Rules
- All monetary values use DECIMAL(18,2).
- All operations scoped to business_owner_id.
- All state changes logged to audit_logs.
- All screens support LTR (English) and RTL (Arabic).
- All operations available in offline mode.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial blueprint |

## --- FILE: hr_payroll_blueprint.md ---

﻿# Blueprint: hr_payroll Module - LaundryPro UAE
> **Version:** 1.0.0

## Overview
HR and Payroll module. Employee master records (personal info, employment details, salary). Attendance tracking (check-in/check-out, late, absent, overtime). Leave management (annual 30 days, sick, unpaid). Payroll calculation with UAE overtime rules (1.25x, 1.5x, 2x). SIF file export for WPS compliance. End-of-service gratuity calculation.

## Key Business Rules
- All monetary values use DECIMAL(18,2).
- All operations scoped to business_owner_id.
- All state changes logged to audit_logs.
- All screens support LTR (English) and RTL (Arabic).
- All operations available in offline mode.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial blueprint |

## --- FILE: inventory_blueprint.md ---

﻿# Blueprint: inventory Module - LaundryPro UAE
> **Version:** 1.0.0

## Overview
Inventory Management module. Supply tracking (detergent, hangers, bags, starch, packaging). Stock-in transactions with supplier and invoice reference. Stock-out transactions linked to production consumption. Minimum threshold alerts. Garment inventory by status and location. Inventory valuation reports.

## Key Business Rules
- All monetary values use DECIMAL(18,2).
- All operations scoped to business_owner_id.
- All state changes logged to audit_logs.
- All screens support LTR (English) and RTL (Arabic).
- All operations available in offline mode.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial blueprint |

## --- FILE: orders_blueprint.md ---

﻿# Blueprint: orders Module - LaundryPro UAE
> **Version:** 1.0.0

## Overview
Order Management module. Walk-in, pickup, and corporate order intake. Sequential numbering (ORD-YYYY-NNNNNN). Barcode/RFID garment tagging. Status tracking (received, sorting, processing, quality-check, ready, out-for-delivery, delivered). Express/same-day/next-day/standard turnaround. Per-item, per-kg, per-piece pricing. Line-item and order-level discounts. Special instructions and notes.

## Key Business Rules
- All monetary values use DECIMAL(18,2).
- All operations scoped to business_owner_id.
- All state changes logged to audit_logs.
- All screens support LTR (English) and RTL (Arabic).
- All operations available in offline mode.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial blueprint |

## --- FILE: pos_blueprint.md ---

﻿# Blueprint: pos Module - LaundryPro UAE
> **Version:** 1.0.0

## Overview
Point of Sale module. Service catalog display with search. Barcode scanner integration for quick item add. Subtotal, discount, VAT (5%), total calculation. Cash, card, split payment methods. Thermal receipt printing (57mm/80mm). Cash drawer auto-open on cash payment. Quick customer lookup. Express checkout flow optimized for < 30 seconds.

## Key Business Rules
- All monetary values use DECIMAL(18,2).
- All operations scoped to business_owner_id.
- All state changes logged to audit_logs.
- All screens support LTR (English) and RTL (Arabic).
- All operations available in offline mode.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial blueprint |

## --- FILE: production_blueprint.md ---

﻿# Blueprint: production Module - LaundryPro UAE
> **Version:** 1.0.0

## Overview
Production Management module. Garment processing stages (sorting, washing, drying, ironing, folding, packaging). Operator assignment per stage. Quality check pass/fail with defect codes. Rewash/reclean workflow. Production performance tracking by operator. Batch processing support.

## Key Business Rules
- All monetary values use DECIMAL(18,2).
- All operations scoped to business_owner_id.
- All state changes logged to audit_logs.
- All screens support LTR (English) and RTL (Arabic).
- All operations available in offline mode.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial blueprint |

## --- FILE: README.md ---

﻿# Module Blueprints - LaundryPro UAE
> **Version:** 1.0.0

## Overview
Each blueprint provides a complete feature specification for a module including purpose, user stories, data model, API endpoints, UI screens, and business rules.

## Module Index
| Module | Blueprint | Status |
|--------|-----------|--------|
| Authentication | auth_blueprint.md | Complete |
| Orders | orders_blueprint.md | Complete |
| POS | pos_blueprint.md | Complete |
| Inventory | inventory_blueprint.md | Complete |
| Production | production_blueprint.md | Complete |
| Delivery | delivery_blueprint.md | Complete |
| Customers | customers_blueprint.md | Complete |
| HR & Payroll | hr_payroll_blueprint.md | Complete |
| Finance | finance_blueprint.md | Complete |
| Reports | reports_blueprint.md | Complete |

## --- FILE: reports_blueprint.md ---

﻿# Blueprint: reports Module - LaundryPro UAE
> **Version:** 1.0.0

## Overview
Reports and Analytics module. Dashboard KPIs (daily revenue, orders, production throughput). Sales reports (by period, branch, service, employee). Production reports (by operator, service type, turnaround). Financial reports (P&L, cash flow, accounts receivable aging). HR reports (attendance, payroll, leave balances). Export to PDF and CSV.

## Key Business Rules
- All monetary values use DECIMAL(18,2).
- All operations scoped to business_owner_id.
- All state changes logged to audit_logs.
- All screens support LTR (English) and RTL (Arabic).
- All operations available in offline mode.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial blueprint |

## --- FILE: README.md ---

﻿# Compliance Documentation - LaundryPro UAE
> **Version:** 1.0.0

UAE regulatory compliance documentation.

## --- FILE: uae_vat_compliance.md ---

﻿# UAE VAT Compliance - LaundryPro UAE
> **Version:** 1.0.0

## VAT Rules
- Standard rate: 5% on all taxable services.
- Calculation: VAT = (Subtotal - Line Discounts) * 0.05.
- Rounding: ROUND_HALF_UP to 2 decimal places.
- TRN: Displayed on all invoices.
- Invoice requirements: Sequential numbering, date, TRN, line items, VAT amount, total.
- Returns: Quarterly VAT return filing.

## --- FILE: backup_strategy.md ---

﻿# Backup Strategy - LaundryPro UAE
> **Version:** 1.0.0

## Backup Types
| Type | Frequency | Retention |
|------|-----------|-----------|
| Full | Daily 02:00 AM | 30 days |
| Incremental | Every 4 hours | 7 days |
| Pre-migration | Before schema changes | Permanent |
| Manual | On-demand | 90 days |

## Backup Verification
- SHA-256 hash generated for every backup file.
- Hash stored alongside backup file.
- Automated verification on backup completion.
- Monthly restore test on isolated environment.

## Storage
- Local: XAMPP backup directory.
- External: USB/network drive (recommended).
- Cloud: Sync to cloud when connectivity available (optional).

## Restore SLA
- Full restore: < 30 minutes for databases up to 10 GB.
- Point-in-time restore: Via incremental backups within 4-hour window.

## --- FILE: data_dictionary.md ---

﻿# Data Dictionary - LaundryPro UAE
> **Version:** 1.0.0

## Naming Conventions
- Tables: snake_case, plural (e.g., orders, order_items)
- Columns: snake_case (e.g., business_owner_id, created_at)
- PKs: id (BIGINT UNSIGNED AUTO_INCREMENT)
- FKs: {referenced_table_singular}_id (e.g., order_id, customer_id)
- Booleans: is_{adjective} (e.g., is_active, is_paid)
- Timestamps: {action}_at (e.g., created_at, deleted_at)
- Money: DECIMAL(18,2) with descriptive name (e.g., unit_price, total_amount)

## Core Tables
| Table | Description | Tenant-Scoped |
|-------|-------------|:---:|
| business_owners | Tenant registration and profile | No (is tenant) |
| branches | Branch locations per tenant | Yes |
| users | System users (employees) | Yes |
| roles | RBAC role definitions | No (global) |
| permissions | RBAC permission definitions | No (global) |
| role_permissions | Role-permission mapping | No (global) |
| customers | Customer profiles | Yes |
| services | Service catalog (wash, dry-clean, etc.) | Yes |
| price_lists | Pricing tiers and schedules | Yes |
| orders | Order headers | Yes |
| order_items | Order line items | Yes |
| order_status_history | Order status transitions | Yes |
| invoices | Invoice headers | Yes |
| invoice_items | Invoice line items | Yes |
| payments | Payment transactions | Yes |
| inventory_items | Supply inventory | Yes |
| inventory_transactions | Stock in/out records | Yes |
| employees | Employee master records | Yes |
| attendance | Check-in/check-out records | Yes |
| payroll | Payroll calculation records | Yes |
| deliveries | Delivery assignments | Yes |
| delivery_items | Items in a delivery | Yes |
| garment_tags | Barcode/RFID tag assignments | Yes |
| production_stages | Garment processing stages | Yes |
| audit_logs | All state change audit entries | Yes |
| sync_outbox | Offline sync queue | Yes |
| machine_licenses | UMAC license bindings | No (system) |
| system_settings | Global system configuration | No (system) |
| migrations | Schema migration tracking | No (system) |

## Standard Columns (all tenant-scoped tables)
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED AUTO_INCREMENT | Primary key |
| business_owner_id | BIGINT UNSIGNED FK | Tenant isolation |
| created_at | DATETIME DEFAULT CURRENT_TIMESTAMP | Creation timestamp |
| updated_at | DATETIME ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |
| created_by | BIGINT UNSIGNED FK (users) | Creator user |
| updated_by | BIGINT UNSIGNED FK (users) | Last updater user |
| is_active | TINYINT(1) DEFAULT 1 | Soft delete flag |
| deleted_at | DATETIME NULL | Soft delete timestamp |

## --- FILE: er_diagram.md ---

﻿# ER Diagram - LaundryPro UAE
> **Version:** 1.0.0

## Core Entity Relationships

```mermaid
erDiagram
    business_owners ||--o{ branches : has
    business_owners ||--o{ users : employs
    business_owners ||--o{ customers : serves
    business_owners ||--o{ services : offers
    business_owners ||--o{ orders : receives

    branches ||--o{ users : staffs
    branches ||--o{ orders : processes

    customers ||--o{ orders : places
    orders ||--o{ order_items : contains
    orders ||--|| invoices : generates
    orders ||--o{ order_status_history : tracks
    orders ||--o{ deliveries : schedules

    services ||--o{ order_items : "priced as"
    order_items ||--o{ garment_tags : tagged

    invoices ||--o{ invoice_items : contains
    invoices ||--o{ payments : receives

    users ||--o{ attendance : logs
    users ||--o{ payroll : "paid via"
    users }o--|| roles : "assigned"

    roles ||--o{ role_permissions : grants
    role_permissions }o--|| permissions : references

    deliveries ||--o{ delivery_items : contains
    deliveries }o--|| users : "assigned to (driver)"

    production_stages }o--|| order_items : processes
    production_stages }o--|| users : "performed by"

    inventory_items ||--o{ inventory_transactions : tracks
```

## --- FILE: migration_strategy.md ---

﻿# Migration Strategy - LaundryPro UAE
> **Version:** 1.0.0

## Principles
1. All migrations are sequential (001, 002, 003...).
2. All migrations are idempotent (IF NOT EXISTS / IF EXISTS).
3. All migrations have a corresponding rollback script.
4. Pre-migration backup is mandatory.
5. Migrations are tested on a copy of production data first.

## Migration File Naming
`{NNN}_{description}.sql`
Example: `001_baseline.sql`, `002_add_rfid_columns.sql`

## Migration Procedure
1. Create migration file in `api/database/migrations/`.
2. Create rollback file in `api/database/migrations/rollback/`.
3. Test migration on development database.
4. Take pre-migration backup (backup.protocol).
5. Execute migration on production.
6. Verify migration success (row counts, schema check).
7. Log migration in `migrations` tracking table.

## Current Migrations
| Number | Description | Date |
|--------|------------|------|
| 001 | Baseline schema (50+ tables) | 2026-09-20 |

## --- FILE: README.md ---

﻿# Data Documentation - LaundryPro UAE
> **Version:** 1.0.0

## Documents
| Document | Description |
|----------|-------------|
| data_dictionary.md | Complete data dictionary for all tables |
| er_diagram.md | Entity-Relationship diagram (Mermaid) |
| migration_strategy.md | Database migration approach and procedures |
| backup_strategy.md | Backup and recovery procedures |

## --- FILE: flutter_dependencies.md ---

﻿# Flutter Dependencies - LaundryPro UAE
> **Version:** 1.0.0

## Core Dependencies (pubspec.yaml)
| Package | Version | Purpose | License |
|---------|---------|---------|---------|
| flutter_riverpod | latest | State management | MIT |
| go_router | latest | Navigation | BSD-3 |
| sqflite | latest | SQLite local DB | MIT |
| drift | latest | SQLite ORM | MIT |
| dio | latest | HTTP client | MIT |
| intl | latest | Internationalization | BSD-3 |
| freezed | latest | Immutable data classes | MIT |
| json_serializable | latest | JSON serialization | BSD-3 |
| equatable | latest | Value equality | MIT |
| window_manager | latest | Window control | MIT |
| printing | latest | Print support | Apache-2.0 |
| pdf | latest | PDF generation | Apache-2.0 |
| flutter_barcode_scanner | latest | Barcode scanning | MIT |

## --- FILE: php_dependencies.md ---

﻿# PHP Dependencies - LaundryPro UAE
> **Version:** 1.0.0

## Core Dependencies (composer.json)
| Package | Version | Purpose | License |
|---------|---------|---------|---------|
| slim/slim | ^4.0 | Micro-framework | MIT |
| firebase/php-jwt | ^6.0 | JWT handling | Apache-2.0 |
| vlucas/phpdotenv | ^5.0 | Environment variables | BSD-3 |
| monolog/monolog | ^3.0 | Logging | MIT |
| ramsey/uuid | ^4.0 | UUID generation | MIT |

## --- FILE: README.md ---

﻿# Dependencies - LaundryPro UAE
> **Version:** 1.0.0

Third-party dependency documentation and management.

## --- FILE: hardware_edge_cases.md ---

﻿# Edge Cases: hardware - LaundryPro UAE
> **Version:** 1.0.0

## Scenarios
Printer disconnected mid-print, scanner sends invalid barcode, cash drawer already open, RFID reader reads multiple tags simultaneously, printer paper out mid-receipt, USB device hot-plug/unplug during operation.

## Testing Strategy
- Each scenario has a corresponding test case in the edge case test suite.
- Edge Case Hunter agent is responsible for discovering new edge cases.
- All edge cases are validated during regression testing.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial edge case catalog |

## --- FILE: locale_edge_cases.md ---

﻿# Edge Cases: locale - LaundryPro UAE
> **Version:** 1.0.0

## Scenarios
Switch locale mid-transaction (EN to AR), Arabic text in English fields, mixed LTR/RTL in same string (e.g., Arabic name with English product code), right-to-left numbers in invoice, very long Arabic text overflow.

## Testing Strategy
- Each scenario has a corresponding test case in the edge case test suite.
- Edge Case Hunter agent is responsible for discovering new edge cases.
- All edge cases are validated during regression testing.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial edge case catalog |

## --- FILE: monetary_edge_cases.md ---

﻿# Edge Cases: monetary - LaundryPro UAE
> **Version:** 1.0.0

## Scenarios
Zero amount orders, maximum DECIMAL(18,2) value (9999999999999999.99), negative discount validation, VAT rounding (round half-up to 2 decimal places), split payment that doesn't sum to total, currency conversion edge at AED boundaries.

## Testing Strategy
- Each scenario has a corresponding test case in the edge case test suite.
- Edge Case Hunter agent is responsible for discovering new edge cases.
- All edge cases are validated during regression testing.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial edge case catalog |

## --- FILE: offline_edge_cases.md ---

﻿# Edge Cases: offline - LaundryPro UAE
> **Version:** 1.0.0

## Scenarios
30+ days offline operation, sync outbox with 10,000+ entries, conflict resolution when both local and cloud modified same record, internet drops mid-sync, sync resumes after partial push, dead-letter queue processing.

## Testing Strategy
- Each scenario has a corresponding test case in the edge case test suite.
- Edge Case Hunter agent is responsible for discovering new edge cases.
- All edge cases are validated during regression testing.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial edge case catalog |

## --- FILE: README.md ---

﻿# Edge Cases - LaundryPro UAE
> **Version:** 1.0.0

Catalog of boundary conditions, edge cases, and special scenarios.

## --- FILE: tenant_edge_cases.md ---

﻿# Edge Cases: tenant - LaundryPro UAE
> **Version:** 1.0.0

## Scenarios
User attempts cross-tenant data access, tenant with zero branches, tenant with maximum branches (50), tenant license expiration mid-transaction, tenant data during UMAC read-only mode.

## Testing Strategy
- Each scenario has a corresponding test case in the edge case test suite.
- Edge Case Hunter agent is responsible for discovering new edge cases.
- All edge cases are validated during regression testing.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial edge case catalog |

## --- FILE: README.md ---

﻿# Data & Process Flows - LaundryPro UAE
> **Version:** 1.0.0

Data flow diagrams and process flow documentation.

## --- FILE: sync_data_flow.md ---

﻿# Sync Data Flow - LaundryPro UAE
> **Version:** 1.0.0

## Push Flow (Local -> Cloud)
```
Local Write -> sync_outbox INSERT -> Connectivity Check ->
IF online: POST /api/v1/sync/push (batch) ->
  Cloud validates idempotency_key ->
  Cloud applies changes ->
  Cloud returns success/conflict ->
  Local marks entries as synced ->
IF offline: Entries remain in outbox (FIFO queue)
```

## Pull Flow (Cloud -> Local)
```
Connectivity Check ->
IF online: GET /api/v1/sync/pull?since={last_sequence} ->
  Cloud returns new entries since checkpoint ->
  Local applies changes (LWW conflict resolution) ->
  Local updates last_sequence checkpoint ->
IF offline: No pull (local state is authoritative)
```

## --- FILE: customer_form.md ---

﻿# Form: customer form - LaundryPro UAE
> **Version:** 1.0.0

## Specification
Customer form: name (required, varchar 100), phone (required, varchar 20, UAE format +971XXXXXXXXX), email (optional, valid email format), address (optional, text), type (required, enum: individual/corporate), trn (required if corporate, 15-digit TRN format).

## Validation Rules
- All required fields validated before submission.
- Inline error messages displayed below field.
- Server-side validation mirrors client-side rules.
- All monetary fields: DECIMAL(18,2), validated > 0.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial form specification |

## --- FILE: employee_form.md ---

﻿# Form: employee form - LaundryPro UAE
> **Version:** 1.0.0

## Specification
Employee form: name (required, varchar 100), phone (required, varchar 20), email (optional), role_id (required, FK), branch_id (required, FK), hire_date (required, date), salary (required, DECIMAL(18,2) > 0), passport_number (required, varchar 20), emirates_id (required, varchar 18).

## Validation Rules
- All required fields validated before submission.
- Inline error messages displayed below field.
- Server-side validation mirrors client-side rules.
- All monetary fields: DECIMAL(18,2), validated > 0.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial form specification |

## --- FILE: invoice_form.md ---

﻿# Form: invoice form - LaundryPro UAE
> **Version:** 1.0.0

## Specification
Invoice form: order_id (required, FK), customer_id (required, FK), subtotal (auto-calculated, DECIMAL), discount_amount (auto-calculated, DECIMAL), vat_amount (auto-calculated, 5% of subtotal-discount), total_amount (auto-calculated, DECIMAL), payment_method (required, enum: cash/card/split), trn_display (auto-filled from business profile).

## Validation Rules
- All required fields validated before submission.
- Inline error messages displayed below field.
- Server-side validation mirrors client-side rules.
- All monetary fields: DECIMAL(18,2), validated > 0.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial form specification |

## --- FILE: order_form.md ---

﻿# Form: order form - LaundryPro UAE
> **Version:** 1.0.0

## Specification
Order form: customer_id (required, FK), branch_id (required, FK), service_type (required, enum), turnaround (required, enum: express/same-day/next-day/standard), notes (optional, text, max 500 chars). Items: service_id (required, FK), quantity (required, int > 0), unit_price (auto-filled, DECIMAL), discount (optional, DECIMAL 0-100%).

## Validation Rules
- All required fields validated before submission.
- Inline error messages displayed below field.
- Server-side validation mirrors client-side rules.
- All monetary fields: DECIMAL(18,2), validated > 0.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial form specification |

## --- FILE: payment_form.md ---

﻿# Form: payment form - LaundryPro UAE
> **Version:** 1.0.0

## Specification
Payment form: invoice_id (required, FK), amount (required, DECIMAL > 0), method (required, enum: cash/card/bank_transfer), reference_number (required if card/bank, varchar 50), notes (optional, text).

## Validation Rules
- All required fields validated before submission.
- Inline error messages displayed below field.
- Server-side validation mirrors client-side rules.
- All monetary fields: DECIMAL(18,2), validated > 0.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial form specification |

## --- FILE: README.md ---

﻿# Forms & Validation - LaundryPro UAE
> **Version:** 1.0.0

Form specifications with field types, validation rules, and error messages for all input screens.

## --- FILE: printer_integration.md ---

﻿# Printer Integration - LaundryPro UAE
> **Version:** 1.0.0

## Supported Printer Types
| Type | Protocol | Paper Sizes | Brands |
|------|----------|-------------|--------|
| Thermal | ESC/POS | 57mm, 80mm | Epson, Star, Bixolon, Citizen, Xprinter |
| Dot-Matrix | ESC/P | 112mm | Epson |
| Inkjet/Laser | Windows Spooler | A6, A5, A4 | Any Windows-compatible |

## Auto-Discovery Methods
1. WMI query for USB printers
2. Bluetooth device scan
3. TCP port scan for network printers
4. mDNS/Bonjour discovery
5. COM port enumeration for serial

## Adapter Interface
All printers implement `IPrinterAdapter`:
- `connect()`, `disconnect()`
- `print(template, data)`
- `getStatus()`
- `openCashDrawer()`

## --- FILE: README.md ---

﻿# Integration Documentation - LaundryPro UAE
> **Version:** 1.0.0

Hardware and third-party integration documentation.

## --- FILE: scanner_integration.md ---

﻿# Scanner Integration - LaundryPro UAE
> **Version:** 1.0.0

## Supported Scanner Types
| Type | Interface | Mode |
|------|-----------|------|
| Handheld USB | USB HID | Keyboard wedge |
| Bluetooth | SPP | Serial stream |
| Fixed mount | RS-232 | Serial stream |

## Barcode Formats
- Code 128 (primary for garment tags)
- QR Code (customer-facing)
- EAN-13 (product lookup)

## Integration Approach
USB HID scanners inject keystrokes. The application listens for rapid keystroke sequences ending with Enter/CR to detect scan input vs. manual typing.

## --- FILE: README.md ---

﻿# Licensing Documentation - LaundryPro UAE
> **Version:** 1.0.0

UMAC licensing and anti-piracy documentation.

## --- FILE: umac_specification.md ---

﻿# UMAC Licensing Specification - LaundryPro UAE
> **Version:** 1.0.0

## Overview
UMAC (Unique Machine Authentication Code) binds each license to a specific machine.

## Machine Hash Components
- CPU ID (CPUID instruction)
- Disk serial number (primary drive)
- MAC address (primary network adapter)
- Combined via SHA-256: `UMAC = SHA256(CPUID + DISK_SERIAL + MAC_ADDRESS)`

## License Tiers
| Tier | Duration | Features |
|------|----------|----------|
| Trial | 30 days | Full features, watermark |
| Standard | 1 year | Core modules |
| Premium | 1 year | All modules + priority support |
| Enterprise | 1 year | Multi-branch + API access |

## Validation Flow
1. On launch: compute UMAC from hardware.
2. Compare against stored license hash.
3. If match: activate.
4. If mismatch: enter read-only mode.
5. Grace period: 30 days offline before read-only enforcement.

## --- FILE: product_overview.md ---

﻿# Product Overview - LaundryPro UAE
> **Version:** 1.0.0

## Tagline
The Complete Offline-First Laundry Management Solution for UAE Businesses.

## Key Selling Points
1. Works without internet (offline-first architecture).
2. Complete ERP/CRM/POS in one application.
3. UAE regulatory compliant (VAT, FTA, WPS).
4. Bilingual (English + Arabic) with full RTL support.
5. Supports all common laundry hardware.
6. Multi-branch management from one system.
7. Enterprise-grade security (UMAC licensing).
8. Built for the UAE laundry industry.

## --- FILE: README.md ---

﻿# Marketing Documentation - LaundryPro UAE
> **Version:** 1.0.0

Product marketing materials and sales documentation.

## --- FILE: isolation_model.md ---

﻿# Tenant Isolation Model - LaundryPro UAE
> **Version:** 1.0.0

## Approach: Shared Database, Shared Schema, Row-Level Isolation

## Isolation Column
`business_owner_id` (BIGINT UNSIGNED FK) on all data tables.

## Enforcement Points
1. **Database**: All SELECT queries include WHERE business_owner_id = ?.
2. **API Middleware**: Extracts business_owner_id from JWT; injects into all queries.
3. **Sync Engine**: Outbox entries scoped to business_owner_id.
4. **Reports**: All reports filtered by business_owner_id.
5. **Bot**: tenant_isolation_checker validates at code review.

## Exempt Tables (system-scoped)
- migrations, system_settings, roles, permissions, role_permissions, machine_licenses

## --- FILE: README.md ---

﻿# Multi-Tenancy Documentation - LaundryPro UAE
> **Version:** 1.0.0

Multi-tenant architecture and isolation documentation.

## --- FILE: audit_maintenance.md ---

﻿# Audit & Maintenance Guide â€” LaundryPro UAE
> **Version:** 1.0.0 | **Last Updated:** 2026-09-21

## Daily Maintenance Checklist
- [ ] Verify XAMPP services running (Apache + MariaDB)
- [ ] Check disk space (minimum 1 GB free)
- [ ] Verify daily backup completed successfully
- [ ] Check sync outbox for dead-letter entries
- [ ] Review error.log for new errors

## Weekly Maintenance Checklist
- [ ] Run database ANALYZE TABLE on all tables
- [ ] Review slow query log
- [ ] Check backup SHA-256 integrity
- [ ] Review audit_logs for anomalies
- [ ] Verify license validity (days remaining)

## Monthly Maintenance Checklist
- [ ] Test backup restore on isolated environment
- [ ] Review and rotate PHP error logs
- [ ] Update dependency lock files (pubspec.lock, composer.lock)
- [ ] Run full security scan (RBAC audit, SQL injection test)
- [ ] Review memory usage trends

## Audit Trail Integrity Verification
```sql
-- Verify hash chain integrity
SELECT a1.id, a1.hash, a2.hash as prev_hash
FROM audit_logs a1
LEFT JOIN audit_logs a2 ON a2.id = a1.id - 1
WHERE a1.id > 1
AND a1.prev_hash != a2.hash
LIMIT 10;
-- If any rows returned, hash chain is broken (investigate tampering)
```

## Database Health Queries
```sql
-- Table sizes
SELECT table_name, ROUND(data_length/1024/1024, 2) AS size_mb, table_rows
FROM information_schema.tables WHERE table_schema = 'laundrypro'
ORDER BY data_length DESC;

-- Index usage
SELECT table_name, index_name, seq_in_index, column_name
FROM information_schema.statistics WHERE table_schema = 'laundrypro'
ORDER BY table_name, index_name, seq_in_index;

-- Fragmentation check
SELECT table_name, ROUND(data_free/1024/1024, 2) AS fragmented_mb
FROM information_schema.tables WHERE table_schema = 'laundrypro' AND data_free > 0;
```

## Log Rotation Policy
| Log | Location | Rotation | Retention |
|-----|----------|----------|-----------|
| PHP error log | C:\xampp\php\logs\ | Weekly | 30 days |
| Apache access log | C:\xampp\apache\logs\ | Daily | 90 days |
| Apache error log | C:\xampp\apache\logs\ | Daily | 90 days |
| Agent decision log | .ai/logs/decisions.log.md | Monthly archive | Permanent |
| Audit trail | audit_logs table | None (append-only) | Permanent |

## --- FILE: deployment_guide.md ---

﻿# Deployment Guide - LaundryPro UAE
> **Version:** 1.0.0

## Prerequisites
- Windows 10/11 (64-bit)
- 4 GB RAM minimum (8 GB recommended)
- 10 GB free disk space
- XAMPP installed with Apache, MariaDB, PHP 8.2

## Installation Steps
1. Install XAMPP and verify services start.
2. Run database baseline migration (001_baseline.sql).
3. Install MSIX package (double-click or sideload).
4. Launch LaundryPro UAE.
5. Complete first-time setup wizard.
6. Configure hardware (auto-discovery).
7. Verify with test transaction.

## Update Procedure
1. Backup database (backup.protocol).
2. Install new MSIX package (auto-updates or manual).
3. Run pending migrations (if any).
4. Verify functionality.
5. Rollback if critical issues found.

## --- FILE: monitoring_checklist.md ---

﻿# System Monitoring Checklist â€” LaundryPro UAE
> **Version:** 1.0.0 | **Last Updated:** 2026-09-21

## Real-Time Monitors
| What | How | Alert Threshold |
|------|-----|-----------------|
| Apache status | `sc query Apache2.4` | Service not running |
| MariaDB status | `sc query mysql` | Service not running |
| Disk space | `Get-PSDrive C` | < 1 GB free |
| Database connections | `SHOW STATUS LIKE 'Threads_connected'` | > 80 |
| Sync outbox pending | `SELECT COUNT(*) FROM sync_outbox WHERE status='pending'` | > 1000 |
| Dead-letter entries | `SELECT COUNT(*) FROM sync_outbox WHERE status='dead'` | > 0 |
| API error rate | PHP error log analysis | > 10 errors/hour |
| Backup age | Last backup timestamp | > 26 hours |

## Health Check Script
```powershell
# LaundryPro Health Check
Write-Host "=== LaundryPro UAE Health Check ==="
Write-Host "Date: 09/21/2026 01:47:25"

# Services
Write-Host "
Services:"
@("Apache2.4","mysql") | ForEach-Object {
    $svc = Get-Service $_ -ErrorAction SilentlyContinue
    Write-Host "  $_: $(if ($svc.Status -eq 'Running') {'OK'} else {'DOWN!'})"
}

# Disk
Write-Host "
Disk:"
$drive = Get-PSDrive C
Write-Host "  Free: $([math]::Round($drive.Free/1GB, 2)) GB"

# Database
Write-Host "
Database:"
$result = & "C:\xampp\mysql\bin\mysql.exe" -u root -e "SELECT 'OK' AS status" 2>$null
Write-Host "  Connection: $(if ($result -match 'OK') {'OK'} else {'FAILED!'})"

Write-Host "
=== Health Check Complete ==="
```

## --- FILE: README.md ---

﻿# Operations Documentation - LaundryPro UAE
> **Version:** 1.0.0

Deployment, backup, monitoring, and operational procedures.

## --- FILE: runtime_troubleshooting.md ---

﻿# Runtime Troubleshooting Guide â€” LaundryPro UAE
> **Version:** 1.0.0 | **Last Updated:** 2026-09-21
> **Owner:** LP-AGENT-OPS-LEAD

---

## Quick Diagnosis Flowchart

```
Issue Reported
    |
    +-- Application won't start?      --> Section 1
    +-- XAMPP service won't start?     --> Section 2
    +-- Database connection failed?    --> Section 3
    +-- API returning errors?          --> Section 4
    +-- Print job fails?               --> Section 5
    +-- Scanner not working?           --> Section 6
    +-- Sync not working?              --> Section 7
    +-- License error?                 --> Section 8
    +-- Performance degradation?       --> Section 9
    +-- Data inconsistency?            --> Section 10
    +-- UI rendering issues?           --> Section 11
    +-- Backup/Restore issues?         --> Section 12
```

---

## Section 1: Application Won't Start

### Symptoms
- MSIX app crashes on launch
- White screen on startup
- Error dialog on launch

### Diagnosis
1. Check Windows Event Viewer (Application log) for crash details.
2. Verify MSIX package integrity: `Get-AppxPackage *LaundryPro*`
3. Check if XAMPP services are running.
4. Check license validity (UMAC hash match).

### Resolution
| Cause | Fix |
|-------|-----|
| Corrupt MSIX | Reinstall MSIX package |
| XAMPP not running | Start Apache and MariaDB services |
| License expired | Renew license or enter grace period |
| Missing .env file | Restore from backup or recreate |
| Database unreachable | Check MariaDB port 3306 |

### Recovery
```powershell
# Verify XAMPP services
net start Apache2.4
net start mysql
# Verify database connection
mysql -u root -p -e "SELECT 1"
```

---

## Section 2: XAMPP Service Won't Start

### Apache Won't Start
| Cause | Fix |
|-------|-----|
| Port 80 occupied | `netstat -ano | findstr :80` then kill conflicting process or change Apache port |
| Port 443 occupied | Same as above for HTTPS port |
| Corrupt httpd.conf | Restore from `xampp/apache/conf/httpd.conf.bak` |
| Missing PHP module | Verify php.ini extension loading |

### MariaDB Won't Start
| Cause | Fix |
|-------|-----|
| Port 3306 occupied | `netstat -ano | findstr :3306` then kill conflicting process |
| Corrupt InnoDB files | Run `mysqlcheck --all-databases --repair` |
| Insufficient disk space | Free disk space (min 1 GB required) |
| my.ini syntax error | Restore from `xampp/mysql/bin/my.ini.bak` |

### Recovery
```powershell
# Check port conflicts
netstat -ano | findstr ":80 :443 :3306"
# Force kill conflicting PID
taskkill /PID <PID> /F
# Restart XAMPP services
& "C:\xampp\xampp_start.exe"
```

---

## Section 3: Database Connection Failed

### Symptoms
- API returns LP-ERR-SYS-5002
- "Connection refused" errors
- Timeout on database queries

### Diagnosis
```powershell
# Test MariaDB connectivity
mysql -u root -p -h 127.0.0.1 -P 3306 -e "SHOW DATABASES;"
# Check connection count
mysql -u root -p -e "SHOW STATUS LIKE 'Threads_connected';"
# Check max connections
mysql -u root -p -e "SHOW VARIABLES LIKE 'max_connections';"
```

### Resolution
| Cause | Fix |
|-------|-----|
| MariaDB not running | Start MariaDB service |
| Max connections reached | Increase max_connections in my.ini (default: 100) |
| Wrong credentials in .env | Verify DB_HOST, DB_PORT, DB_USER, DB_PASS in .env |
| Firewall blocking | Allow port 3306 in Windows Firewall |
| InnoDB corruption | Run recovery: `innodb_force_recovery = 1` in my.ini, restart, then repair |

---

## Section 4: API Returning Errors

### Error Code Quick Reference
| Error Code | Meaning | Fix |
|------------|---------|-----|
| LP-ERR-AUTH-1001 | Invalid credentials | Verify username/password |
| LP-ERR-AUTH-1002 | Token expired | Refresh token via /auth/refresh |
| LP-ERR-AUTH-1004 | Insufficient permissions | Check user role and RBAC scopes |
| LP-ERR-AUTH-1006 | License expired | Renew UMAC license |
| LP-ERR-AUTH-1007 | Machine not authorized | Verify UMAC hash; re-bind license |
| LP-ERR-VAL-2001 | Required field missing | Check request payload |
| LP-ERR-VAL-2004 | Duplicate entry | Check for existing record |
| LP-ERR-BIZ-3002 | Invoice immutable | Use correction memo workflow |
| LP-ERR-SYNC-4001 | Sync conflict | Check dead-letter queue |
| LP-ERR-SYS-5001 | Internal server error | Check PHP error log |
| LP-ERR-SYS-5002 | Database connection failed | See Section 3 |

### PHP Error Log Location
`C:\xampp\php\logs\php_error_log` or `C:\xampp\apache\logs\error.log`

---

## Section 5: Print Job Fails

### Diagnosis
1. Check printer power and USB/network connection.
2. Run auto-discovery to verify detection.
3. Check Windows print spooler: `Get-Service Spooler`
4. Test with direct ESC/POS command.

### Resolution
| Cause | Fix |
|-------|-----|
| Printer offline | Power cycle printer; check USB cable |
| Wrong port assigned | Re-run auto-discovery |
| Print spooler stopped | `Start-Service Spooler` |
| Paper out | Reload paper |
| ESC/POS command error | Verify printer supports ESC/POS; check codepage for Arabic |
| Driver conflict | Remove and reinstall printer driver |

### Test Print
```powershell
# Test Windows spooler
Get-Printer | Format-Table Name, PortName, PrinterStatus
# Restart print spooler
Restart-Service Spooler
```

---

## Section 6: Scanner Not Working

### Diagnosis
1. Check USB connection.
2. Verify scanner appears in Device Manager (HID devices).
3. Test scanner output in Notepad (should inject text + Enter).

### Resolution
| Cause | Fix |
|-------|-----|
| USB not connected | Reconnect USB cable |
| Wrong HID mode | Configure scanner for USB HID keyboard wedge mode |
| Scanner sending wrong suffix | Configure scanner to send CR (Enter) suffix |
| Bluetooth not paired | Re-pair Bluetooth scanner |
| Application not capturing input | Ensure focus is on the scan input field |

---

## Section 7: Sync Not Working

### Diagnosis
```sql
-- Check outbox status
SELECT status, COUNT(*) FROM sync_outbox GROUP BY status;
-- Check dead-letter entries
SELECT * FROM sync_outbox WHERE status = 'dead' ORDER BY created_at DESC LIMIT 10;
-- Check last sync time
SELECT MAX(synced_at) FROM sync_outbox WHERE status = 'synced';
```

### Resolution
| Cause | Fix |
|-------|-----|
| No internet | Expected in offline mode; entries queue in outbox |
| Cloud endpoint down | Entries queue; retry on next connectivity |
| Max retries exceeded | Check dead-letter queue; investigate and replay |
| Conflict unresolved | Manual resolution via admin interface |
| Tenant isolation violation | CRITICAL: investigate immediately |
| Outbox table locked | Check for long-running transactions; restart MariaDB |

---

## Section 8: License Error

### UMAC Troubleshooting
| Symptom | Cause | Fix |
|---------|-------|-----|
| Machine not authorized | Hardware changed (CPU, disk, NIC) | Re-bind license to new hardware hash |
| License expired | Subscription lapsed | Renew license key |
| Read-only mode | Grace period exceeded (30 days offline) | Connect to internet for license verification |
| Invalid license format | Corrupt license key | Request new license from vendor |

### Hardware Hash Verification
```powershell
# Get CPU ID
wmic cpu get ProcessorId
# Get disk serial
wmic diskdrive get SerialNumber
# Get MAC address
getmac /v
```

---

## Section 9: Performance Degradation

### Diagnosis
| Area | Check | Tool |
|------|-------|------|
| Database | Slow queries | `SHOW PROCESSLIST;` and slow query log |
| API | Response time | Check API response time headers |
| UI | Frame rate | Flutter DevTools performance tab |
| Memory | Leak detection | Task Manager memory trend |
| Disk | Space | `Get-PSDrive C` |

### Quick Fixes
```sql
-- Find slow queries
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;
-- Analyze table statistics
ANALYZE TABLE orders, order_items, invoices, customers;
-- Check missing indexes
EXPLAIN SELECT * FROM orders WHERE business_owner_id = 1 AND status = 'pending';
```

---

## Section 10: Data Inconsistency

### Diagnosis
```sql
-- Check orphaned order items
SELECT oi.id FROM order_items oi LEFT JOIN orders o ON oi.order_id = o.id WHERE o.id IS NULL;
-- Check invoice-payment mismatch
SELECT i.id, i.total_amount, COALESCE(SUM(p.amount),0) as paid FROM invoices i LEFT JOIN payments p ON p.invoice_id = i.id GROUP BY i.id HAVING i.total_amount != paid;
-- Check tenant isolation
SELECT table_name FROM information_schema.columns WHERE column_name = 'business_owner_id' AND table_schema = 'laundrypro';
```

### Resolution
1. Identify root cause (missing FK, failed sync, bug).
2. Take backup before any data fix.
3. Apply data correction with audit log entry.
4. Verify with integrity checks.
5. Add regression test to prevent recurrence.

---

## Section 11: UI Rendering Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| RTL layout broken | Missing Directionality | Wrap with Directionality widget |
| Text overflow | Long Arabic text | Use TextOverflow.ellipsis or Flexible |
| Widget rebuild jank | Unnecessary rebuilds | Use const constructors and select() |
| Theme not applied | Wrong context | Ensure Theme.of(context) is used |
| Images not loading | Wrong path | Check asset declarations in pubspec.yaml |

---

## Section 12: Backup/Restore Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Backup fails | Disk full | Free space; minimum 2x database size |
| SHA-256 mismatch | Corrupt backup file | Re-run backup; check disk health |
| Restore fails | Version mismatch | Ensure backup matches current schema version |
| Partial restore | Interrupted process | Restore from the previous clean backup |

### Emergency Backup
```powershell
# Emergency manual backup
cd C:\xampp\mysql\bin
mysqldump -u root -p --single-transaction --routines --triggers laundrypro > "backup_emergency_20260921_014725.sql"
```

---

## Escalation Matrix for Runtime Issues
| Severity | Response Time | Who to Contact |
|----------|--------------|----------------|
| P1 Critical (system down) | 15 min | OPS-L3 + CTO |
| P2 High (major feature broken) | 1 hour | OPS-L2 + ENG-LEAD |
| P3 Medium (workaround available) | 4 hours | OPS-L1 |
| P4 Low (cosmetic/enhancement) | Next sprint | Backlog |

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial runtime troubleshooting guide |

## --- FILE: README.md ---

# Peripherals (Windows hardware)

LaundryPro UAE integrates ESC/POS printing, barcode scanner wedge, scale parser, cash drawer, and diagnostic tools via `lib/peripherals/`.

## Setup

1. Open **Settings → Peripherals**
2. **Printer** tab — select Windows installed thermal printer
3. **POS** — after payment, use **Print** for hardware or **Save PDF** for fallback

## Requirements

- Windows 10/11 desktop
- PowerShell (printer discovery via Win32 spooler)
- Selected printer in Peripherals console before POS hardware print

## Cash drawer

Drawer kick uses ESC/POS pulse through the selected printer. Configure printer in Peripherals → **Cash Drawer** tab or pulse automatically on cash payment in POS.

## Scanner

USB keyboard-wedge scanners work without drivers. POS and Peripherals screens listen for fast key bursts; matches service `code` or product `barcode` via catalog API.

## MSIX / VC++ runtime

For MSIX builds, stage VC++ runtime DLLs before packaging:

```powershell
powershell scripts/peripherals/stage_missing_dlls.ps1
```

Required DLLs: `msvcp140.dll`, `msvcp140_1.dll`, `vcruntime140.dll`, `vcruntime140_1.dll` (from Visual C++ Redistributable).

## Remote SQL tab

Admin diagnostic only — connects directly to MySQL bypassing API auth. Use on trusted LAN only.

## Local database

Peripheral templates, print queue, and logs use SQLite at:

`%APPDATA%/laundrypro_peripherals.db` (via `getApplicationSupportDirectory`)


## --- FILE: api_quick_reference.md ---

﻿# API Quick Reference - LaundryPro UAE
> **Version:** 1.0.0

## Auth
| Method | Path | Description |
|--------|------|-------------|
| POST | /api/v1/auth/login | Login (returns tokens) |
| POST | /api/v1/auth/refresh | Refresh access token |
| POST | /api/v1/auth/logout | Revoke tokens |

## Orders
| Method | Path | Description |
|--------|------|-------------|
| GET | /api/v1/orders | List orders (paginated) |
| POST | /api/v1/orders | Create order |
| GET | /api/v1/orders/:id | Get order detail |
| PATCH | /api/v1/orders/:id | Update order |
| POST | /api/v1/orders/:id/status | Update order status |

## Customers
| Method | Path | Description |
|--------|------|-------------|
| GET | /api/v1/customers | List customers |
| POST | /api/v1/customers | Create customer |
| GET | /api/v1/customers/:id | Get customer |
| PATCH | /api/v1/customers/:id | Update customer |

## Sync
| Method | Path | Description |
|--------|------|-------------|
| POST | /api/v1/sync/push | Push outbox entries |
| GET | /api/v1/sync/pull | Pull cloud changes |

## --- FILE: README.md ---

﻿# Reference Documentation - LaundryPro UAE
> **Version:** 1.0.0

Quick reference cards and cheat sheets.

## --- FILE: business_requirements.md ---

﻿# Business Requirements - LaundryPro UAE
> **Version:** 1.0.0

## Business Objectives
1. Provide a complete ERP/CRM/POS solution for UAE laundry businesses.
2. Support offline-first operation (internet not required for daily operations).
3. Support multi-tenant deployment (multiple business owners, multiple branches).
4. Support bilingual interface (English LTR + Arabic RTL).
5. Comply with UAE regulations (VAT, FTA, WPS, PDPL).
6. Support all common laundry hardware (printers, scanners, cash drawers, RFID).
7. Enable data synchronization when connectivity is available.
8. Protect against piracy with machine-bound licensing (UMAC).

## Business Constraints
- Must run on Windows 10/11 desktop (MSIX distribution).
- Must work without internet (offline-first).
- Must use local XAMPP server (no cloud dependency for core operations).
- Must support existing laundry hardware ecosystem in UAE.
- Must comply with UAE Federal Tax Authority (FTA) requirements.
- All monetary calculations must use DECIMAL precision (zero floating-point).

## Target Users
1. **Business Owners** - Financial oversight, reports, multi-branch management
2. **Branch Managers** - Daily operations, staff management, inventory
3. **Cashiers** - POS operations, order intake, payments
4. **Production Operators** - Garment processing, quality checks
5. **Delivery Drivers** - Route management, delivery confirmation
6. **System Administrators** - System configuration, user management

## Success Criteria
- Cashier can process order in < 30 seconds.
- System operates for 30+ days without internet.
- VAT calculation matches FTA requirements exactly.
- All data syncs correctly after connectivity restoration.
- Zero data loss during offline/online transitions.

## --- FILE: functional_requirements.md ---

﻿# Functional Requirements - LaundryPro UAE
> **Version:** 1.0.0

## Module: Authentication & Authorization
- FR-AUTH-001: System shall support username/password login.
- FR-AUTH-002: System shall enforce RBAC with 6 defined roles.
- FR-AUTH-003: System shall issue JWT access tokens (15-min expiry).
- FR-AUTH-004: System shall support token refresh (7-day refresh token).
- FR-AUTH-005: System shall support session management and logout.
- FR-AUTH-006: System shall enforce machine-bound licensing (UMAC).

## Module: Order Management
- FR-ORD-001: System shall support walk-in, pickup, and corporate order intake.
- FR-ORD-002: System shall assign sequential order numbers (ORD-YYYY-NNNNNN).
- FR-ORD-003: System shall support barcode and RFID garment tagging.
- FR-ORD-004: System shall track order status (received, processing, ready, delivered).
- FR-ORD-005: System shall support express, same-day, next-day, and standard turnaround.
- FR-ORD-006: System shall calculate pricing per-item, per-kg, or per-piece.
- FR-ORD-007: System shall support line-item discounts and order-level discounts.
- FR-ORD-008: System shall support order notes and special instructions.

## Module: Point of Sale
- FR-POS-001: System shall display service catalog with prices.
- FR-POS-002: System shall support barcode scanner input for item lookup.
- FR-POS-003: System shall calculate subtotal, discount, VAT, and total.
- FR-POS-004: System shall support cash, card, and split payment methods.
- FR-POS-005: System shall print receipt on thermal printer.
- FR-POS-006: System shall open cash drawer after cash payment.

## Module: Inventory
- FR-INV-001: System shall track supply inventory (detergent, hangers, bags, etc.).
- FR-INV-002: System shall support stock-in and stock-out transactions.
- FR-INV-003: System shall alert when stock falls below minimum threshold.
- FR-INV-004: System shall track garment inventory by status and location.

## Module: Production
- FR-PRD-001: System shall track garment production stages.
- FR-PRD-002: System shall support quality check pass/fail.
- FR-PRD-003: System shall support rewash/reclean workflow.
- FR-PRD-004: System shall track production by operator for performance.

## Module: Delivery
- FR-DEL-001: System shall support route planning with address management.
- FR-DEL-002: System shall track delivery status (assigned, en-route, delivered).
- FR-DEL-003: System shall support delivery confirmation with signature/photo.
- FR-DEL-004: System shall support driver assignment and reassignment.

## Module: Customer Management
- FR-CUS-001: System shall maintain customer profiles with contact info.
- FR-CUS-002: System shall track customer order history.
- FR-CUS-003: System shall support corporate accounts with billing.
- FR-CUS-004: System shall support customer preferences and notes.

## Module: HR & Payroll
- FR-HR-001: System shall manage employee records.
- FR-HR-002: System shall track attendance (check-in/check-out).
- FR-HR-003: System shall calculate payroll with UAE overtime rules.
- FR-HR-004: System shall export SIF files for WPS compliance.
- FR-HR-005: System shall track leave entitlements and balances.

## Module: Finance & Invoicing
- FR-FIN-001: System shall generate invoices with TRN and VAT.
- FR-FIN-002: System shall enforce immutable posted invoices.
- FR-FIN-003: System shall support correction memos for invoice amendments.
- FR-FIN-004: System shall generate financial reports (daily, weekly, monthly).
- FR-FIN-005: System shall track all payments and outstanding balances.

## Module: Reports & Analytics
- FR-RPT-001: System shall generate sales reports by period, branch, employee.
- FR-RPT-002: System shall generate production reports by operator, service type.
- FR-RPT-003: System shall generate financial reports (P&L, cash flow, aging).
- FR-RPT-004: System shall support report export (PDF, CSV).
- FR-RPT-005: System shall display dashboard KPIs.

## Module: Settings & Configuration
- FR-SET-001: System shall support multi-branch configuration.
- FR-SET-002: System shall support service catalog management.
- FR-SET-003: System shall support price list management.
- FR-SET-004: System shall support hardware configuration (printers, scanners).
- FR-SET-005: System shall support backup and restore.

## --- FILE: non_functional_requirements.md ---

﻿# Non-Functional Requirements - LaundryPro UAE
> **Version:** 1.0.0

## Performance
- NFR-PERF-001: API response time < 500ms at P95.
- NFR-PERF-002: Page load time < 2 seconds for all screens.
- NFR-PERF-003: Database query execution < 100ms at P95.
- NFR-PERF-004: Order processing (POS) < 30 seconds end-to-end.
- NFR-PERF-005: Print job queuing < 2 seconds.
- NFR-PERF-006: Sync outbox flush < 30 seconds after connectivity restoration.

## Reliability
- NFR-REL-001: System shall operate continuously for 30+ days without internet.
- NFR-REL-002: Zero data loss during offline/online transitions.
- NFR-REL-003: Automatic recovery from hardware disconnection.
- NFR-REL-004: Database backup with SHA-256 integrity verification.

## Security
- NFR-SEC-001: All API endpoints authenticated via JWT.
- NFR-SEC-002: RBAC enforced server-side on all routes.
- NFR-SEC-003: All user input sanitized (SQL injection, XSS prevention).
- NFR-SEC-004: PII encrypted at rest.
- NFR-SEC-005: Machine-bound licensing (UMAC) prevents unauthorized use.
- NFR-SEC-006: Audit trail tamper-evident with hash chaining.

## Usability
- NFR-USE-001: Full LTR (English) and RTL (Arabic) support.
- NFR-USE-002: WCAG 2.1 AA accessibility compliance.
- NFR-USE-003: Keyboard navigation for all screens.
- NFR-USE-004: Font scaling support (100%-200%).

## Scalability
- NFR-SCA-001: Support up to 10 concurrent users per branch.
- NFR-SCA-002: Support up to 50 branches per business owner.
- NFR-SCA-003: Support up to 100,000 orders per branch per year.
- NFR-SCA-004: Support up to 500 inventory items per branch.

## --- FILE: README.md ---

﻿# Requirements - LaundryPro UAE
> **Version:** 1.0.0

## Document Index
| Document | Description |
|----------|-------------|
| business_requirements.md | High-level business objectives and constraints |
| functional_requirements.md | Detailed functional requirements by module |
| non_functional_requirements.md | Performance, security, usability, reliability requirements |
| user_roles.md | User role definitions and permission matrix |
| use_case_summary.md | Summary of all use cases by module |

## --- FILE: user_roles.md ---

﻿# User Roles & Permissions - LaundryPro UAE
> **Version:** 1.0.0

## Role Hierarchy
super_admin > owner > manager > cashier / operator / driver

## Permission Matrix
| Module | Action | super_admin | owner | manager | cashier | operator | driver |
|--------|--------|:-----------:|:-----:|:-------:|:-------:|:--------:|:------:|
| Auth | Login | Y | Y | Y | Y | Y | Y |
| Auth | Manage Users | Y | Y | N | N | N | N |
| Orders | Create | Y | Y | Y | Y | N | N |
| Orders | View All | Y | Y | Y | N | N | N |
| Orders | View Own | Y | Y | Y | Y | Y | Y |
| POS | Process Payment | Y | Y | Y | Y | N | N |
| POS | Void Transaction | Y | Y | Y | N | N | N |
| Inventory | View | Y | Y | Y | N | Y | N |
| Inventory | Modify | Y | Y | Y | N | N | N |
| Production | Update Status | Y | Y | Y | N | Y | N |
| Delivery | Assign Driver | Y | Y | Y | N | N | N |
| Delivery | Update Status | Y | Y | Y | N | N | Y |
| Customers | View | Y | Y | Y | Y | N | N |
| Customers | Modify | Y | Y | Y | N | N | N |
| HR | View Employees | Y | Y | Y | N | N | N |
| HR | Manage Payroll | Y | Y | N | N | N | N |
| Finance | View Reports | Y | Y | Y | N | N | N |
| Finance | Manage Invoices | Y | Y | N | N | N | N |
| Settings | Configure | Y | Y | N | N | N | N |
| Settings | Manage Branches | Y | Y | N | N | N | N |
| System | Backup/Restore | Y | Y | N | N | N | N |
| System | License Mgmt | Y | N | N | N | N | N |

## --- FILE: README.md ---

﻿# Security Documentation - LaundryPro UAE
> **Version:** 1.0.0

Security architecture, policies, and procedures.

## --- FILE: security_architecture.md ---

﻿# Security Architecture - LaundryPro UAE
> **Version:** 1.0.0

## Security Layers
1. **Authentication**: JWT with 15-min access tokens, 7-day refresh tokens.
2. **Authorization**: RBAC with scope-based permissions on all endpoints.
3. **Input Validation**: Server-side validation on all inputs; PDO prepared statements.
4. **Data Protection**: AES-256-GCM encryption for PII at rest; SHA-256 for backup verification.
5. **Audit Trail**: Hash-chained audit logs for tamper evidence.
6. **Licensing**: UMAC machine-bound licensing with hardware hash verification.
7. **Tenant Isolation**: business_owner_id on all data queries and mutations.

## --- FILE: README.md ---

﻿# Sync Engine Documentation - LaundryPro UAE
> **Version:** 1.0.0

Offline-first sync engine documentation.

## --- FILE: sync_protocol.md ---

﻿# Sync Protocol Specification - LaundryPro UAE
> **Version:** 1.0.0

## Sync Outbox Schema
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Entry ID |
| sequence_number | BIGINT UNSIGNED | Monotonic sequence |
| idempotency_key | CHAR(36) UUID | Deduplication key |
| table_name | VARCHAR(100) | Target table |
| row_id | BIGINT UNSIGNED | Target row PK |
| operation | ENUM('INSERT','UPDATE','DELETE') | Operation type |
| payload | JSON | Data payload |
| business_owner_id | BIGINT UNSIGNED FK | Tenant scope |
| status | ENUM('pending','synced','failed','dead') | Sync status |
| retry_count | INT DEFAULT 0 | Retry attempts |
| created_at | DATETIME | Entry creation time |
| synced_at | DATETIME NULL | Sync completion time |

## Push Protocol
POST /api/v1/sync/push with batch of outbox entries (max 100 per request).

## Pull Protocol
GET /api/v1/sync/pull?since={last_sequence}&limit=100.

## Conflict Resolution
Last-Write-Wins by updated_at. If equal timestamps, higher sequence_number wins.
Unresolvable conflicts moved to dead-letter queue for manual resolution.

## --- FILE: README.md ---

﻿# Testing Documentation - LaundryPro UAE
> **Version:** 1.0.0

Test strategies, plans, and frameworks.

## --- FILE: test_strategy.md ---

﻿# Test Strategy - LaundryPro UAE
> **Version:** 1.0.0

## Test Pyramid
1. **Unit Tests** (base): Individual functions, methods, widgets. Target: 80% coverage.
2. **Integration Tests** (middle): API endpoints, database queries, cross-module flows.
3. **E2E Tests** (top): Full user workflows through the UI.

## Test Frameworks
| Layer | Flutter | PHP |
|-------|---------|-----|
| Unit | flutter_test | PHPUnit |
| Widget | testWidgets, golden | N/A |
| Integration | integration_test | PHPUnit + HTTP client |
| E2E | integration_test (driver) | N/A |

## Quality Gates (must pass before release)
- Unit test pass rate: 100%
- Integration test pass rate: 100%
- Code coverage: >= 80%
- Zero CRITICAL bot alerts
- Regression suite: 100% pass
- Security test: 100% pass
- Accessibility: WCAG 2.1 AA compliant

## --- FILE: cashier_guide.md ---

﻿# Cashier Quick Start Guide - LaundryPro UAE
> **Version:** 1.0.0

## Getting Started
1. Login with your cashier credentials.
2. You will see the Dashboard with today's pending orders.

## Creating an Order
1. Click **New Order** or navigate to **POS**.
2. Search or scan items to add to the order.
3. Review the order summary (subtotal, discount, VAT, total).
4. Click **Process Payment**.
5. Select payment method (cash or card).
6. Receipt prints automatically.
7. Cash drawer opens (if cash payment).

## Common Tasks
- **Lookup Customer**: Use the search bar in Customers.
- **Apply Discount**: Click the discount icon on a line item or order.
- **Reprint Receipt**: Open order detail and click Print.
- **Switch Language**: Click the language toggle (EN/AR) in the top bar.

## --- FILE: README.md ---

﻿# Training Documentation - LaundryPro UAE
> **Version:** 1.0.0

User training materials and guides.

## --- FILE: design_system.md ---

﻿# Design System - LaundryPro UAE
> **Version:** 1.0.0

## Colors
| Token | Value | Usage |
|-------|-------|-------|
| primary | #1E88E5 | Primary actions, headers |
| primaryDark | #1565C0 | Pressed states |
| secondary | #43A047 | Success, confirmations |
| error | #E53935 | Errors, warnings |
| warning | #FB8C00 | Caution states |
| surface | #FFFFFF | Card backgrounds |
| background | #F5F5F5 | Page backgrounds |
| onPrimary | #FFFFFF | Text on primary |
| onSurface | #212121 | Primary text |
| onSurfaceVariant | #757575 | Secondary text |

## Typography
| Style | Font (LTR) | Font (RTL) | Size | Weight |
|-------|-----------|-----------|------|--------|
| displayLarge | Inter | Noto Sans Arabic | 32sp | Bold |
| headlineMedium | Inter | Noto Sans Arabic | 24sp | SemiBold |
| titleLarge | Inter | Noto Sans Arabic | 20sp | Medium |
| bodyLarge | Inter | Noto Sans Arabic | 16sp | Regular |
| bodyMedium | Inter | Noto Sans Arabic | 14sp | Regular |
| labelLarge | Inter | Noto Sans Arabic | 14sp | Medium |
| labelSmall | Inter | Noto Sans Arabic | 12sp | Regular |

## Spacing Scale
| Token | Value |
|-------|-------|
| xs | 4dp |
| sm | 8dp |
| md | 16dp |
| lg | 24dp |
| xl | 32dp |
| xxl | 48dp |

## Components
- Buttons: Primary (filled), Secondary (outlined), Text, Icon
- Inputs: TextField, Dropdown, DatePicker, SearchField
- Cards: Elevated, Outlined
- Tables: DataTable with sorting, pagination, selection
- Dialogs: Alert, Confirm, Form
- Navigation: Sidebar, TopBar, Breadcrumbs

## --- FILE: navigation_map.md ---

﻿# Navigation Map - LaundryPro UAE
> **Version:** 1.0.0

## Navigation Structure (go_router)

```
/login
/dashboard
/pos
/orders
  /orders/new
  /orders/:id
/customers
  /customers/new
  /customers/:id
/inventory
  /inventory/stock-in
  /inventory/stock-out
/production
  /production/:id
  /production/qc
/deliveries
  /deliveries/:id
  /deliveries/route
/employees
  /employees/:id
/attendance
/payroll
/leaves
/invoices
  /invoices/:id
  /invoices/:id/correction
/payments
/expenses
/reports
  /reports/daily
  /reports/sales
  /reports/financial
  /reports/production
  /reports/hr
/settings
  /settings/branches
  /settings/services
  /settings/prices
  /settings/users
  /settings/hardware
  /settings/backup
  /settings/license
  /settings/sync
```

## Sidebar Navigation Groups
1. **Main**: Dashboard, POS
2. **Operations**: Orders, Customers, Production, Deliveries
3. **Inventory**: Stock Management
4. **HR**: Employees, Attendance, Payroll, Leaves
5. **Finance**: Invoices, Payments, Expenses
6. **Reports**: All report types
7. **Settings**: System configuration

## --- FILE: README.md ---

﻿# UI Documentation - LaundryPro UAE
> **Version:** 1.0.0

## Documents
| Document | Description |
|----------|-------------|
| design_system.md | Colors, typography, spacing, components |
| screen_catalog.md | Complete screen inventory (42+ screens) |
| navigation_map.md | Application navigation structure |
| responsive_rules.md | LTR/RTL responsive layout rules |

## --- FILE: responsive_rules.md ---

﻿# LTR/RTL Responsive Rules - LaundryPro UAE
> **Version:** 1.0.0

## Layout Rules
1. Use `start` and `end` instead of `left` and `right`.
2. Use `Directionality` widget for text direction.
3. Use `TextDirection.ltr` for English, `TextDirection.rtl` for Arabic.
4. All padding/margin use start/end, not left/right.
5. Icons that indicate direction (arrows, chevrons) must flip in RTL.

## Typography Rules
1. LTR font: Inter (Latin glyphs).
2. RTL font: Noto Sans Arabic (Arabic glyphs).
3. Numbers always displayed LTR even in RTL context.
4. Dates follow locale format (DD/MM/YYYY for both EN and AR).

## Component Rules
1. Tables: Column order does NOT reverse in RTL.
2. Forms: Labels align to start (right in RTL).
3. Navigation: Sidebar on start side (right in RTL).
4. Buttons: Icon position flips in RTL.
5. Dialogs: Close button on end side (left in RTL).

## --- FILE: screen_catalog.md ---

﻿# Screen Catalog - LaundryPro UAE
> **Version:** 1.0.0

## Screens by Module (42+)
| # | Screen | Route | Module | Roles |
|---|--------|-------|--------|-------|
| 1 | Login | /login | Auth | All |
| 2 | Dashboard | /dashboard | Dashboard | All |
| 3 | POS | /pos | POS | cashier, manager, owner |
| 4 | Order List | /orders | Orders | cashier, manager, owner |
| 5 | Order Detail | /orders/:id | Orders | cashier, manager, owner |
| 6 | New Order | /orders/new | Orders | cashier, manager |
| 7 | Customer List | /customers | Customers | cashier, manager, owner |
| 8 | Customer Detail | /customers/:id | Customers | cashier, manager, owner |
| 9 | New Customer | /customers/new | Customers | cashier, manager |
| 10 | Inventory List | /inventory | Inventory | manager, owner |
| 11 | Stock In | /inventory/stock-in | Inventory | manager |
| 12 | Stock Out | /inventory/stock-out | Inventory | manager |
| 13 | Production Queue | /production | Production | operator, manager |
| 14 | Production Detail | /production/:id | Production | operator, manager |
| 15 | Quality Check | /production/qc | Production | operator, manager |
| 16 | Delivery List | /deliveries | Delivery | driver, manager |
| 17 | Delivery Detail | /deliveries/:id | Delivery | driver, manager |
| 18 | Route View | /deliveries/route | Delivery | driver |
| 19 | Employee List | /employees | HR | manager, owner |
| 20 | Employee Detail | /employees/:id | HR | manager, owner |
| 21 | Attendance | /attendance | HR | manager, owner |
| 22 | Payroll | /payroll | HR | owner |
| 23 | Invoice List | /invoices | Finance | manager, owner |
| 24 | Invoice Detail | /invoices/:id | Finance | manager, owner |
| 25 | Payment List | /payments | Finance | cashier, manager, owner |
| 26 | Daily Report | /reports/daily | Reports | manager, owner |
| 27 | Sales Report | /reports/sales | Reports | manager, owner |
| 28 | Financial Report | /reports/financial | Reports | owner |
| 29 | Production Report | /reports/production | Reports | manager, owner |
| 30 | HR Report | /reports/hr | Reports | owner |
| 31 | Settings | /settings | Settings | admin, owner |
| 32 | Branch Management | /settings/branches | Settings | admin, owner |
| 33 | Service Catalog | /settings/services | Settings | manager, owner |
| 34 | Price Lists | /settings/prices | Settings | manager, owner |
| 35 | User Management | /settings/users | Settings | admin, owner |
| 36 | Hardware Config | /settings/hardware | Settings | admin |
| 37 | Backup & Restore | /settings/backup | Settings | admin, owner |
| 38 | License | /settings/license | Settings | admin |
| 39 | Sync Status | /settings/sync | Settings | admin, manager |
| 40 | Correction Memo | /invoices/:id/correction | Finance | manager, owner |
| 41 | Leave Management | /leaves | HR | manager, owner |
| 42 | Expense Tracking | /expenses | Finance | manager, owner |

## --- FILE: README.md ---

﻿# Use Cases - LaundryPro UAE
> **Version:** 1.0.0

## Use Case Index by Actor
| Actor | Use Cases |
|-------|-----------|
| Cashier | UC-001 to UC-010 (POS, orders, payments) |
| Manager | UC-011 to UC-020 (oversight, reports, staff) |
| Operator | UC-021 to UC-025 (production, quality) |
| Driver | UC-026 to UC-030 (delivery, route) |
| Owner | UC-031 to UC-040 (finance, multi-branch, analytics) |
| Admin | UC-041 to UC-050 (system config, users, licensing) |

## --- FILE: uc_admin.md ---

﻿# Use Cases: admin - LaundryPro UAE
> **Version:** 1.0.0

## UC-041: Configure System Settings
Actor: Admin. Flow: Open settings -> Modify configuration -> Save -> Restart services if needed.

## UC-042: Manage Hardware
Actor: Admin. Flow: Run auto-discovery -> Review detected devices -> Configure connections -> Test printing.

## UC-043: License Management
Actor: Admin. Flow: View license status -> Activate/renew license -> Verify machine binding.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial use case documentation |

## --- FILE: uc_cashier.md ---

﻿# Use Cases: cashier - LaundryPro UAE
> **Version:** 1.0.0

## UC-001: Create Walk-in Order
Actor: Cashier. Flow: Open POS -> Scan/select items -> Apply pricing -> Calculate total -> Process payment -> Print receipt.

## UC-002: Process Payment
Actor: Cashier. Flow: Select payment method -> Enter amount -> Validate -> Record -> Print receipt -> Open drawer.

## UC-003: Lookup Customer
Actor: Cashier. Flow: Search by name/phone -> Select customer -> Auto-fill order details.

## UC-004: Apply Discount
Actor: Cashier. Flow: Select line item or order -> Apply discount (% or fixed) -> Recalculate totals.

## UC-005: Print Receipt
Actor: Cashier. Flow: Select order -> Preview receipt -> Print on configured printer.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial use case documentation |

## --- FILE: uc_driver.md ---

﻿# Use Cases: driver - LaundryPro UAE
> **Version:** 1.0.0

## UC-026: View Delivery Route
Actor: Driver. Flow: Login -> View assigned deliveries -> See route order -> Navigate to first stop.

## UC-027: Confirm Delivery
Actor: Driver. Flow: Arrive at customer -> Hand over items -> Capture confirmation -> Update status to delivered.

## UC-028: Handle Failed Delivery
Actor: Driver. Flow: Customer unavailable -> Mark as failed -> Add notes -> Return items to branch.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial use case documentation |

## --- FILE: uc_manager.md ---

﻿# Use Cases: manager - LaundryPro UAE
> **Version:** 1.0.0

## UC-011: View Daily Summary
Actor: Manager. Flow: Open dashboard -> View KPIs (orders, revenue, pending) -> Drill down by branch.

## UC-012: Manage Employees
Actor: Manager. Flow: View employee list -> Add/edit/deactivate -> Assign roles -> Set schedules.

## UC-013: Approve Refund
Actor: Manager. Flow: Review refund request -> Check original invoice -> Approve/reject -> Process if approved.

## UC-014: Manage Inventory
Actor: Manager. Flow: View stock levels -> Stock-in with supplier reference -> Review alerts for low stock.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial use case documentation |

## --- FILE: uc_operator.md ---

﻿# Use Cases: operator - LaundryPro UAE
> **Version:** 1.0.0

## UC-021: Process Garment
Actor: Operator. Flow: Scan garment tag -> View processing instructions -> Perform service -> Mark complete -> Move to next stage.

## UC-022: Quality Check
Actor: Operator. Flow: Inspect processed garment -> Pass/fail -> If fail: flag defect and send for rewash.

## UC-023: Package Order
Actor: Operator. Flow: Verify all items complete -> Package -> Mark order as ready -> Notify customer.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial use case documentation |

## --- FILE: uc_owner.md ---

﻿# Use Cases: owner - LaundryPro UAE
> **Version:** 1.0.0

## UC-031: View Financial Reports
Actor: Owner. Flow: Select report type -> Choose period and branch -> Generate -> View/export.

## UC-032: Multi-Branch Overview
Actor: Owner. Flow: View all branches -> Compare KPIs -> Drill into branch details.

## UC-033: Payroll Review
Actor: Owner. Flow: View payroll summary -> Review calculations -> Approve -> Export SIF for WPS.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial use case documentation |

## --- FILE: cashier_daily.md ---

﻿# User Journey: cashier daily - LaundryPro UAE
> **Version:** 1.0.0

## Journey Steps
06:00 Login -> Check pending orders -> Process walk-in customers -> Scan items -> Calculate totals -> Process payments -> Print receipts -> Handle customer queries -> Process pickups -> End-of-shift cash count.

## Touchpoints
- Desktop application (Flutter Windows)
- Thermal receipt printer
- Barcode scanner
- Cash drawer

## Pain Points Addressed
- Offline operation (no internet dependency)
- Fast POS processing (< 30 seconds)
- Bilingual interface (EN/AR)
- Automatic hardware detection

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial user journey |

## --- FILE: first_time_setup.md ---

﻿# User Journey: first time setup - LaundryPro UAE
> **Version:** 1.0.0

## Journey Steps
Install MSIX -> Launch app -> Enter license key -> Configure business profile (name, TRN, address) -> Create admin account -> Add first branch -> Run hardware auto-discovery -> Configure printer -> Import service catalog -> Create first test order -> Verify receipt printing -> Go live.

## Touchpoints
- Desktop application (Flutter Windows)
- Thermal receipt printer
- Barcode scanner
- Cash drawer

## Pain Points Addressed
- Offline operation (no internet dependency)
- Fast POS processing (< 30 seconds)
- Bilingual interface (EN/AR)
- Automatic hardware detection

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial user journey |

## --- FILE: manager_daily.md ---

﻿# User Journey: manager daily - LaundryPro UAE
> **Version:** 1.0.0

## Journey Steps
07:00 Login -> Review dashboard KPIs -> Check production queue -> Assign operators -> Handle escalations -> Review inventory alerts -> Process refund requests -> Generate daily report -> End-of-day close.

## Touchpoints
- Desktop application (Flutter Windows)
- Thermal receipt printer
- Barcode scanner
- Cash drawer

## Pain Points Addressed
- Offline operation (no internet dependency)
- Fast POS processing (< 30 seconds)
- Bilingual interface (EN/AR)
- Automatic hardware detection

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial user journey |

## --- FILE: owner_weekly.md ---

﻿# User Journey: owner weekly - LaundryPro UAE
> **Version:** 1.0.0

## Journey Steps
Weekly: Login -> Review multi-branch dashboard -> Compare branch performance -> Review financial reports -> Approve payroll -> Check license status -> Plan next week's operations.

## Touchpoints
- Desktop application (Flutter Windows)
- Thermal receipt printer
- Barcode scanner
- Cash drawer

## Pain Points Addressed
- Offline operation (no internet dependency)
- Fast POS processing (< 30 seconds)
- Bilingual interface (EN/AR)
- Automatic hardware detection

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial user journey |

## --- FILE: README.md ---

﻿# User Journeys - LaundryPro UAE
> **Version:** 1.0.0

## Journey Index
| Journey | Persona | Description |
|---------|---------|-------------|
| cashier_daily.md | Cashier | A cashier's typical workday |
| manager_daily.md | Manager | A manager's typical workday |
| owner_weekly.md | Owner | Owner's weekly review |
| first_time_setup.md | Admin | Initial system setup experience |

## --- FILE: daily_close.md ---

﻿# Workflow: daily close - LaundryPro UAE
> **Version:** 1.0.0

## Flow
Daily close: Print daily summary report -> Count cash register -> Enter counted amount -> System calculates variance -> Manager reviews and approves -> Generate daily financial report -> Backup database.

## Actors
- Relevant user roles as defined in user_roles.md

## Preconditions
- User authenticated with appropriate role
- System online or offline (offline-first capable)

## Postconditions
- All state changes logged to audit_logs
- Sync outbox updated for offline entries

## Error Handling
- Validation errors shown inline
- System errors logged and user notified
- Offline mode: operations queued in sync outbox

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial workflow documentation |

## --- FILE: delivery_flow.md ---

﻿# Workflow: delivery flow - LaundryPro UAE
> **Version:** 1.0.0

## Flow
Delivery: Orders marked ready -> Group by route -> Assign driver -> Driver departs -> Update status en-route -> Deliver to customer -> Confirm delivery -> Update order status.

## Actors
- Relevant user roles as defined in user_roles.md

## Preconditions
- User authenticated with appropriate role
- System online or offline (offline-first capable)

## Postconditions
- All state changes logged to audit_logs
- Sync outbox updated for offline entries

## Error Handling
- Validation errors shown inline
- System errors logged and user notified
- Offline mode: operations queued in sync outbox

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial workflow documentation |

## --- FILE: order_intake.md ---

﻿# Workflow: order intake - LaundryPro UAE
> **Version:** 1.0.0

## Flow
Walk-in order: Customer arrives -> Cashier creates order -> Add items (scan/manual) -> Apply pricing -> Calculate total with VAT -> Process payment -> Print receipt -> Tag garments -> Send to sorting.

## Actors
- Relevant user roles as defined in user_roles.md

## Preconditions
- User authenticated with appropriate role
- System online or offline (offline-first capable)

## Postconditions
- All state changes logged to audit_logs
- Sync outbox updated for offline entries

## Error Handling
- Validation errors shown inline
- System errors logged and user notified
- Offline mode: operations queued in sync outbox

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial workflow documentation |

## --- FILE: payment_flow.md ---

﻿# Workflow: payment flow - LaundryPro UAE
> **Version:** 1.0.0

## Flow
Payment: Calculate total (subtotal - discounts + VAT) -> Select method (cash/card/split) -> Process payment -> Record in payments table -> Update order paid status -> Print receipt -> Open cash drawer (if cash).

## Actors
- Relevant user roles as defined in user_roles.md

## Preconditions
- User authenticated with appropriate role
- System online or offline (offline-first capable)

## Postconditions
- All state changes logged to audit_logs
- Sync outbox updated for offline entries

## Error Handling
- Validation errors shown inline
- System errors logged and user notified
- Offline mode: operations queued in sync outbox

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial workflow documentation |

## --- FILE: pickup_order.md ---

﻿# Workflow: pickup order - LaundryPro UAE
> **Version:** 1.0.0

## Flow
Pickup order: Customer calls/schedules online -> Manager creates pickup order -> Assign driver -> Driver collects garments -> Tag at branch -> Process as standard order.

## Actors
- Relevant user roles as defined in user_roles.md

## Preconditions
- User authenticated with appropriate role
- System online or offline (offline-first capable)

## Postconditions
- All state changes logged to audit_logs
- Sync outbox updated for offline entries

## Error Handling
- Validation errors shown inline
- System errors logged and user notified
- Offline mode: operations queued in sync outbox

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial workflow documentation |

## --- FILE: production_flow.md ---

﻿# Workflow: production flow - LaundryPro UAE
> **Version:** 1.0.0

## Flow
Production: Sorted garments -> Assign to operator -> Process (wash/dry/iron) -> Quality check -> Pass: package -> Fail: rewash/flag -> Mark ready -> Notify customer.

## Actors
- Relevant user roles as defined in user_roles.md

## Preconditions
- User authenticated with appropriate role
- System online or offline (offline-first capable)

## Postconditions
- All state changes logged to audit_logs
- Sync outbox updated for offline entries

## Error Handling
- Validation errors shown inline
- System errors logged and user notified
- Offline mode: operations queued in sync outbox

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial workflow documentation |

## --- FILE: README.md ---

﻿# Business Workflows - LaundryPro UAE
> **Version:** 1.0.0

## Workflow Index
| Workflow | Description |
|----------|-------------|
| order_intake.md | Walk-in order creation flow |
| pickup_order.md | Scheduled pickup order flow |
| production_flow.md | Garment processing pipeline |
| delivery_flow.md | Order delivery workflow |
| payment_flow.md | Payment processing workflow |
| refund_flow.md | Refund and correction workflow |
| daily_close.md | End-of-day closing procedure |
| tenant_setup.md | New tenant onboarding workflow |

## --- FILE: refund_flow.md ---

﻿# Workflow: refund flow - LaundryPro UAE
> **Version:** 1.0.0

## Flow
Refund: Identify original invoice -> Create correction memo (credit note) -> Process refund payment -> Create new invoice if needed -> Log audit trail -> Manager approval required for refunds > 500 AED.

## Actors
- Relevant user roles as defined in user_roles.md

## Preconditions
- User authenticated with appropriate role
- System online or offline (offline-first capable)

## Postconditions
- All state changes logged to audit_logs
- Sync outbox updated for offline entries

## Error Handling
- Validation errors shown inline
- System errors logged and user notified
- Offline mode: operations queued in sync outbox

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial workflow documentation |

## --- FILE: tenant_setup.md ---

﻿# Workflow: tenant setup - LaundryPro UAE
> **Version:** 1.0.0

## Flow
Tenant setup: Generate UMAC license -> Install MSIX -> Run setup wizard -> Configure business profile -> Create admin user -> Setup branches -> Configure hardware -> Import service catalog -> Run test transaction -> Go live.

## Actors
- Relevant user roles as defined in user_roles.md

## Preconditions
- User authenticated with appropriate role
- System online or offline (offline-first capable)

## Postconditions
- All state changes logged to audit_logs
- Sync outbox updated for offline entries

## Error Handling
- Validation errors shown inline
- System errors logged and user notified
- Offline mode: operations queued in sync outbox

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial workflow documentation |

## --- FILE: ALGORITHMS_AND_FEATURE_REVIEW.md ---

﻿# LaundryPro UAE: Algorithms & Feature Review

## 1. Core Algorithms

### 1.1 Financial Precision Engine (`bcmath`)
All financial aggregations in the API strictly avoid native floating-point math to prevent IEEE-754 precision drift.

**Algorithm:**
1. Fetch lines from DB as `DECIMAL(18,2)` strings.
2. Initialize `grand_total = '0.00'`.
3. Loop lines:
   - `line_total = bcmul(qty_string, price_string, 2)`
   - `line_total = bcsub(line_total, discount_string, 2)`
   - `grand_total = bcadd(grand_total, line_total, 2)`
4. Apply VAT (5%):
   - `tax_amount = bcmul(grand_total, '0.05', 2)`
   - `final_grand_total = bcadd(grand_total, tax_amount, 2)`
5. Return JSON payload encapsulating values as strings.

### 1.2 Offline-First Sync Backoff Algorithm
When pushing local changes to the cloud from `sync_outbox`, network failures trigger an exponential backoff to preserve system resources.

**Algorithm:**
1. Daemon queries `SELECT * FROM sync_outbox WHERE status IN ('pending', 'failed') AND next_retry_at <= NOW() LIMIT 100`.
2. For each record, `POST` to cloud.
3. If `200 OK`, `UPDATE status = 'synced'`.
4. If Network Timeout or `5xx`:
   - `attempts = attempts + 1`
   - If `attempts > 10`: `status = 'dead_letter'`
   - Else: `delay = power(2, attempts) * 60` seconds.
   - `next_retry_at = NOW() + delay`

### 1.3 Inventory Concurrency Lock
To prevent negative inventory when two terminals sell the same product simultaneously.

**Algorithm:**
1. `BEGIN TRANSACTION;`
2. `SELECT qty_on_hand FROM products WHERE id = X FOR UPDATE;` (Locks row)
3. If `qty_on_hand - req_qty < 0`: Rollback & throw `InsufficientStockException`.
4. `UPDATE products SET qty_on_hand = qty_on_hand - req_qty;`
5. `INSERT INTO inventory_movements ...`
6. `COMMIT;` (Releases lock)

---

## 2. Feature Review & Screen Index

| UI Screen | Feature Set | State |
|---|---|---|
| **AppShell** | Navigation rail, localized RTL/LTR, sync status indicator, dynamic theming. | Production Ready |
| **Dashboard** | 60s auto-refresh, top KPIs, financial trend arrows, quick actions. | Production Ready |
| **POS Screen** | Barcode scanning integration, split payments panel, `bcmath` mirrored calculations. | Production Ready |
| **Catalog** | `AppDataTable` integration, 2000+ item pagination, image attachment mapping. | Production Ready |
| **Customers** | CRM tracking, outstanding balance calculations, WhatsApp quick-link integration. | Production Ready |
| **Peripherals** | Epson/Citizen thermal printer integration via ESC/POS protocol, cash drawer pulse testing. | Production Ready |
| **Shift Close** | Blind cash entry, variance calculation logic, forced Z-Report printing. | Production Ready |
| **Settings** | UI bindings to `system_settings` table, dynamic VAT adjustments, licensing UMAC verifications. | Production Ready |

### Final Readiness Assessment
The runtime features operate accurately. The frontend is fully decoupled from the backend state via offline repositories. All components meet strict deployment specifications.


## --- FILE: BLUEPRINT_WORKFLOWS_USE_CASES.md ---



## --- FILE: CLOSEOUT_CHECKLIST.md ---

# LaundryPro UAE — Final Closeout Checklist

**Version:** 1.2.1+4  
**Date:** 2026-09-05  
**Quality gate:** `powershell scripts\dev.ps1 gate`

## Consolidation

| Item | Status |
|------|--------|
| `001_baseline.sql` greenfield migration | Done |
| Incremental migrations archived | Done |
| `001_all_seeds.sql` + `run_dev_seed.php` | Done |
| `scripts/dev.ps1` unified CLI | Done |
| API tests → 4 phase suites (182 cases) | Done |
| Legacy DB baseline shim in MigrationService | Done |

## Test evidence

| Suite | Pass | Skip |
|-------|------|------|
| API (`run_api_tests.php`) | 173 | 9 |
| Flutter (`flutter test`) | 116 | 0 |
| OpenAPI routes | 148 | — |

## Phase gap audit

| Track | Status | Notes |
|-------|--------|-------|
| Phase 0 | VERIFIED | Platform + quality gate |
| Phase 1 | VERIFIED | CRM, catalog, POS, sales, sync local |
| Phase 1C | VERIFIED | License, backup verify/restore |
| Phase 2 | VERIFIED | Production, delivery, challans, purchasing, HR, payroll, expenses, reports, notifications |
| Phase 2 P2-13 | DEFERRED | Print template designer UI — peripheral template DB exists, no visual designer |
| Phase 3 | VERIFIED | Branches, terminals, LAN, analytics, KSA, channels, accounting, storefront, portal |
| CR-2026-09-02-001 | PARALLEL | Cloud scaffold; tenant tests optional (skip on 404) |
| CR-2026-09-05-002 | VERIFIED | Phase 3 completion |
| CR-2026-09-05-003 | VERIFIED | POS peripheral framework merge |
| POS hardware | VERIFIED | Print, scan, drawer; printer must be selected in Peripherals |

## Documentation synced

| Document | Updated |
|----------|---------|
| CR-2026-09-05-003.md | Yes |
| EDGE_CASES.md (AC-031..035) | Yes |
| QUALITY_GATE.md | Yes |
| api-contract.md | Yes |
| docs/peripherals/README.md | Yes |
| Roadmap (key sections) | Yes |

## Git closeout

- [x] Commit 1: `feat(peripherals): merge POS peripheral framework`
- [x] Commit 2: `chore: consolidate artifacts and sync v1.2.1 docs`
- [x] Quality gate green
- [x] `git push origin main` (`9a3eeb2`)

## Known optional skips (not blockers)

- Cloud tenant registration tests (cloud-api not on localhost)
- `p3_branch_create` / `p3_terminal_create` optional 500 in some envs
- MSIX build requires VS C++ ATL + `scripts/peripherals/stage_missing_dlls.ps1`


## --- FILE: DATABASE_ER_DIAGRAM.md ---

﻿# LaundryPro UAE: Database Entity-Relationship (ER) Diagram

This document defines the core relational data model underpinning the LaundryPro UAE offline-first system.

## Core Schema

```mermaid
erDiagram
    BUSINESS ||--o{ BRANCHES : "owns"
    BRANCHES ||--o{ TERMINALS : "contains"
    
    ROLES ||--o{ USERS : "defines permissions for"
    USERS ||--o{ REFRESH_TOKENS : "issues"
    USERS ||--o{ AUDIT_LOGS : "performs"
    
    CUSTOMERS ||--o{ SALES_ORDERS : "places"
    
    CATEGORIES ||--o{ SERVICES : "groups"
    SERVICES ||--o{ SERVICE_PRODUCT_MAP : "consumes"
    PRODUCTS ||--o{ SERVICE_PRODUCT_MAP : "is consumed by"
    
    SALES_ORDERS ||--o{ SALES_ORDER_LINES : "contains"
    SALES_ORDERS ||--o{ PAYMENT_TRANSACTIONS : "paid via"
    
    PRODUCTS ||--o{ INVENTORY_MOVEMENTS : "tracked by"
    VENDORS ||--o{ PURCHASE_ORDERS : "receives"
    PURCHASE_ORDERS ||--o{ INVENTORY_MOVEMENTS : "restocks via"
    
    TERMINALS ||--o{ SYNC_OUTBOX : "queues data to"
    SYNC_OUTBOX ||--o{ SYNC_STATE : "monitored by"
    
    BUSINESS {
        int id PK
        string name
        string trn
        boolean is_active
    }
    
    USERS {
        int id PK
        string uuid
        int role_id FK
        string username
        string password_hash
    }
    
    ROLES {
        int id PK
        string name
        json permissions
    }
    
    CUSTOMERS {
        int id PK
        string uuid
        string name
        string phone
        decimal outstanding_balance
    }
    
    SALES_ORDERS {
        int id PK
        string uuid
        int customer_id FK
        string status
        string payment_status
        decimal grand_total
        decimal balance_due
    }
    
    SALES_ORDER_LINES {
        int id PK
        int sales_order_id FK
        int service_id FK
        int quantity
        decimal unit_price
        decimal subtotal
    }
    
    PRODUCTS {
        int id PK
        string sku
        string name
        int qty_on_hand
        int reorder_point
    }
    
    INVENTORY_MOVEMENTS {
        int id PK
        int product_id FK
        string type
        int quantity_change
    }
    
    SYNC_OUTBOX {
        int id PK
        string entity_type
        string entity_uuid
        string action
        json payload
        string status
        int attempts
        timestamp next_retry_at
    }
```

## Design Constraints
- All primary keys (`id`) are unsigned integers auto-incremented for local database speed.
- All replicated tables possess a `uuid` `CHAR(36)` used as the global primary key when synchronizing to the central cloud.
- Monetary values (`grand_total`, `subtotal`, etc.) are STRICTLY typed as `DECIMAL(18,2)`.
- The `sync_outbox` acts as an event-store for the offline-first replication engine.


## --- FILE: MANUAL_ADMIN_SUPERADMIN_BOOK.md ---

﻿# LaundryPro UAE — Super-Admin & Cloud Portal Guide

**Document Version:** 2.0 (Production Release)  
**Target Audience:** Magnificent Solution System Administrators, Cloud Operators, Franchise IT Heads  

---

## Table of Contents
1. [Cloud Architecture & Security Overview](#1-cloud-architecture--security-overview)
2. [Accessing the Super-Admin Web Portal](#2-accessing-the-super-admin-web-portal)
3. [Dashboard Metrics & Operational Telemetry](#3-dashboard-metrics--operational-telemetry)
4. [Tenant & Client Laundry Node Management](#4-tenant--client-laundry-node-management)
5. [Cryptographic License Issuance & Management](#5-cryptographic-license-issuance--management)
6. [Offline License Request Processing (laundrypro_req.lic)](#6-offline-license-request-processing-laundrypro_reqlic)
7. [Remote Revocation & Kill-Switch](#7-remote-revocation--kill-switch)
8. [Real-time Sync Payload Stream Inspector](#8-real-time-sync-payload-stream-inspector)
9. [System Audit Trail & Security Logs](#9-system-audit-trail--security-logs)
10. [Database Backup & Maintenance](#10-database-backup--maintenance)
11. [Backup & Restore Procedures](#11-backup--restore-procedures)
12. [Rate Limiting & Security Monitoring](#12-rate-limiting--security-monitoring)
13. [Sync Engine Monitoring](#13-sync-engine-monitoring)
14. [RBAC Role Management](#14-rbac-role-management)
15. [Financial Precision Notes (bcmath)](#15-financial-precision-notes-bcmath)

---

## 1. Cloud Architecture & Security Overview

The Central Cloud API & Super-Admin Web Portal resides in cloud-api/ and is designed for standard cPanel shared hosting or Linux Apache servers:
- **Framework:** Pure PHP 8.2 with PDO MariaDB/MySQL.
- **Frontend UI:** AdminLTE v4 (Bootstrap 5, FontAwesome/Bootstrap Icons).
- **Public Root:** cloud-api/public/ (accessible via VirtualHost or sub-folder).
- **Database:** laundrypro_cloud.

---

## 2. Accessing the Super-Admin Web Portal

1. Navigate to:
   http://localhost/cloud-api/public/admin or http://cloud-api/admin  
   (Production URL: https://www.laundrypro-cloudapi.magnificentsolution.co.in/admin)
2. Enter your super-admin credentials:
   - **Username:** superadmin
   - **Password:** SuperAdmin@LaundryPro2026!
3. The session is protected by cryptographic cookie signatures and CSRF tokens.

---

## 3. Dashboard Metrics & Operational Telemetry

The executive dashboard displays:
- **Total Registered Tenants:** Count of laundry business nodes.
- **Active Licenses:** Count of valid, unexpired licenses.
- **Total Sync Events:** All-time ingested data records.
- **24-Hour Telemetry:** Pushes, orders, and pings received in the last 24 hours.
- **Recent Tenants Table:** Quick links to client profiles and activation statuses.

---

## 4. Tenant & Client Laundry Node Management

Navigate to **Tenants** in the sidebar:
1. **View Tenants:** View all registered laundry owners, trade license numbers, contact info, and node status.
2. **Cloud Tokens:** Each tenant has an auto-generated high-entropy Bearer token (	oken_...) used by their local XAMPP node for authentication.
3. **Status Control:** Toggle status between **Active**, **Suspended**, or **Archived**.

---

## 5. Cryptographic License Issuance & Management

Navigate to **Licenses** in the sidebar:
1. Click **Issue New License**.
2. Select the client **Tenant / Business**.
3. Choose Plan:
   - **Standard** (Full features, 1 year validity)
   - **Enterprise** (Multi-branch, unlimited terminals)
   - **Trial / Evaluation** (7 days, 9 invoices quota)
4. Enter target hardware **UMAC Code** (e.g., UMAC-8F2A-49C1-77B0).
5. Click **Generate License**.
6. The system generates a cryptographically signed license key:
   LP-1A2B3C4D-5E6F-7G8H
   which is returned to the client.

---

## 6. Offline License Request Processing (laundrypro_req.lic)

For client machines without internet access:
1. Client generates laundrypro_req.lic from the Flutter License Screen.
2. Client sends this file to Magnificent Solution support.
3. Super-Admin opens the License Generator, inputs the client details and hardware UMAC from the file.
4. Download the signed laundrypro_license.lic file and return it to the client.
5. Client imports the file into their desktop app to unlock permanent operation.

---

## 7. Remote Revocation & Kill-Switch

If a client terminates their contract or fails payment:
1. Navigate to **Licenses**.
2. Locate the client license and click **Revoke License**.
3. On the next cloud handshake (or sync attempt), the local node receives the revocation signal and locks POS transaction capabilities.

---

## 8. Real-time Sync Payload Stream Inspector

Navigate to **Sync Records** in the sidebar:
- Inspect inbound JSON payloads stream pushed by client workstations.
- Filter by Tenant, Entity Type (customer, sales_order, payment, expense).
- View exact timestamps, local record IDs, and payload snapshots for technical troubleshooting.

---

## 9. System Audit Trail & Security Logs

Navigate to **Audit Logs**:
- Every super-admin login, tenant creation, license issuance, and revocation is recorded with:
  - Admin User ID
  - Action Name
  - Timestamp
  - Client IP Address
  - Action Details

---

## 10. Database Backup & Maintenance

The cloud database laundrypro_cloud should be backed up using mysqldump:
`ash
mysqldump -u root -p laundrypro_cloud > laundrypro_cloud_backup_.sql
`

---

## 11. Backup & Restore Procedures

All system backups are executed via the local PHP API to ensure consistency.

1. **Creating a Backup:** 
   - A cron job or manual trigger calls POST /api/v1/backup/run.
   - The system executes mysqldump, packages the .sql file into a .zip, and generates a SHA-256 cryptographic manifest.
2. **Restoring a Backup:**
   - Call POST /api/v1/backup/restore.
   - The system unpacks the .zip, validates the SHA-256 signature against the manifest to prevent payload tampering, and overwrites the active database.
   - **Never manually restore a raw SQL dump** in a production environment as it bypasses the audit and integrity checks.

---

## 12. Rate Limiting & Security Monitoring

The RateLimitMiddleware protects all /auth/* endpoints against brute-force attacks using an IP-based sliding window throttle.

- **Rule:** Maximum 5 attempts per 1-minute window per IP.
- **Enforcement:** If exceeded, the API returns 429 Too Many Requests.
- **Monitoring:** Check the system_settings table for keys prefixed with 
ate_limit:. These keys store the hit count and expiry timestamp. Admins can manually clear these rows if a legitimate terminal is locked out.

---

## 13. Sync Engine Monitoring

The offline-first sync engine relies on the sync_outbox table and the SyncService background daemon.

- **Monitoring:** Call GET /api/v1/sync/status to check the outbox depth.
- **Outbox States:**
  - pending: Record is queued for the next push cycle.
  - synced: Record successfully received by the cloud.
  - ailed: Push failed. The engine applies an exponential backoff (up to 10 attempts) before parking the record.
- **Alerts:** Set up a monitoring threshold. If pending records exceed 500, or if any record is stuck in ailed for more than 24 hours, an alert should be dispatched to the IT team.

---

## 14. RBAC Role Management

The system uses granular Role-Based Access Control (RBAC). Roles are strictly defined in the 
oles and 
ole_permissions tables.

- **Creating Roles:** Use the **Role Editor Screen** in the Flutter UI or POST /api/v1/roles to create custom roles (e.g., "Junior Cashier", "Inventory Manager").
- **Granular Permissions:** Permissions follow the 
esource.action convention (e.g., sales.read, sales.write, catalog.write, users.manage).
- **Enforcement:** All permissions are validated server-side by the PHP controllers using the JWT payload claims.

---

## 15. Financial Precision Notes (bcmath)

**CRITICAL:** LaundryPro UAE entirely forbids the use of native PHP floating-point numbers (loat / double) for monetary calculations.

- **Why?** Native floats introduce precision loss (e.g.,  .1 + 0.2 = 0.30000000000000004), which compounds into massive discrepancies over thousands of sales and tax calculations.
- **The Standard:** All monetary values are strictly cast to DECIMAL(18,2) in MariaDB and transported as **strings** in JSON payloads.
- **PHP Calculations:** Whenever the API must perform math (e.g., tax calculation, discounts), it strictly uses the cmath extension (cadd, csub, cmul, cdiv) with a scale of 2.
- **Admin Action:** Ensure extension=bcmath is enabled in php.ini on all edge terminals. If disabled, the API will crash on any financial mutation.



## --- FILE: MANUAL_OPERATOR_BOOK.md ---

# LaundryPro UAE — Operator & Cashier User Manual

**Document Version:** 2.1 (Production Release)
**Product Version:** 1.2.1+4
**Target Audience:** Front-desk Cashiers, Store Operators, Laundry Floor Staff, Delivery Drivers

---

## Table of Contents
1. [Starting the Application](#1-starting-the-application)
2. [Splash Screen & Self-Healing Boot](#2-splash-screen--self-healing-boot)
3. [Logging In & Profile Switching](#3-logging-in--profile-switching)
4. [Instant Sale / Counter Point of Sale (POS)](#4-instant-sale--counter-point-of-sale-pos)
5. [Customer CRM & Walk-In Customers](#5-customer-crm--walk-in-customers)
6. [Thermal Receipt Printing & Cash Drawer](#6-thermal-receipt-printing--cash-drawer)
7. [Order Tracking & Processing Movement](#7-order-tracking--processing-movement)
8. [Factory Challans & Delivery Tasks](#8-factory-challans--delivery-tasks)
9. [Staff Attendance Clock-In / Clock-Out](#9-staff-attendance-clock-in--clock-out)
10. [End of Day Closing & Reports](#10-end-of-day-closing--reports)
11. [Offline Resilience & Recovery](#11-offline-resilience--recovery)
12. [Split Payments (Multi-Tender)](#12-split-payments-multi-tender)
13. [Hold & Resume Sales](#13-hold--resume-sales)
14. [Refunds & Correction Memos](#14-refunds--correction-memos)
15. [Keyboard Shortcuts](#15-keyboard-shortcuts)
16. [WhatsApp Receipt Sharing](#16-whatsapp-receipt-sharing)

---

## 1. Starting the Application

Launch LaundryPro UAE from your Windows Desktop shortcut or executable:

`
build\\windows\\x64\\runner\\Release\\laundrypro_uae.exe
`

Ensure that XAMPP (Apache and MySQL) is running on the computer before launching.

---

## 2. Splash Screen & Self-Healing Boot

When the program opens, a modern splash screen validates the system environment:

1. **Verifying Local Node Connectivity:** Checks if the local database and local web server are active.
   - *If offline:* The screen clearly displays: *Unable to connect to local database engine. Please verify XAMPP is running.* You can click **Retry** or **Exit Application**.
2. **Applying Database Upgrades:** Silently checks for pending database migrations and executes them automatically without operator intervention.
3. **Evaluating License & Machine ID:** Checks hardware UMAC and active license quotas.
4. **Cloud Background Handshake:** In the background, contacts the central cloud server to check for sync updates (never blocks offline usage).
5. **Dashboard Transition:** Opens the Login screen smoothly.

---

## 3. Logging In & Profile Switching

1. Enter your operator username and password:
   - **Default Admin:** dmin / dmin123
   - Passwords are case-sensitive. Contact your system administrator if locked out.
2. Select your preferred language:
   - **English (LTR)** or **العربية (Arabic RTL)**.
   - You can toggle language at any time from the top navigation bar.
3. To switch operator profiles mid-shift, click your name avatar in the top-right corner and select **Switch User** without closing the application.

---

## 4. Instant Sale / Counter Point of Sale (POS)

The POS interface is optimised for keyboard, mouse, and touchscreen operation:

1. **Select or Scan Customer:**
   - Use the Customer Search bar (by phone number, name, or code) or click **Walk-in Customer**.
2. **Add Laundry Items:**
   - Tap category buttons (Dry Clean, Wash & Fold, Steam Press, Curtain Care).
   - Click services or scan item barcodes.
   - Adjust quantities using the on-screen keypad (+ / -).
3. **Apply Modifiers & Urgency:**
   - Express Service (+50%), Fragrance, Stiff Starch, Stain Treatment.
4. **Collect Payment:**
   - Choose Payment Method: **Cash**, **Card / Terminal**, **Credit (Account)**, or **Split** (see Section 12).
   - If paying Cash, enter tender amount; the system calculates exact change in AED & Fils.
5. **Finalize Order:**
   - Click **Confirm & Print**. The thermal receipt prints immediately and the cash drawer kicks open.

---

## 5. Customer CRM & Walk-In Customers

1. Navigate to **Customers** on the left navigation rail.
2. Click **New Customer** (F2):
   - Enter Full Name, UAE Mobile Number (+971 50 ...), TRN (if corporate), Delivery Address, Villa/Flat No.
3. View order history, unpaid ledger balances, and loyalty points.

---

## 6. Thermal Receipt Printing & Cash Drawer

- **Printer Models Supported:** Standard 80 mm and 58 mm ESC/POS thermal receipt printers (Epson, Citizen, Bixolon, Xprinter).
- **Cash Drawer:** Automatically pops open via RJ11 pulse on cash transactions.
- **Reprint Receipt:** Open any past order and click **Reprint Receipt** (Ctrl+P).
- **Test Print:** Navigate to **Settings > Peripherals > Test Print** to verify printer alignment.

---

## 7. Order Tracking & Processing Movement

Track order progress through 4 standard stages:

1. **Received (Counter):** Items tagged and bagged.
2. **In Processing (Washing/Dry Cleaning):** Items in wash or dry clean cycle.
3. **Ready for Pickup / Delivery:** Ironed, packaged, and inspected by QC.
4. **Delivered / Completed:** Customer collected or driver delivered.

Status changes are logged with operator name and timestamp for full auditability.

---

## 8. Factory Challans & Delivery Tasks

- **Challans:** For laundries with an off-site central factory, generate a batch transfer Challan with line counts and barcodes for the transport driver.
- **Home Deliveries:** View scheduled deliveries, assign to drivers, and mark completed upon drop-off.

---

## 9. Staff Attendance Clock-In / Clock-Out

1. Navigate to **HR & Attendance**.
2. Staff member selects their profile or scans their employee barcode badge.
3. Tap **Clock In** at the start of shift and **Clock Out** at the end of shift.
4. Records are automatically compiled for monthly UAE Labour Law compliant payroll.

---

## 10. End of Day Closing & Reports

At the end of your shift:
1. Navigate to **Reports** > **Daily Sales Summary**.
2. Verify:
   - Total Cash in Drawer
   - Total Card Payments
   - Total Outstanding Invoices
3. Print the **Shift End / Z-Report** for the store manager.
4. For full shift reconciliation with variance logging, see Section 13: Hold & Resume Sales actually see Shift Close (UC-13 in Blueprint).

---

## 11. Offline Resilience & Recovery

- **Zero Cloud Dependence:** You can continue booking orders, printing receipts, and collecting payments even if the internet is completely disconnected.
- When internet returns, the background sync engine seamlessly uploads records to the central cloud.
- The status bar at the bottom of every screen shows a **Sync Status** indicator:
  - Green dot: All records synced.
  - Amber dot: Pending records in outbox (syncing shortly).
  - Red dot: Offline; records queued locally.

---

## 12. Split Payments (Multi-Tender)

Use Split Payment when a customer wants to settle an invoice with more than one payment method (e.g., part cash, part card).

**Steps:**

1. Build the cart and proceed to **Checkout** as normal.
2. Instead of selecting a single payment method, click **Split Payment**.
3. The Split Payment panel opens showing the full invoice total.
4. Enter the **Cash amount** the customer is paying (e.g., 100.00 AED).
   - The panel automatically shows the **Remaining Balance** (e.g., 110.00 AED).
5. Select the second method for the remaining balance: **Card / Terminal**, **Credit (Account)**, or a third split.
6. For Card: confirm the physical terminal has approved the charge, then click **Card Approved**.
7. Verify the running total matches the invoice total (the **Finalize** button only activates when fully balanced).
8. Click **Finalize Split Payment**.
9. A **single consolidated receipt** prints listing all payment legs.
10. The cash drawer opens only if a cash leg was included.

> **Note:** Change is only calculated and given on the **cash leg**. Card and account legs must be exact amounts.

---

## 13. Hold & Resume Sales

Hold an in-progress cart without losing its contents — useful when a customer needs to step aside or fetch more items.

**To Hold a Sale:**

1. While on the active cart screen, press **Ctrl+H** or click the **Hold Cart** icon (pause symbol) in the toolbar.
2. Enter an optional **Hold Note** (e.g., “customer fetching more garments”).
3. Click **Hold**. The cart is saved and the POS clears to accept a new customer.

**To Resume a Held Sale:**

1. Click the **Held Orders** tray icon in the top navigation bar (shows count badge).
2. Select the held cart from the list.
3. Click **Resume** — the cart reloads with all items, customer details, and modifiers intact.
4. Continue checkout as normal.

> **Important:** Held carts do not generate an invoice or reserve stock. They are session-level holds. If the application is closed, held carts are discarded.

---

## 14. Refunds & Correction Memos

LaundryPro UAE never modifies or deletes an original invoice. All refunds and corrections are handled through a **Correction Memo** (Credit Memo) that links back to the original order.

**Steps to Issue a Correction Memo:**

1. Navigate to **Orders** and search for the original order by number, customer name, or date.
2. Open the order detail view.
3. Click **Issue Correction Memo** (requires Manager role or above).
4. In the dialog:
   - Select the line items to refund (full or partial lines).
   - Enter the **refund reason** (mandatory field).
   - Choose the **refund method**: Cash Return, Account Credit, or Voucher.
5. Click **Confirm Memo**.
6. The system creates a **Credit Memo** (e.g., #CM-2026-00019) with a negative total referencing the original order.
7. A **Correction Memo receipt** prints automatically, clearly headed:

   `
   CORRECTION MEMO — NOT AN INVOICE
   Ref. Original Order: LP-2026-00109
   `

8. Return cash to the customer or apply the credit to their account.

> **Key Rules:**
> - The original invoice remains unchanged and visible in history.
> - Only managers and above can issue correction memos.
> - Partial refunds are allowed; you cannot refund more than the original line quantity.

---

## 15. Keyboard Shortcuts

Keyboard shortcuts accelerate high-volume counter operations. All shortcuts are active when the POS or Orders screen is in focus.

| Shortcut | Action |
|---|---|
| **F1** | Open Help / This Manual |
| **F2** | New Customer |
| **F3** | Customer Search |
| **F4** | New Order / Open Cart |
| **F5** | Refresh Current Screen |
| **F6** | Apply Express (+50%) modifier to selected line |
| **F8** | Void / Remove selected cart line |
| **F9** | Open Cash Drawer (manual pulse) |
| **F10** | Proceed to Checkout |
| **F11** | Toggle Full-Screen Mode |
| **F12** | Reprint Last Receipt |
| **Ctrl+H** | Hold Current Cart |
| **Ctrl+P** | Print / Reprint Receipt |
| **Ctrl+R** | Open Refund / Correction Memo |
| **Ctrl+Z** | Undo Last Item Add (cart only) |
| **Ctrl+S** | Save Draft (hold cart silently) |
| **Ctrl+Shift+S** | Shift Close Screen |
| **Ctrl+W** | Send WhatsApp Receipt (see Section 16) |
| **Escape** | Cancel current dialog / close panel |
| **Enter** | Confirm active dialog / proceed |
| **+** / **-** | Increase / Decrease selected item quantity |
| **Numpad 0–9** | Quick quantity entry on focused line |

---

## 16. WhatsApp Receipt Sharing

Send a digital receipt directly to the customer\'s WhatsApp number immediately after payment.

**After completing a sale:**

1. The post-payment confirmation screen shows a **Send WhatsApp Receipt** button (or press **Ctrl+W**).
2. Verify the customer\'s UAE mobile number displayed (pre-filled from the customer record).
3. Click **Send via WhatsApp**.
4. The system constructs a WhatsApp deep-link with the receipt summary pre-filled in the message body:
   `
   https://wa.me/971501234567?text=LaundryPro+UAE+Receipt+%23LP-2026-00109...
   `
5. Windows opens the WhatsApp Desktop app (or WhatsApp Web in browser).
6. Review the pre-filled message and click **Send** in WhatsApp.

**To share a receipt for a past order:**

1. Open the order in **Orders > Order Detail**.
2. Click the **WhatsApp** icon in the action bar.
3. Follow steps 2–6 above.

> **Note:** WhatsApp sharing uses the standard wa.me deep-link protocol and requires WhatsApp Desktop or WhatsApp Web to be installed and logged in on the workstation. An active internet connection is required for WhatsApp delivery; the local POS operates fully without it.
