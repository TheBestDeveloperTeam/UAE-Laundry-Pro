# Magnificent Solution – Local Laundry Services Management System

## Comprehensive Technical Documentation

**Project Name:** LaundryPro UAE

**Client:** UAE Local Laundry Service MSME Vendor

**Initial Area:** Dubai, extendable to all UAE Emirates and KSA

**Developed and Maintained by:** Magnificent Solution

**Document Version:** 1.0

**Date:** [Current Date]

---

## Table of Contents

1. Executive Summary
2. Project Overview
3. Requirements Specification (RFP & BRD)
4. Scope of Work (SOW)
5. Entity Relationship Model
6. Use Cases
7. Technical Blueprint
8. Algorithms & Business Logic
9. Workflow Descriptions
10. Feature List
11. Scalable & Reliable Coding Guidelines
12. Appendices

---

## 1. Executive Summary

The **LaundryPro UAE** system is a comprehensive, standalone desktop application designed to manage all aspects of a local laundry service business. Built with Flutter for Windows, it leverages a local MySQL/MariaDB database via a PHP-based local API layer, ensuring offline capabilities, data privacy, and full control. The system integrates hardware peripherals (scanner, thermal/inkjet/dot-matrix printers, cash drawer) and offers multilingual support (English/Arabic with LTR/RTL layouts), multi-currency handling, and extensive modules for services, products, customers, vendors, HR, inventory, and billing.

The solution is tailored for MSME laundry vendors in the UAE, starting with Dubai and designed to scale across all emirates and eventually KSA. It emphasizes instant sales, product and service inventory management, license control with UMAC, and robust backup/disaster recovery mechanisms.

---

## 2. Project Overview

### 2.1 Objective

Develop a feature-rich, user-friendly, and reliable desktop application to manage daily laundry operations, including:

- Service and product catalog with hierarchical groupings and modifiers.
- Customer and vendor management.
- Point-of-sale (POS) with instant invoicing, credit/debit/cash payment tracking.
- Inventory receiving, adjustments, and stock control.
- Human resource management (attendance, payroll, leaves, advances).
- Expense tracking and vendor purchases.
- Reporting and printing with customizable formats.
- License management tied to physical address and UMAC controls.
- Multilingual and multi-currency support.
- Hardware integration for barcode scanning, printing, and cash management.

### 2.2 Target Users

- **Owner/Manager:** Access to all modules, reports, and configurations.
- **Front-desk staff:** POS, customer interactions, service status updates.
- **Production staff:** Service processing, status updates.
- **Accountant/HR:** Payroll, expenses, vendor payments.

### 2.3 Key Differentiators

- **Not a generic website:** Custom UI designed for high-efficiency desktop use with large touch targets, keyboard shortcuts, and scanner-optimized workflows.
- **Flavors Configuration:** Customizable sales workflows and screens based on business type (e.g., laundry-only, dry-cleaning, mixed).
- **UMAC Controls:** Unique Machine Access Code combined with physical address lock to prevent unauthorized use.
- **Offline-first:** Fully functional without internet; local API and database ensure data sovereignty.
- **Scalable:** Architecture supports multiple branches and future cloud sync if needed.

---

## 3. Requirements Specification (RFP & BRD)

### 3.1 Functional Requirements

#### 3.1.1 Authentication & Security

- OAuth 2.0 with JWT tokens for local API authentication.
- Role-based access control (RBAC) with configurable permissions.
- User accounts with hashed passwords and session timeout.
- UMAC (Unique Machine Access Code) binding to physical address and license duration.
- Audit logs for all critical operations.

#### 3.1.2 Service Management

- CRUD operations for service types (e.g., Dry-Clean, Wash, Iron Normal, Steam Iron, Steam Wash).
- Many-to-many relationships between services and products.
- Grouping of multiple services into a single sellable grouped service.
- Modifiers for services (e.g., extra starch, fragrance).
- Service categories with unlimited hierarchical nesting (self-inheritance).

#### 3.1.3 Product Management

- CRUD operations for product types (e.g., Shirt, Trouser, Pant, etc.).
- Many-to-many relationships between services and products.
- Grouping of multiple products into a single sellable grouped product.
- Product modifiers (e.g., size, color, fabric type).
- Product categories with unlimited hierarchical nesting.

#### 3.1.4 Inventory Management

- Stock receiving for products (purchase orders, manual entries).
- Stock adjustments (damage, loss, correction).
- Real-time stock levels with alerts for low stock.
- Barcode generation and scanning for products.
- Vendor purchases linked to inventory.

#### 3.1.5 Customer & Vendor Management

- Customer master with personal, professional, and location details.
- Vendor master with similar fields.
- History of transactions, invoices, and payments for each party.
- Credit limits and outstanding balances tracking.

#### 3.1.6 Point of Sale (POS)

- Instant sales entry with cash/credit/debit options.
- Cash credit memo format: SrNo, Description, Qty, Rate, Amount.
- Support for pending invoices and partial payments.
- Multi-currency display according to setup (AED with fils, later extendable to INR.paise, USD.cent).
- Quick item lookup via scanner or search.
- Discounts, taxes, and surcharges.
- Hold and recall invoices.
- Print invoice to thermal/inkjet/dot-matrix printers with customizable templates.
- Share invoice receipt via social media or email (as PDF/image).

#### 3.1.7 Service Workflow & Status

- Order statuses: Received, In Process, Ready for Delivery, Delivered, Cancelled.
- Notifications and alerts for pending services.
- Delivery challans and receipts.
- Assignment to employees for processing.

#### 3.1.8 Human Resource Management

- Employee master with personal and professional info.
- Attendance tracking (manual or time-based).
- Leave management (types, approvals, balances).
- Payroll generation (salary calculations, deductions, advances).
- Advance salary payments with recovery tracking.
- Expense management (utilities, rent, maintenance, etc.).

#### 3.1.9 Reporting & Analytics

- Daily sales reports, service-wise, product-wise.
- Inventory reports (stock levels, movement).
- Customer outstanding and aging reports.
- Employee attendance and payroll reports.
- Expense and profit/loss reports.
- Customizable report formats and export to PDF/Excel.

#### 3.1.10 License & UMAC Control

- License key with duration (e.g., monthly, annual).
- Binding to a unique physical address (MAC address, CPU ID, etc.).
- UMAC (Unique Machine Access Code) validation on every launch.
- Grace period for renewals.
- Remote deactivation capability (future).

#### 3.1.11 Local File Management

- Storage for invoice PDFs, product/service images, and other documents.
- Organized folder structure with automatic naming.
- Local import/export of data (CSV, JSON, SQL dumps).
- Auto-backup at scheduled intervals.
- Disaster recovery: automatic detection of database corruption and restore from last good backup.

#### 3.1.12 Hardware Integration

- Hand-held scanner: support all brands via HID (keyboard wedge) or serial interface.
- Thermal printer: ESC/POS commands for 80mm/58mm receipts.
- Inkjet/Dot-matrix printers: standard Windows printing with custom templates.
- Cash drawer: trigger via printer or dedicated port.
- Touch screen: UI designed for finger-friendly operation.

#### 3.1.13 Multilingual & Orientation

- Static labels and validation messages controlled via JSON files.
- Support for English (LTR) and Arabic (RTL).
- Entire UI layout flips based on selected language.
- Ability to add more languages by adding JSON files.

### 3.2 Non-Functional Requirements

- **Performance:** Response time < 500ms for local operations; handle 10,000+ invoices without degradation.
- **Reliability:** 99.9% uptime in local environment; automatic recovery from crashes.
- **Usability:** Minimal training required for staff; intuitive workflows.
- **Scalability:** Modular architecture to add branches or multi-store in future.
- **Security:** Encrypted local database connections; secure storage of passwords; UMAC enforcement.
- **Portability:** Runs on Windows 10/11; future port to macOS/Linux possible due to Flutter.

### 3.3 Constraints

- No internet dependency for core operations.
- Must work with XAMPP (Apache + MySQL/MariaDB) as local server.
- Initial setup only once; currency fixed at AED with fils.
- Data stored locally; no cloud sync initially.

---

## 4. Scope of Work (SOW)

The scope includes:

1. **Design & Prototyping:**
   - UI/UX design for all modules.
   - High-fidelity mockups for POS, dashboard, management screens.
   - Responsive layouts for 4:3 and 16:9 screens.

2. **Backend Development:**
   - PHP RESTful API with OAuth2.0 and JWT.
   - MySQL/MariaDB schema design.
   - CRUD endpoints for all entities.
   - Authentication and authorization middleware.
   - File upload/download endpoints.
   - Backup and restore scripts.
   - Swagger documentation.

3. **Frontend Development (Flutter):**
   - Windows desktop application.
   - State management (Provider/Riverpod).
   - MVVM architecture.
   - Integration with local API via HTTP.
   - Multi-language support (JSON resource files).
   - Hardware interfaces (scanner, printers, cash drawer).
   - PDF generation for invoices/reports.
   - Social media sharing.
   - Auto-update mechanism (optional).

4. **Testing:**
   - Unit tests for core logic.
   - Integration tests for API and DB.
   - User acceptance testing (UAT) with sample data.
   - Performance testing.

5. **Deployment & Training:**
   - Installation package creation (MSI/EXE).
   - Setup script for XAMPP and database.
   - User manual and training videos.
   - On-site or remote training sessions.

6. **Post-Deployment Support:**
   - 30 days bug fixing.
   - 1 year maintenance (optional contract).
   - Remote troubleshooting.

**Deliverables:**
- Source code (Flutter & PHP).
- Database schema and seed data.
- Installation package.
- User documentation.
- API documentation (Swagger).
- Training materials.

**Out of Scope:**
- Payment gateway integration.
- Multi-store/cloud synchronization (future).
- Mobile app (future).
- Real-time foreign exchange rates.

---

## 5. Entity Relationship Model

### 5.1 Tables

#### 5.1.1 `users`
- id (PK)
- username
- password_hash
- role_id (FK)
- employee_id (FK, nullable)
- active
- created_at, updated_at

#### 5.1.2 `roles`
- id (PK)
- name
- permissions (JSON)

#### 5.1.3 `employees`
- id (PK)
- name
- phone
- address
- joining_date
- salary_basis
- active

#### 5.1.4 `customers`
- id (PK)
- name
- phone
- email
- address (multiple? use separate table)
- type (personal/professional)
- credit_limit
- outstanding_balance
- created_at

#### 5.1.5 `vendors`
- id (PK)
- name
- contact_person
- phone
- email
- address
- tax_id

#### 5.1.6 `services`
- id (PK)
- name
- description
- category_id (FK, self-referencing)
- price
- cost
- active
- is_group (bool)
- parent_group_id (FK, nullable for grouped service)
- created_at

#### 5.1.7 `products`
- id (PK)
- name
- description
- category_id (FK, self-referencing)
- price
- cost
- stock_quantity
- low_stock_threshold
- barcode
- active
- is_group (bool)
- parent_group_id (FK, nullable for grouped product)
- created_at

#### 5.1.8 `service_product_map`
- id (PK)
- service_id (FK)
- product_id (FK)
- default_qty
- notes

#### 5.1.9 `categories`
- id (PK)
- name
- parent_id (FK, self-referencing)
- type (service/product)

#### 5.1.10 `invoices`
- id (PK)
- invoice_number (unique)
- customer_id (FK, nullable for walk-in)
- invoice_date
- total_amount
- discount
- tax
- grand_total
- amount_paid
- balance_due
- payment_status (pending/partial/paid)
- status (open/closed/void)
- created_by (user_id)
- created_at

#### 5.1.11 `invoice_items`
- id (PK)
- invoice_id (FK)
- item_type (service/product/group)
- item_id (FK to services or products)
- description
- quantity
- rate
- amount
- modifiers (JSON)
- service_status (received/in_process/ready/delivered/cancelled)
- assigned_employee_id (FK, nullable)
- notes

#### 5.1.12 `payments`
- id (PK)
- invoice_id (FK)
- payment_date
- amount
- payment_method (cash/credit/debit/cheque)
- reference_number
- received_by (user_id)

#### 5.1.13 `purchase_orders`
- id (PK)
- vendor_id (FK)
- order_date
- total_amount
- status (pending/received/cancelled)
- created_by

#### 5.1.14 `purchase_order_items`
- id (PK)
- purchase_order_id (FK)
- product_id (FK)
- quantity
- unit_cost
- total_cost

#### 5.1.15 `stock_adjustments`
- id (PK)
- product_id (FK)
- adjustment_type (in/out)
- quantity
- reason
- adjusted_by (user_id)
- adjustment_date

#### 5.1.16 `expenses`
- id (PK)
- expense_category (water, electricity, rent, maintenance, etc.)
- amount
- expense_date
- vendor_id (FK, nullable)
- notes
- created_by

#### 5.1.17 `attendance`
- id (PK)
- employee_id (FK)
- date
- check_in_time
- check_out_time
- status (present/absent/half-day/leave)

#### 5.1.18 `leaves`
- id (PK)
- employee_id (FK)
- leave_type
- start_date
- end_date
- status (pending/approved/rejected)
- approved_by (user_id)

#### 5.1.19 `payroll`
- id (PK)
- employee_id (FK)
- month
- basic_salary
- allowances
- deductions
- net_pay
- paid_status
- paid_date

#### 5.1.20 `advances`
- id (PK)
- employee_id (FK)
- amount
- date
- reason
- recovered_amount
- remaining_amount

#### 5.1.21 `settings`
- id (PK)
- key
- value (JSON)
- description

#### 5.1.22 `license`
- id (PK)
- license_key
- start_date
- end_date
- physical_address (MAC/CPU)
- umac_code
- active

### 5.2 Relationships

- `users` -> `roles` (Many-to-One)
- `users` -> `employees` (One-to-One, optional)
- `services` -> `categories` (Many-to-One, via category_id)
- `products` -> `categories` (Many-to-One, via category_id)
- `services` self-reference for grouping (parent_group_id)
- `products` self-reference for grouping (parent_group_id)
- `service_product_map` (Many-to-Many between services and products)
- `invoices` -> `customers` (Many-to-One, nullable)
- `invoice_items` -> `invoices` (Many-to-One)
- `invoice_items` polymorphic to `services` or `products` (via item_type and item_id)
- `payments` -> `invoices` (Many-to-One)
- `purchase_orders` -> `vendors` (Many-to-One)
- `purchase_order_items` -> `purchase_orders` and `products` (Many-to-One)
- `stock_adjustments` -> `products` (Many-to-One)
- `expenses` -> `vendors` (Many-to-One, nullable)
- `attendance`, `leaves`, `payroll`, `advances` -> `employees` (Many-to-One)
- `settings` and `license` are singleton tables.

---

## 6. Use Cases

### 6.1 Actor: Front-Desk Staff

- **Login:** Authenticate using username/password.
- **Create Walk-in Customer:** Quickly register a new customer with minimal details.
- **Search/Select Customer:** Find existing customer via phone/name.
- **Create Invoice:** Add service/product items, apply discounts, choose payment method, and save/print invoice.
- **Apply Grouped Service/Product:** Select a pre-defined group (e.g., "Wash & Iron Shirt") to add multiple items at once.
- **Scan Barcode:** Use hand-held scanner to add product to invoice.
- **Hold Invoice:** Save incomplete invoice for later recall.
- **Process Payment:** Record partial/full payment, update balance.
- **Print Invoice:** Send to thermal/inkjet printer with chosen format.
- **Share Invoice:** Send PDF receipt via WhatsApp/Email/Social media.
- **Update Service Status:** Change status of items (Received -> In Process -> Ready -> Delivered).
- **Create Delivery Challan:** Generate delivery note for a set of items.
- **View Pending Invoices:** List and follow up on unpaid invoices.
- **Check Customer Balance:** View outstanding amount for a customer.

### 6.2 Actor: Owner/Manager

- **All Front-Desk actions.**
- **Manage Services/Products:** Create, edit, deactivate, set prices, define groups and modifiers.
- **Manage Categories:** Create hierarchical categories for services/products.
- **Manage Customers/Vendors:** Full CRUD, set credit limits.
- **Inventory Management:** Receive stock via purchase order, adjust stock, view stock levels and alerts.
- **Purchase Orders:** Create POs to vendors, mark as received.
- **HR Management:** Add employees, assign roles, manage leaves, process payroll, record advances.
- **Expense Tracking:** Record and categorize business expenses.
- **Reports:** Generate and view sales, inventory, customer, HR, and financial reports.
- **Settings:** Configure currency, language, printer preferences, invoice formats, backup schedule.
- **License Management:** View license status, renew license, view UMAC details.
- **Backup & Restore:** Manually trigger backup, restore from backup, view backup history.

### 6.3 Actor: Production Staff

- **Login with limited permissions.**
- **View Assigned Items:** See list of service items assigned to them.
- **Update Service Status:** Mark items as "In Process" then "Ready".
- **Add Notes:** Add notes about special handling or issues.

### 6.4 Actor: Accountant (if separate role)

- **All financial operations:** Payments, expenses, payroll, advances.
- **View Financial Reports:** Profit & Loss, Balance Sheet (simplified).
- **Manage Vendor Payments:** Record payments to vendors.

### 6.5 Actor: System Administrator

- **User Management:** Create users, assign roles.
- **Database Management:** Direct access to local DB (outside app).
- **License Activation:** Enter license key, bind to hardware.
- **Update Application:** Apply updates.

### 6.6 Use Case Diagram Description

Actors: Front-Desk Staff, Owner/Manager, Production Staff, Accountant, System Admin.
Main use cases: Login, Manage Catalog, POS, Inventory, HR, Reports, Settings, License, Backup.

---

## 7. Technical Blueprint

### 7.1 Architecture Overview

The system follows a **three-tier architecture** within a single machine:

1. **Presentation Tier:** Flutter Windows desktop app.
2. **Application Tier:** Local PHP REST API (running on XAMPP Apache).
3. **Data Tier:** MySQL/MariaDB database.

Communication: Flutter app communicates with PHP API via HTTP requests (localhost). API uses OAuth2.0 for authentication and returns JSON. JWT tokens are used for session management.

### 7.2 Technology Stack

- **Frontend:** Flutter (Dart) for Windows desktop.
- **Backend:** PHP 8.x with Slim Framework or Laravel Lumen (lightweight).
- **Database:** MySQL/MariaDB.
- **Web Server:** Apache (via XAMPP).
- **Authentication:** OAuth2.0 server (custom implementation or library like `bshaffer/oauth2-server-php`).
- **API Documentation:** Swagger/OpenAPI.
- **PDF Generation:** Flutter `pdf` package or PHP `dompdf`/`TCPDF`.
- **Local Storage:** File system for images and PDFs; SQLite for cache (optional).
- **Hardware Integration:** Flutter packages like `flutter_barcode_scanner`, `esc_pos_printer`, `printing`.

### 7.3 MVVM Pattern

- **Model:** Data classes (e.g., `Customer`, `Invoice`, `Service`) with JSON serialization.
- **View:** Flutter widgets (screens) that observe ViewModels.
- **ViewModel:** Contains business logic, calls API services, maintains UI state (using `ChangeNotifier` or `Riverpod`). 

### 7.4 Microservice Approach

Within the local API, endpoints are organized as microservices:

- `/auth` – authentication, token refresh.
- `/customers` – customer CRUD.
- `/services` – service CRUD.
- `/products` – product CRUD.
- `/categories` – category CRUD.
- `/invoices` – invoice CRUD, payment processing.
- `/inventory` – stock adjustments, purchase orders.
- `/employees` – HR endpoints.
- `/reports` – aggregated data for reports.
- `/settings` – application settings.
- `/license` – license validation.
- `/files` – file upload/download.

Each service has its own controller, model, and validation logic.

### 7.5 Database Design Details

- Use InnoDB engine for transaction support.
- Foreign keys with `ON DELETE RESTRICT` to maintain integrity.
- Indexes on frequently queried columns: `invoice_number`, `customer_id`, `service_id`, `product_id`, `barcode`.
- Soft deletes (`active` flag) for services/products/customers to preserve historical data.
- `settings` table stores JSON configuration for flavors, printer templates, etc.

### 7.6 Security

- **OAuth2.0:** Password grant type for initial login, refresh tokens for session renewal.
- **JWT:** Signed with secret key stored in local configuration file; expires after 8 hours.
- **API Rate Limiting:** Basic throttling to prevent brute force (though local).
- **Data Encryption:** Database connection uses local socket; passwords stored hashed (bcrypt).
- **License Enforcement:** UMAC code generated from hardware signature (MAC address + CPU serial). Stored in license table, checked on startup.
- **Audit Logs:** API middleware logs all write operations (who, what, when).

### 7.7 Hardware Integration

- **Scanner:** Configured as keyboard wedge; Flutter listens for rapid input ending with Enter. Supports USB and Bluetooth scanners.
- **Thermal Printer:** Use `esc_pos_printer` package to send ESC/POS commands to printer via USB/Bluetooth/Network.
- **Inkjet/Dot-matrix:** Use Flutter `printing` package to generate PDF then print via Windows print dialog.
- **Cash Drawer:** Triggered by thermal printer’s cash drawer kick command (pin 2) or via dedicated serial port using `flutter_serial_port`.

### 7.8 Local File Management

- **Root Folder:** `C:\LaundryPro\` (configurable during installation).
- **Subfolders:**
  - `invoices/` – PDF receipts named by invoice number.
  - `images/` – product/service images.
  - `backups/` – database dumps and file backups.
  - `logs/` – application and API logs.
  - `exports/` – CSV/Excel exports.
- **Backup Script:** PHP cron or Windows Task Scheduler runs `mysqldump` daily at 2 AM. Backups are zipped and stored in `backups/` with timestamp.
- **Disaster Recovery:** On API start, check database connectivity; if fails, attempt automatic restore from latest backup. Also, Flutter app monitors API health and offers manual restore.

### 7.9 Multi-language & LTR/RTL

- All UI strings are defined in JSON files: `en.json`, `ar.json`.
- Flutter app loads language file based on settings.
- For LTR/RTL, set `Directionality` based on selected language. Use `Localizations` delegate.
- In Arabic, flip layout using `Directionality` and `TextDirection.rtl`.
- Numbers remain Western digits (configurable if needed).

### 7.10 Flavors Config

A "Flavor" defines a set of preferences and UI customizations for different business types (e.g., Laundry Only, Dry Cleaning Only, Full Service). Stored in `settings` table as JSON. Can be switched from settings screen. Examples:

- `pos_layout`: "compact" or "full"
- `show_product_images`: true/false
- `default_service_status`: "received"
- `currency_symbol_position`: "before" or "after"
- `invoice_theme`: "classic", "modern", "simple"
- `quick_buttons`: list of frequently used services/products.

Flutter app reads flavor config and adjusts UI accordingly.

---

## 8. Algorithms & Business Logic

### 8.1 UMAC Generation and Validation

1. On application first run, gather hardware identifiers: MAC address of primary network adapter, CPU serial number, motherboard serial.
2. Concatenate and hash (SHA-256) to produce a unique machine signature.
3. User enters license key (provided by vendor) which contains an encrypted payload with allowed physical address and expiry.
4. Decrypt key using vendor’s private key (hardcoded in app? better: use public key to verify signature).
5. Compare stored physical address in key with current machine signature. If mismatch, reject.
6. Store license details in `license` table, set active.
7. On each startup, check license table; validate expiry and physical address (recompute UMAC). If expired, show renewal screen and limit functionality to viewing data only.

### 8.2 Price Calculation for Invoice

- For each item, retrieve base price from service/product table.
- If item is a group, sum of component prices (with optional group discount).
- Apply modifiers: each modifier may add fixed or percentage amount.
- Apply line discount if any (percentage or amount).
- Compute line total: `quantity * (rate + modifier_additions) - line_discount`.
- Sum all line totals to get subtotal.
- Apply invoice-level discount (percentage or amount).
- Add tax (if configured, e.g., VAT 5% in UAE) on discounted subtotal.
- Grand total = discounted subtotal + tax.
- Balance due = grand total - amount paid.

### 8.3 Inventory Deduction on Invoice Save

- When an invoice item of type `product` is saved (status not cancelled), deduct quantity from `products.stock_quantity`.
- If stock would go negative, prompt user to confirm (allow backorder) or block.
- If invoice is later voided, add quantity back.

### 8.4 Service Status Updates

- Default status for new invoice items: `received`.
- Production staff can change to `in_process`, then `ready`.
- Front-desk can mark as `delivered` when handed to customer.
- If cancelled, restore product stock (if product item) and mark invoice line as cancelled.
- Notifications: When status changes to `ready`, optionally send SMS/WhatsApp (future) or show alert on dashboard.

### 8.5 Payroll Calculation

1. For each employee, get basic salary and allowances from employee record.
2. Calculate attendance-based deductions: (days absent / total working days) * basic salary.
3. Add overtime if tracked (not initially in scope).
4. Deduct any advances recovered this month (from `advances` table, amount to recover per month).
5. Apply other deductions (e.g., fines).
6. Net pay = (basic + allowances) - deductions.
7. Store in `payroll` table, mark unpaid.
8. When paid, update status.

### 8.6 Backup and Recovery

- **Auto-backup:** At 2 AM, run `mysqldump` command to create SQL dump, compress to zip, store in `backups/db_YYYYMMDD_HHMMSS.zip`. Keep last 30 backups, delete older.
- **File backup:** Copy `invoices/` and `images/` folders to backup zip as well.
- **Manual backup:** Admin can trigger from settings screen.
- **Recovery:** On API startup, attempt DB connection; if failed, find latest backup zip, extract, run SQL to restore database. If successful, rename problematic DB and continue. Show notification in app.

### 8.7 Barcode Generation

- Products can have barcodes. Generate Code128 or QR code using `barcode` package in Flutter or PHP.
- Print barcode labels on thermal printer.

### 8.8 Search Optimization

- Use MySQL full-text indexes on customer name, phone, service name, product name.
- Frontend debounces search input, calls API `/search?q=...&type=customer` etc.

---

## 9. Workflow Descriptions

### 9.1 Sales Workflow (POS)

1. Front-desk staff selects "New Sale".
2. If customer exists, search/select; else create walk-in customer.
3. Add items:
   - Scan barcode to add product.
   - Search/select service or product from list.
   - Optionally choose a grouped item (expands to multiple line items).
   - Set quantity and modifiers.
4. Review invoice lines, apply discounts.
5. Choose payment method (cash/credit/debit). If cash, optionally open cash drawer and calculate change.
6. Save invoice. System deducts inventory and updates balances.
7. Print invoice and/or share via social media.
8. If credit, invoice remains in pending status; later payments recorded.

### 9.2 Service Fulfillment Workflow

1. Invoice item created with status `received`.
2. Production staff views assigned items (auto or manual assignment).
3. Mark item as `in_process` (start work).
4. After completion, mark as `ready`.
5. Customer notification (optional).
6. On delivery/handover, mark as `delivered`.

### 9.3 Inventory Receiving Workflow

1. Create purchase order to vendor with product items and quantities.
2. Receive goods, verify against PO.
3. Update stock quantities (add).
4. Record vendor payment if immediate, or track as accounts payable (not explicit in DB but can be via expense or vendor balance).

### 9.4 HR Payroll Workflow

1. At month end, HR/accountant runs payroll generation.
2. System computes net pay based on attendance and advances.
3. Review and adjust if needed.
4. Mark as paid, record payment date.
5. Advances recovery automatically deducted; remaining balance updated.

### 9.5 License Activation Workflow

1. Install application and XAMPP.
2. Launch app, enter license key.
3. App sends request to local API to validate key, which computes UMAC and checks expiry.
4. If valid, store license and unlock features.
5. On expiry, app enters restricted mode.

---

## 10. Feature List

### 10.1 Core Features

- [x] Dashboard with key metrics (today's sales, pending orders, low stock alerts).
- [x] POS screen with quick buttons, scanner support, invoice creation.
- [x] Customer and vendor management.
- [x] Service and product catalog with hierarchical categories and groups.
- [x] Inventory management with purchase orders and stock adjustments.
- [x] Invoice management (list, search, view, reprint).
- [x] Payment tracking and partial payments.
- [x] Service status tracking.
- [x] HR management (employees, attendance, leaves, payroll, advances).
- [x] Expense tracking.
- [x] Reports (sales, inventory, customer, financial).
- [x] Multi-language support (English/Arabic).
- [x] Multi-currency (AED with fils, extendable).
- [x] Hardware integration (scanner, printers, cash drawer).
- [x] License and UMAC control.
- [x] Backup and recovery.
- [x] File management for PDFs and images.
- [x] Social media sharing of invoices.
- [x] Flavors configuration.
- [x] Customizable invoice/report templates.

### 10.2 Advanced Features

- [x] Barcode generation and printing.
- [x] Grouped services and products.
- [x] Modifiers for services and products.
- [x] Delivery challans.
- [x] Customer credit limits and outstanding balances.
- [x] Automatic low stock alerts.
- [x] Audit logs.
- [x] Swagger API documentation.
- [x] Local import/export (CSV).
- [x] Touch-screen optimized UI.

### 10.3 Future Enhancements (Not in Scope)

- Cloud sync for multi-branch.
- Mobile app for customers.
- SMS/WhatsApp notifications.
- Integration with accounting software.
- Real-time foreign exchange rates.

---

## 11. Scalable & Reliable Coding Guidelines

### 11.1 General Principles

- **SOLID:** Follow single responsibility, open-closed, Liskov substitution, interface segregation, dependency inversion.
- **DRY:** Avoid duplication; use helper functions, base classes, traits.
- **KISS:** Keep it simple; avoid over-engineering.
- **YAGNI:** Do not add features not required.

### 11.2 Flutter Best Practices

- Use `const` constructors where possible.
- Separate UI (widgets) from business logic (viewmodels).
- Use `Provider` or `Riverpod` for state management.
- Handle async operations with `FutureBuilder` or `StreamBuilder` appropriately.
- Dispose controllers and subscriptions.
- Use `ThemeData` for consistent styling.
- For large lists, use `ListView.builder`.
- Avoid `setState` in deeply nested widgets; use state management.
- Localization: Use `intl` package with ARB files or JSON; wrap app with `MaterialApp` with `localizationsDelegates`.
- For responsive design, use `MediaQuery` and `LayoutBuilder`.
- Test widgets with `flutter_test`.

### 11.3 PHP API Best Practices

- Use PDO prepared statements for all database queries.
- Validate all input data (never trust client).
- Return proper HTTP status codes (200, 201, 400, 401, 403, 404, 500).
- Use consistent JSON response structure: `{ "success": true, "data": ..., "message": "" }`.
- Handle exceptions globally and log errors.
- Use Composer for dependency management.
- Organize code into controllers, models, middleware.
- Secure endpoints with OAuth2 middleware.
- Rate limit sensitive endpoints (login, token refresh).
- Keep API stateless (JWT in header).
- Document every endpoint with Swagger annotations.

### 11.4 Database Best Practices

- Use migrations for schema changes (e.g., Phinx).
- Normalize data but denormalize for performance where needed (e.g., invoice totals stored in invoice table for quick reports).
- Use transactions for operations that affect multiple tables (invoice save, stock update, payment).
- Index foreign keys and search columns.
- Regularly optimize tables (`OPTIMIZE TABLE`).
- Set appropriate charset (`utf8mb4`) for Arabic support.
- Use `TIMESTAMP` with timezone awareness (store UTC, convert to local in app).

### 11.5 Error Handling & Logging

- In Flutter, catch errors with `try-catch`, show user-friendly messages.
- Use `Sentry` or local logging for exceptions.
- In PHP, log all errors to `logs/app.log` with timestamps.
- Implement API response error codes with descriptive messages.
- Provide retry mechanisms for transient failures (e.g., printer offline).

### 11.6 Performance

- Optimize API queries: use eager loading to avoid N+1.
- Cache frequently used data (e.g., services list) in Flutter app memory or local SQLite.
- Use pagination for large lists (customers, invoices).
- Lazy load images.
- Debounce search inputs.
- Run heavy reports in background with progress indicator.

### 11.7 Security

- Never store plain-text passwords; use bcrypt hash.
- Sanitize all user inputs (SQL injection, XSS).
- Use HTTPS for API (even local, self-signed certificate can be used).
- Keep JWT secret in environment file, not in source code.
- Restrict file upload types and sizes.
- Escape output in PDF generation.
- Implement CSRF protection (though local, still good).
- License validation must be robust against time tampering (use system time and optional NTP check).

### 11.8 Maintainability

- Use consistent naming conventions (camelCase for variables, PascalCase for classes).
- Write self-documenting code with comments where necessary.
- Provide README and API docs.
- Use Git for version control.
- Follow semantic versioning for releases.
- Keep modules decoupled for easy testing and replacement.

### 11.9 Scalability Considerations

- Even though local, design API to be stateless for future load balancing.
- Use database connection pooling (though MySQL local not an issue).
- Design reports to be generated on demand with caching.
- Allow future addition of branch ID to tables for multi-store.
- Use queue for long-running tasks (future).

---

## 12. Appendices

### 12.1 API Endpoints Summary (Sample)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /auth/token | Get OAuth2 token (username/password) |
| POST | /auth/refresh | Refresh token |
| GET | /customers | List customers (paginated, search) |
| POST | /customers | Create customer |
| GET | /customers/{id} | Get customer details |
| PUT | /customers/{id} | Update customer |
| DELETE | /customers/{id} | Deactivate customer |
| GET | /services | List services |
| POST | /services | Create service |
| GET | /products | List products |
| POST | /products | Create product |
| GET | /categories | List categories |
| POST | /categories | Create category |
| GET | /invoices | List invoices (with filters) |
| POST | /invoices | Create invoice (with items) |
| GET | /invoices/{id} | Get invoice details |
| PUT | /invoices/{id}/status | Update invoice status |
| POST | /invoices/{id}/payments | Add payment |
| GET | /inventory/stock | Get current stock levels |
| POST | /inventory/adjust | Adjust stock |
| POST | /purchase-orders | Create purchase order |
| GET | /employees | List employees |
| POST | /employees | Create employee |
| POST | /payroll/generate | Generate payroll for month |
| GET | /reports/sales | Sales report |
| GET | /reports/inventory | Inventory report |
| POST | /backup | Trigger manual backup |
| GET | /license/status | Get license info |
| POST | /license/activate | Activate license |

### 12.2 Database Schema SQL (Simplified)

See ER section for table definitions.

### 12.3 Hardware Configuration

- **Scanner:** Most USB barcode scanners emulate keyboard, no special driver needed. For Bluetooth, pair as keyboard.
- **Thermal Printer:** ESC/POS compatible (e.g., Epson TM-T20, Xprinter). Connect via USB; use vendor driver or generic text driver.
- **Cash Drawer:** Connect RJ11 to thermal printer, or use serial port with dedicated trigger command.
- **Inkjet/Dot-matrix:** Standard Windows printer; Flutter `printing` package handles.

### 12.4 Localization Files

- `en.json`: `{ "home": "Home", "new_sale": "New Sale", ... }`
- `ar.json`: `{ "home": "الرئيسية", "new_sale": "بيع جديد", ... }`

### 12.5 Flavor Configuration Example

```json
{
  "flavor": "full_service",
  "pos_layout": "full",
  "show_product_images": true,
  "quick_buttons": ["Wash & Iron", "Dry Clean", "Iron Only"],
  "currency_symbol": "AED",
  "currency_position": "after",
  "tax_rate": 5,
  "invoice_theme": "modern",
  "default_language": "en",
  "thermal_printer_width": 80
}
```

### 12.6 Backup Script (PHP/Shell)

```php
// backup.php
$timestamp = date('Ymd_His');
$dbName = 'laundrypro';
$backupFile = "C:/LaundryPro/backups/db_{$timestamp}.sql";
$command = "mysqldump -u root -psecret {$dbName} > {$backupFile}";
exec($command);
// Zip file
$zip = new ZipArchive();
$zipFile = "C:/LaundryPro/backups/db_{$timestamp}.zip";
$zip->open($zipFile, ZipArchive::CREATE);
$zip->addFile($backupFile, basename($backupFile));
$zip->close();
unlink($backupFile);
// Delete old backups (keep 30)
$backups = glob("C:/LaundryPro/backups/db_*.zip");
if (count($backups) > 30) {
    usort($backups, function($a, $b) { return filemtime($a) - filemtime($b); });
    for ($i = 0; $i < count($backups) - 30; $i++) {
        unlink($backups[$i]);
    }
}
```

### 12.7 License Activation Algorithm (Pseudocode)

```
function validateLicense(key):
    data = decryptAndVerify(key, publicKey)
    if data.expiry < now:
        return false, "License expired"
    currentUmac = generateUmac()
    if data.umac != currentUmac:
        return false, "Machine mismatch"
    return true, data
```

---

**End of Document**