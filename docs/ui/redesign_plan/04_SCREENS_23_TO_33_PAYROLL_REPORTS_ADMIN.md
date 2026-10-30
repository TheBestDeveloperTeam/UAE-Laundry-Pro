# LaundryPro UAE — Screen-by-Screen Zero-Loss Re-Architecture Specifications
## Modules 23 through 33 (Payroll, Analytics, Reports, Multi-Branch & System Admin)

---

### 5.23 UAE WPS Payroll Generator (`lib/views/payroll_screen.dart`)

Generates compliant Salary Information Files (SIF) for the UAE Wage Protection System (WPS) under Central Bank / MOHRE regulations.

```
┌────────────────────────────────────────────────────────────────────────┐
│ UAE WPS Payroll Generator                  [ Generate SIF ] [ Disburse ]│
├────────────────────────────────────────────────────────────────────────┤
│ Month: October 2026   Branch: ALL   Status: DRAFT   Total: AED 38,450  │
├────────────────────────────────────────────────────────────────────────┤
│ EMP ID   NAME         BASIC  ALLOWANCES OVERTIME DEDUCTIONS NET PAY    │
│ EMP-0101 M. Arif      2,200   1,000      240.00    -100.00   3,340.00  │
│ EMP-0102 S. Sharma    2,000     800      120.00       0.00   2,920.00  │
│ EMP-0103 J. Mwangi    2,100     900      350.00     -50.00   3,300.00  │
│ EMP-0104 B. Tanveer   1,800     700      180.00       0.00   2,680.00  │
└────────────────────────────────────────────────────────────────────────┘
```

#### Detailed Architecture & State Specifications
1. **MOHRE Employer & Routing Setup:**
   - Validates Employer Unique ID (13 digits), Bank Routing Code, and Employee IBAN strings.
2. **SIF Text File Generator:**
   - Produces formatted `.SIF` electronic payroll submission file.
3. **Salary Slip Generation:**
   - Formatted dual-language Arabic/English salary payslips exportable to PDF.

---

### 5.24 Staff Salary Advances & Loans (`lib/views/salary_advances_screen.dart`)

Employee micro-advances, emergency loans, and monthly payroll deduction amortization.

#### Detailed Architecture & State Specifications
1. **Loan Ledger Table:**
   - Employee Name, Total Advance Amount, Monthly Installment, Remaining Balance, Repayment Progress Bar.
2. **New Advance Request Dialog:**
   - Validates requested advance against employee's monthly basic salary cap (e.g. maximum 50%).

---

### 5.25 Analytical Business Intelligence (`lib/views/analytics_screen.dart`)

Deep operational metrics, revenue trajectories, customer churn risk, and garment type profitability.

```
┌────────────────────────────────────────────────────────────────────────┐
│ Business Intelligence & Operational Insights  [ Range: Last 30 Days v ]│
├───────────────────────────────────┬────────────────────────────────────┤
│ Revenue by Service Category       │ Customer Cohort Retention          │
│ [Donut Chart]                     │ [Bar Chart: Return vs First-Time]  │
│ - Dry Clean:     42% (AED 34,200) │ - Returning:   68% (1,420 orders)  │
│ - Wash & Iron:   35% (AED 28,500) │ - First-time:  32% (670 orders)    │
│ - Steam Press:   15% (AED 12,200) │                                    │
│ - Abaya Special:  8% (AED  6,520) │ Avg Order Value:         AED 38.40 │
├───────────────────────────────────┴────────────────────────────────────┤
│ Hourly Intake & Dispatch Heatmap                                       │
│ [ 8 AM - 10 PM Distribution Matrix: Peak Hours: 9-11 AM & 6-9 PM ]     │
└────────────────────────────────────────────────────────────────────────┘
```

#### Detailed Architecture & State Specifications
1. **Interactive Visualizations:**
   - Clean vector Donut Chart for Service Split.
   - Cohort Retention Bar Chart.
   - Peak Hour Intake Heatmap matrix.
2. **Export Capabilities:**
   - One-click export to CSV / Excel or formatted PDF Executive Summary.

---

### 5.26 Compliance & FTA VAT Reports (`lib/views/reports_screen.dart`)

Tax reporting, audit trails, and financial statements complying with UAE FTA regulations.

```
┌────────────────────────────────────────────────────────────────────────┐
│ FTA VAT Return (Box 1a) & Operational Reports   [ Period: Q3 2026 v ]  │
├───────────────────────────────────┬────────────────────────────────────┤
│ FTA Form 201 VAT Summary          │ Standard Operations Reports        │
│ Box 1a: Standard Rated Supplies:  │ • Daily Cash Drawer Reconciliation │
│         AED 285,400.00            │ • Driver Cash Collection Summary   │
│ Box 1b: Output VAT Due (5%):      │ • Voided & Discounted Orders Audit │
│         AED  14,270.00            │ • Machine Chemical Consumption     │
│ Box 9:  Recoverable Input VAT:    │ • Unclaimed Garments Aging (>90d)  │
│         AED   2,840.00            │                                    │
│ Net VAT Payable to FTA:           │ [ Generate Audit File (FAFT) ]     │
│         AED  11,430.00            │ [ Export Official VAT Return ]     │
└───────────────────────────────────┴────────────────────────────────────┘
```

#### Detailed Architecture & State Specifications
1. **FTA Form 201 VAT Return Generator:**
   - Automatically computes Box 1a (Gross Standard Rated Sales), Output VAT, Recoverable Input VAT, and Net VAT Due.
2. **Federal Audit File (FAFT):**
   - Generates FTA-standard FAFT text audit file for tax authority audits.
3. **Cash Drawer Balancing Sheet:**
   - Shift opening float vs drawer actuals vs credit card machine settlement discrepancy reconciliation.

---

### 5.27 Multi-Branch Enterprise Console (`lib/views/branches_screen.dart`)

Central management of multiple store branches across Emirates (Dubai, Abu Dhabi, Sharjah).

#### Detailed Architecture & State Specifications
1. **Branch List Table:**
   - Branch Code (`DXB-01`, `SHJ-01`), Branch Name, Address, TRN Number, Contact Phone, Assigned Terminals Count, Status (`Active` / `Inactive`).
2. **Branch Switching & Isolation:**
   - Enforces strict data tenancy by branch while allowing head office consolidation.

---

### 5.28 Workstation Terminals & Peripheral Bindings (`lib/views/terminals_screen.dart`)

Hardware mapping for each physical PC or touch terminal.

#### Detailed Architecture & State Specifications
1. **Terminal Register:**
   - Terminal Code (`T01`, `T02`), Branch, Assigned Windows Hostname, Dedicated Cash Drawer ID, Default ESC/POS Printer, Direct COM Port Barcode Reader.
2. **Terminal Licensing & Machine Binding:**
   - Displays UMAC machine address and local activation certificate status.

---

### 5.29 Multi-Channel Online Ingestion (`lib/views/channels_screen.dart`)

Aggregates orders from external WhatsApp bots, mobile apps, and third-party delivery platforms.

#### Detailed Architecture & State Specifications
1. **Channel Status Dashboard:**
   - Ingestion channels: `WhatsApp Business API`, `Customer Mobile App`, `Web Ordering Portal`, `Partner Aggregators`.
2. **Incoming Webhook Feed:**
   - Live stream of inbound digital order requests with Accept/Reject counter workflow.

---

### 5.30 Online Storefront Customizer (`lib/views/storefront_screen.dart`)

Branding, digital price lists, and customer delivery scheduling slots for the web/app storefront.

#### Detailed Architecture & State Specifications
1. **Storefront Configurator:**
   - Store Logo upload, Banner colors, Operating hours, Minimum order amount for free delivery, Delivery zone polygon mapping.

---

### 5.31 Role-Based Access Control Editor (`lib/views/role_editor_screen.dart`)

Granular security permissions for Cashiers, Washers, Pressers, Drivers, Managers, and System Admins.

```
┌────────────────────────────────────────────────────────────────────────┐
│ Role Permissions Matrix                       [ Save Matrix ] [ Reset ]│
├───────────────────┬──────────────┬─────────────┬───────────┬───────────┤
│ PERMISSION KEY    │ CASHIER      │ OPERATOR    │ DRIVER    │ MANAGER   │
├───────────────────┼──────────────┼─────────────┼───────────┼───────────┤
│ sales.create_order│  [x] Allow   │  [ ] Deny   │ [ ] Deny  │ [x] Allow │
│ sales.apply_disc  │  [ ] Deny    │  [ ] Deny   │ [ ] Deny  │ [x] Allow │
│ sales.void_order  │  [ ] Deny    │  [ ] Deny   │ [ ] Deny  │ [x] Allow │
│ production.advance│  [ ] Deny    │  [x] Allow  │ [ ] Deny  │ [x] Allow │
│ reports.view_vat  │  [ ] Deny    │  [ ] Deny   │ [ ] Deny  │ [x] Allow │
│ hr.view_payroll   │  [ ] Deny    │  [ ] Deny   │ [ ] Deny  │ [x] Allow │
└───────────────────┴──────────────┴─────────────┴───────────┴───────────┘
```

#### Detailed Architecture & State Specifications
1. **Interactive Checkbox Matrix:**
   - Over 45 granular capability keys covering Sales, Catalog, Inventory, Production, Financials, HR, and System Admin.
2. **Immediate Session Invalidation:**
   - Changes take effect instantaneously across local user sessions.

---

### 5.32 Hardware & Peripherals Workbench (`lib/views/peripherals_screen.dart`)

Diagnostic and testing ground for thermal printers, pole displays, barcode readers, and weighing scales.

#### Detailed Architecture & State Specifications
1. **Thermal Receipt Printer Configuration:**
   - Interface: Direct USB, Windows Print Spooler, Network TCP/IP, or RS-232 Serial COM.
   - Code page configuration: Arabic CP720 / CP864 / ESC/POS raster print mode.
   - Live Test Button: Prints bilingual test receipt with LaundryPro logo.
2. **Barcode / 2D QR Scanner:**
   - Character encoding, prefix/suffix carriage return testing window.
3. **Electronic Weighing Scale:**
   - Live weight reading gauge for bulk laundry kilo intake (reads continuous RS-232 / USB HID stream).

---

### 5.33 System Settings, Business Profile & Licensing
(`lib/views/settings_screen.dart`, `lib/views/business_screen.dart`, `lib/views/license_screen.dart`)

Core platform configuration.

#### Detailed Architecture & State Specifications
1. **Business Profile (`business_screen.dart`):**
   - Registered Business Legal Name (English & Arabic), Federal TRN (15 digits), Trade License Number, Registered Address, Phone, Website, Logo Upload.
2. **License & UMAC Activation (`license_screen.dart`):**
   - Displays Hardware Machine ID (`UMAC-1FA2-E8CA-5835`), License Status (`Active Enterprise Edition`), Expiration Date, Offline License Import/Export (.lic file transfer).
3. **General Settings (`settings_screen.dart`):**
   - Default Currency Symbol (`AED`), Number of decimal places (2), Order number prefix (`LP-`), Default tax rate (5%), Automatic invoice printing on settlement toggle.

