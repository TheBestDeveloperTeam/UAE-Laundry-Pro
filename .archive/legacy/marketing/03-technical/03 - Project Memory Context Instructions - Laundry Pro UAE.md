# Project Memory Context Instructions – LaundryPro UAE

**Version:** 1.0  
**Date:** [Current Date]  
**Prepared by:** Magnificent Solution  
**Purpose:** This document serves as the comprehensive memory context for the LaundryPro UAE system. It contains all necessary technical, functional, and architectural information to understand, develop, maintain, and extend the application. It is intended for developers, AI assistants, and project stakeholders.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [System Architecture](#2-system-architecture)
3. [Technology Stack](#3-technology-stack)
4. [Database Design](#4-database-design)
5. [API Specifications](#5-api-specifications)
6. [Authentication & Security](#6-authentication--security)
7. [License & UMAC Control](#7-license--umac-control)
8. [Localization & RTL Support](#8-localization--rtl-support)
9. [Hardware Integration](#9-hardware-integration)
10. [Flutter Frontend Structure](#10-flutter-frontend-structure)
11. [PHP Backend Structure](#11-php-backend-structure)
12. [Core Modules & Business Logic](#12-core-modules--business-logic)
13. [Workflows](#13-workflows)
14. [Algorithms](#14-algorithms)
15. [Configuration & Settings](#15-configuration--settings)
16. [Backup & Disaster Recovery](#16-backup--disaster-recovery)
17. [Deployment & Setup](#17-deployment--setup)
18. [Coding Guidelines](#18-coding-guidelines)
19. [Testing Strategy](#19-testing-strategy)
20. [Troubleshooting](#20-troubleshooting)
21. [Future Enhancements](#21-future-enhancements)
22. [Glossary](#22-glossary)
23. [Appendices](#23-appendices)

---

## 1. Project Overview

LaundryPro UAE is a standalone Windows desktop application built for local laundry service MSMEs in the UAE, initially targeting Dubai but scalable to all Emirates and KSA. It manages end-to-end operations including services, products, customers, vendors, HR, inventory, billing, and reporting. The application runs entirely offline with a local MySQL/MariaDB database and a PHP-based local API layer, ensuring data privacy and control.

Key differentiators:
- Custom UI (not a generic website) optimized for touch screens, keyboard, and barcode scanners.
- Flavors configuration to customize sales workflows.
- License tied to physical machine via UMAC.
- Multilingual (English LTR, Arabic RTL) with JSON-controlled labels.
- Multi-currency support (AED with fils initially).
- Hardware integration for scanners, thermal printers, inkjet/dot-matrix printers, and cash drawers.
- Robust backup/disaster recovery.

Target users: Owner/Manager, Front-desk staff, Production staff, Accountant/HR, System Administrator.

---

## 2. System Architecture

The system follows a three-tier architecture within a single Windows machine:

1. **Presentation Tier**: Flutter desktop application (Windows).
2. **Application Tier**: PHP REST API running on Apache (via XAMPP).
3. **Data Tier**: MySQL/MariaDB database.

Communication: Flutter app communicates with PHP API via HTTP requests to `localhost`. The API uses OAuth2.0 for authentication and returns JSON. JWT tokens manage sessions.

**MVVM Pattern** in Flutter:
- **Model**: Data classes with JSON serialization.
- **View**: Flutter widgets observing ViewModels.
- **ViewModel**: Business logic, API calls, state management (using Provider/Riverpod).

**Microservice Approach** in API: Endpoints grouped by domain (auth, customers, services, invoices, etc.) with separate controllers.

**Local File Management**: Root folder `C:\LaundryPro\` with subfolders for invoices, images, backups, logs, exports.

---

## 3. Technology Stack

| Layer          | Technology                           |
|----------------|--------------------------------------|
| Frontend       | Flutter (Dart) for Windows desktop   |
| Backend        | PHP 8.x (Slim Framework or Lumen)    |
| Database       | MySQL/MariaDB (via XAMPP)            |
| Web Server     | Apache (XAMPP)                       |
| Authentication | OAuth2.0 with JWT                    |
| API Docs       | Swagger/OpenAPI                      |
| PDF Generation | Flutter `pdf` package / PHP `dompdf` |
| Hardware       | ESC/POS, Windows printing, serial    |
| Localization   | JSON files (`en.json`, `ar.json`)    |
| Backup         | PHP script + Windows Task Scheduler  |

---

## 4. Database Design

Database name: `laundrypro`  
Engine: InnoDB  
Charset: `utf8mb4` for Arabic support.

### 4.1 Tables (Summary)

| Table Name           | Description                                |
|----------------------|--------------------------------------------|
| `users`              | System users with roles                    |
| `roles`              | User roles and permissions (JSON)          |
| `employees`          | Employee master data                       |
| `customers`          | Customer master data                       |
| `vendors`            | Vendor master data                         |
| `services`           | Service catalog with pricing, categories   |
| `products`           | Product catalog with stock, barcode        |
| `categories`         | Hierarchical categories for services/products |
| `service_product_map`| Many-to-many service-product relationships |
| `invoices`           | Sales invoices with totals, status         |
| `invoice_items`      | Line items for invoices (polymorphic)      |
| `payments`           | Payments against invoices                  |
| `purchase_orders`    | Purchase orders to vendors                 |
| `purchase_order_items`| Line items for purchase orders            |
| `stock_adjustments`  | Manual stock in/out adjustments            |
| `expenses`           | Business expenses                          |
| `attendance`         | Employee attendance records                |
| `leaves`             | Employee leave requests                    |
| `payroll`            | Monthly payroll records                    |
| `advances`           | Employee salary advances                   |
| `settings`           | Key-value settings (JSON values)           |
| `license`            | License key, UMAC, expiry                  |

### 4.2 Key Relationships

- `users` → `roles` (Many-to-One)
- `users` → `employees` (One-to-One optional)
- `services` → `categories` (Many-to-One)
- `products` → `categories` (Many-to-One)
- `services` self-join for grouping (parent_group_id)
- `products` self-join for grouping (parent_group_id)
- `service_product_map` (Many-to-Many between services and products)
- `invoices` → `customers` (Many-to-One, nullable for walk-ins)
- `invoice_items` → `invoices` (Many-to-One)
- `invoice_items` polymorphic to services/products via `item_type` and `item_id`
- `payments` → `invoices` (Many-to-One)
- `purchase_orders` → `vendors` (Many-to-One)
- `purchase_order_items` → `purchase_orders` and `products`
- `stock_adjustments` → `products` (Many-to-One)
- `expenses` → `vendors` (nullable)
- `attendance`, `leaves`, `payroll`, `advances` → `employees`

### 4.3 Soft Deletes

Many tables include an `active` flag (boolean) to preserve historical data (services, products, customers, employees). Deactivation is used instead of hard deletion where necessary.

---

## 5. API Specifications

Base URL: `http://localhost/api/`

All endpoints require `Authorization: Bearer <token>` except `/auth/token` and `/auth/refresh`.

### 5.1 Authentication

| Method | Endpoint        | Description                |
|--------|-----------------|----------------------------|
| POST   | `/auth/token`   | Get OAuth2 token (password grant) |
| POST   | `/auth/refresh` | Refresh access token       |

### 5.2 Customers

| Method | Endpoint           | Description                     |
|--------|--------------------|---------------------------------|
| GET    | `/customers`       | List customers (paginated, search) |
| POST   | `/customers`       | Create customer                 |
| GET    | `/customers/{id}`  | Get customer details            |
| PUT    | `/customers/{id}`  | Update customer                 |
| DELETE | `/customers/{id}`  | Deactivate customer             |

Similar patterns for services, products, categories, vendors, employees, expenses, etc.

### 5.3 Invoices

| Method | Endpoint                  | Description                          |
|--------|---------------------------|--------------------------------------|
| GET    | `/invoices`               | List invoices with filters           |
| POST   | `/invoices`               | Create invoice with items            |
| GET    | `/invoices/{id}`          | Get invoice details                  |
| PUT    | `/invoices/{id}/status`   | Update invoice status (void, close)  |
| POST   | `/invoices/{id}/payments` | Add payment to invoice               |

### 5.4 Inventory

| Method | Endpoint                  | Description                |
|--------|---------------------------|----------------------------|
| GET    | `/inventory/stock`        | Get current stock levels   |
| POST   | `/inventory/adjust`       | Adjust stock               |
| POST   | `/purchase-orders`        | Create purchase order      |
| GET    | `/purchase-orders`        | List purchase orders       |

### 5.5 HR

| Method | Endpoint                | Description                  |
|--------|-------------------------|------------------------------|
| GET    | `/employees`            | List employees               |
| POST   | `/employees`            | Create employee              |
| POST   | `/payroll/generate`     | Generate payroll for month   |
| GET    | `/attendance`           | Get attendance records       |
| POST   | `/attendance`           | Record attendance            |
| POST   | `/leaves`               | Apply for leave              |

### 5.6 Reports

| Method | Endpoint              | Description            |
|--------|-----------------------|------------------------|
| GET    | `/reports/sales`      | Sales report           |
| GET    | `/reports/inventory`  | Inventory report       |
| GET    | `/reports/customers`  | Customer aging report  |
| GET    | `/reports/payroll`    | Payroll report         |

### 5.7 Backup & License

| Method | Endpoint           | Description               |
|--------|--------------------|---------------------------|
| POST   | `/backup`          | Trigger manual backup     |
| GET    | `/license/status`  | Get license info          |
| POST   | `/license/activate`| Activate license key      |

All API responses follow JSON structure:

```json
{
  "success": true,
  "data": {},
  "message": ""
}
```

---

## 6. Authentication & Security

### 6.1 OAuth2.0 Flow

- Flutter app sends `POST /auth/token` with `username`, `password`, `grant_type=password`.
- Server validates credentials, returns `access_token` (JWT) and `refresh_token`.
- Access token expires after 8 hours; refresh token used to obtain new access token.
- JWT contains user ID, role, and permissions; signed with a secret key stored in API `.env` file.

### 6.2 Password Hashing

Passwords are hashed using bcrypt (cost factor 10). No plaintext storage.

### 6.3 Role-Based Access Control (RBAC)

Roles stored in `roles` table with permissions as JSON array. Middleware checks required permission for each endpoint.

### 6.4 Audit Logs

All write operations (POST, PUT, DELETE) are logged in a separate `audit_logs` table (not listed in DB section but recommended) with user ID, timestamp, action, and endpoint.

### 6.5 License & UMAC Integration

On app startup, license validation occurs before granting access to main features. See section 7.

---

## 7. License & UMAC Control

### 7.1 UMAC Generation

- UMAC = Unique Machine Access Code.
- Generated from hardware identifiers: MAC address of primary network adapter, CPU serial number, motherboard serial.
- Algorithm: Concatenate identifiers, apply SHA-256 hash, take first 32 characters.

### 7.2 License Activation

1. User enters license key (provided by Magnificent Solution).
2. Flutter sends key to `/license/activate` endpoint.
3. API decrypts key using public key (embedded in app) to verify signature.
4. Extracts payload containing allowed UMAC, expiry date, and other metadata.
5. Computes current machine UMAC; compares with allowed UMAC.
6. If match and not expired, stores license in `license` table, sets `active=1`.
7. If mismatch or expired, returns error; app enters restricted mode (view-only, no new invoices).

### 7.3 Startup Validation

- On every launch, app queries `/license/status`.
- If license missing, expired, or UMAC mismatch, show renewal screen.

### 7.4 Renewal

- New license key can be activated to extend expiry. Old license record remains for history.

---

## 8. Localization & RTL Support

### 8.1 Language Files

- `assets/lang/en.json`: English labels.
- `assets/lang/ar.json`: Arabic labels.
- Format: `{ "key": "value" }`.

Example:
```json
{
  "app_name": "LaundryPro UAE",
  "new_sale": "New Sale",
  "customer": "Customer"
}
```

### 8.2 Flutter Implementation

- Use `intl` package or custom JSON loader.
- Set `MaterialApp`'s `locale` and `supportedLocales`.
- For RTL, set `Directionality` based on locale (`TextDirection.rtl` for Arabic).
- All UI widgets must respect `Directionality` (automatic with Flutter).
- Numbers remain Western digits; can be configured.

### 8.3 Static Labels

Every visible string must be retrieved from localization file; no hardcoded strings in UI.

---

## 9. Hardware Integration

### 9.1 Barcode Scanner

- Most USB scanners act as keyboard input (HID). No special driver needed.
- Flutter app listens for rapid key events ending with Enter/CR.
- Configuration: Scanner suffix set to Enter; prefix may be disabled.
- Bluetooth scanners pair as keyboard or serial; use serial plugin if needed.

### 9.2 Thermal Printer (ESC/POS)

- Support 80mm and 58mm printers (Epson, Xprinter, etc.).
- Use `esc_pos_printer` Flutter package.
- Connection: USB (via `usb` package), Bluetooth, or Network.
- Commands: Print text, barcode, cut paper, open cash drawer (pin 2).
- Invoice template stored in settings; can be customized (width, font, logo).

### 9.3 Inkjet/Dot-Matrix Printers

- Use Flutter `printing` package to generate PDF then send to Windows print dialog.
- Suitable for A4 reports and invoices.

### 9.4 Cash Drawer

- Connected to thermal printer via RJ11; printer sends kick command.
- Alternative: Serial port trigger using `flutter_serial_port`.

### 9.5 Touch Screen

- UI designed with large buttons, min 48x48 px targets.
- Support for multi-touch and swipe gestures where appropriate.

---

## 10. Flutter Frontend Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants.dart
│   ├── theme.dart
│   ├── utils.dart
│   └── localization.dart
├── models/
│   ├── customer.dart
│   ├── invoice.dart
│   ├── service.dart
│   └── ...
├── services/
│   ├── api_client.dart
│   ├── auth_service.dart
│   ├── customer_service.dart
│   └── ...
├── viewmodels/
│   ├── login_viewmodel.dart
│   ├── pos_viewmodel.dart
│   ├── customer_viewmodel.dart
│   └── ...
├── views/
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── pos_screen.dart
│   ├── customer_list_screen.dart
│   ├── ...
│   └── widgets/
│       ├── custom_button.dart
│       ├── barcode_input.dart
│       └── ...
└── main.dart
```

### 10.1 State Management

Use **Provider** (or Riverpod) for dependency injection and state management. Each screen has a corresponding ViewModel extending `ChangeNotifier`.

### 10.2 API Client

`ApiClient` class using `http` package, handles token injection, refresh logic, error parsing.

### 10.3 Navigation

Use `go_router` for named routes with parameters (e.g., invoice details).

---

## 11. PHP Backend Structure

```
api/
├── public/
│   └── index.php
├── src/
│   ├── Controllers/
│   │   ├── AuthController.php
│   │   ├── CustomerController.php
│   │   └── ...
│   ├── Middleware/
│   │   ├── AuthMiddleware.php
│   │   ├── RoleMiddleware.php
│   │   └── ...
│   ├── Models/
│   │   ├── Customer.php
│   │   ├── Invoice.php
│   │   └── ...
│   ├── Helpers/
│   │   ├── Response.php
│   │   ├── Validator.php
│   │   └── ...
│   └── Config/
│       ├── database.php
│       ├── oauth.php
│       └── ...
├── storage/
│   ├── logs/
│   └── backups/
└── .env
```

### 11.1 Routing

Use Slim framework's routing to map endpoints to controller methods.

### 11.2 Middleware

- `AuthMiddleware`: Validates JWT, attaches user to request.
- `RoleMiddleware`: Checks user role/permission.
- `CorsMiddleware`: For future web access (if needed).

### 11.3 Database Access

Use PDO with prepared statements. Optionally use Eloquent ORM (if Laravel Lumen). For Slim, use a simple query builder or raw PDO.

### 11.4 Validation

Validate all inputs using a custom Validator class or Respect\Validation library.

---

## 12. Core Modules & Business Logic

### 12.1 Service Management

- CRUD for services.
- Hierarchical categories via `categories` table with `parent_id`.
- Grouped services: create a service with `is_group=1`, then add child services via `parent_group_id` or separate mapping.
- Many-to-many service-product mapping via `service_product_map`.
- Modifiers: stored as JSON in `invoice_items.modifiers` (e.g., `{"starch": true, "fragrance": "lavender"}`) or defined in settings.

### 12.2 Product Management

- Similar to services but includes stock quantity and barcode.
- Stock is maintained in `products.stock_quantity`.
- Low stock alerts based on `low_stock_threshold`.

### 12.3 Inventory

- **Receiving**: Create purchase order, mark as received, update stock.
- **Adjustments**: Manual stock in/out with reason.
- **Stock movement**: Invoice creation deducts stock; voiding invoice adds back.

### 12.4 POS & Invoicing

- Invoice items can be of type `service`, `product`, or `group`.
- Price calculation includes modifiers, line discount, invoice discount, tax.
- Payment types: cash, credit, debit, cheque.
- Partial payments update `balance_due`.
- Invoice number auto-generated (e.g., `INV-000001`).

### 12.5 HR Management

- Attendance: daily record with check-in/out.
- Leaves: request/approval workflow.
- Payroll: monthly generation based on attendance, advances.
- Advances: record and track recovery.

### 12.6 Reports

- Sales report by date range, customer, service.
- Inventory report with stock levels.
- Customer aging report.
- Payroll report.
- Customizable report templates.

---

## 13. Workflows

### 13.1 Sales Workflow (POS)

1. User taps "New Sale".
2. Search/select customer or create walk-in.
3. Add items via scanner or manual selection.
4. Adjust quantities, add modifiers.
5. Apply discounts.
6. Select payment method, process payment.
7. Save invoice → API deducts stock, updates balances.
8. Print/share invoice.

### 13.2 Service Fulfillment

1. Invoice item created with status `received`.
2. Production staff updates to `in_process`.
3. Upon completion, mark `ready`.
4. Delivery/handover, mark `delivered`.

### 13.3 Inventory Receiving

1. Create purchase order with products and quantities.
2. Receive shipment, verify.
3. Update stock (add quantities).
4. Record vendor payment if applicable.

### 13.4 Payroll Processing

1. At month end, HR runs payroll generation.
2. System calculates net pay from basic salary, attendance, advances.
3. Review/adjust.
4. Mark as paid.

### 13.5 License Activation

1. Install app, enter license key.
2. API validates, stores license.
3. App unlocks.

---

## 14. Algorithms

### 14.1 UMAC Generation

```
function generateUmac():
    mac = getMacAddress()
    cpu = getCpuSerial()
    board = getBoardSerial()
    raw = mac + cpu + board
    hash = sha256(raw)
    return hash.substring(0, 32)
```

### 14.2 Price Calculation

```
for each item in invoice_items:
    basePrice = (item_type == 'service') ? service.price : product.price
    if item is group:
        basePrice = sum(child prices) * groupDiscount
    modifierAdd = sum(modifier extra)
    lineTotal = (basePrice + modifierAdd) * quantity - lineDiscount
subtotal = sum(lineTotal)
discountedSubtotal = subtotal - invoiceDiscount
tax = discountedSubtotal * taxRate/100
grandTotal = discountedSubtotal + tax
balanceDue = grandTotal - amountPaid
```

### 14.3 Inventory Deduction

On invoice save (status not void):
- For product items, decrement stock by quantity.
- If stock < 0, warn or block (configurable).

On invoice void:
- Increment stock back.

### 14.4 Payroll Calculation

```
basicSalary = employee.basic_salary
allowances = employee.allowances
daysAbsent = count(attendance.status='absent')
workingDays = totalWorkingDays(month)
deduction = (daysAbsent / workingDays) * basicSalary
advanceRecovery = sum(advances.due_this_month)
netPay = basicSalary + allowances - deduction - advanceRecovery - otherDeductions
```

### 14.5 Backup Rotation

- Keep last 30 backups.
- Delete older backups automatically.

---

## 15. Configuration & Settings

Settings stored in `settings` table as JSON values. Accessible via `/settings` endpoints.

### 15.1 Flavors Configuration

A flavor defines UI and workflow preferences. Example JSON:

```json
{
  "flavor": "full_service",
  "pos_layout": "full",
  "show_product_images": true,
  "quick_buttons": ["Wash & Iron", "Dry Clean"],
  "currency_symbol": "AED",
  "currency_position": "after",
  "tax_rate": 5,
  "invoice_theme": "modern",
  "default_language": "en",
  "thermal_printer_width": 80
}
```

### 15.2 Printer Settings

- Thermal printer width (58/80mm), characters per line.
- Invoice template: logo path, font size, footer text.

### 15.3 Backup Schedule

- Time of day for automatic backup (default 2 AM).
- Backup location.

### 15.4 Localization

- Default language selection.
- Ability to add new language JSON files.

---

## 16. Backup & Disaster Recovery

### 16.1 Automatic Backups

- Windows Task Scheduler runs PHP script `backup.php` daily at 2 AM.
- Script performs `mysqldump` of `laundrypro` database.
- Also zips `invoices/` and `images/` folders.
- Stores zip in `C:\LaundryPro\backups\db_YYYYMMDD_HHMMSS.zip`.
- Deletes backups older than 30 days.

### 16.2 Manual Backup

- Admin can trigger backup from Settings screen or command line.

### 16.3 Disaster Recovery

- On API startup, check DB connection.
- If fails, find latest backup zip, extract SQL, restore database.
- Show notification in app about recovery.

### 16.4 Zero Data Loss Strategy

- Use InnoDB transactions for critical operations.
- Regular backups minimize data loss window.
- Consider binary logs (not implemented but recommended).

---

## 17. Deployment & Setup

### 17.1 Prerequisites

- Windows 10/11.
- XAMPP with PHP 8.x and MySQL.
- Flutter SDK installed and configured for Windows.
- Composer for PHP dependencies.
- Hardware peripherals (optional).

### 17.2 Installation Steps

1. Install XAMPP, start Apache and MySQL.
2. Clone API code into `C:\xampp\htdocs\laundrypro-api`.
3. Run `composer install`.
4. Copy `.env.example` to `.env`, set database credentials, JWT secret.
5. Import database schema (`schema.sql`) into MySQL.
6. Build Flutter app: `flutter build windows`.
7. Run app; it will connect to `http://localhost/laundrypro-api/`.
8. Activate license.

### 17.3 Configuration Files

- API `.env`: DB connection, OAuth keys, backup paths.
- Flutter `config.dart`: API base URL, default language, etc.

---

## 18. Coding Guidelines

### 18.1 General

- Follow SOLID, DRY, KISS principles.
- Use meaningful names.
- Write self-documenting code with comments where necessary.

### 18.2 Flutter

- Use `const` constructors.
- Separate UI and business logic.
- Use Provider/Riverpod.
- Avoid `setState` in deep trees.
- Handle async with `FutureBuilder`/`StreamBuilder`.
- Test widgets.

### 18.3 PHP

- Use PDO prepared statements.
- Validate all inputs.
- Return consistent JSON.
- Handle exceptions globally.
- Use Composer.
- Document with Swagger annotations.

### 18.4 Database

- Use migrations for schema changes.
- Normalize; denormalize for performance if needed.
- Use transactions for multi-table operations.
- Index foreign keys and search fields.
- Use `utf8mb4`.

### 18.5 Security

- Never store plaintext passwords.
- Escape output in PDF.
- Validate file uploads.
- Use HTTPS (even self-signed) for API.
- Protect JWT secret.

### 18.6 Performance

- Optimize queries.
- Cache frequently used data.
- Paginate large lists.
- Debounce search.

### 18.7 Maintainability

- Keep modules decoupled.
- Use version control.
- Write documentation.

---

## 19. Testing Strategy

- **Unit Tests**: Test ViewModels, models, algorithms (Flutter `flutter_test`).
- **API Tests**: Use Postman/Newman or PHPUnit for endpoint testing.
- **Integration Tests**: Test database interactions.
- **UI Tests**: Flutter integration tests for critical flows (POS, login).
- **User Acceptance Testing**: With sample data.

---

## 20. Troubleshooting

| Issue                          | Possible Cause                | Solution                                   |
|--------------------------------|-------------------------------|--------------------------------------------|
| API connection refused         | Apache not running            | Start XAMPP Apache                          |
| Database connection failure    | Wrong credentials in .env     | Check .env settings                         |
| License mismatch               | Hardware changed or key wrong | Re-activate with correct key                |
| Scanner not inputting          | Scanner not in HID mode       | Configure scanner as keyboard wedge         |
| Thermal printer not printing   | Wrong driver or port          | Install correct driver, check port          |
| RTL not working                | Locale not set properly       | Ensure `Directionality` is set              |
| Backup not running             | Task Scheduler not configured | Set up scheduled task                       |

---

## 21. Future Enhancements

- Cloud synchronization for multi-branch.
- Mobile app for customers (order tracking).
- SMS/WhatsApp notifications.
- Integration with accounting software.
- Real-time FX rates for multi-currency.
- Barcode label printing module.
- Advanced analytics with charts.

---

## 22. Glossary

- **UMAC**: Unique Machine Access Code.
- **POS**: Point of Sale.
- **RTL**: Right-to-left (Arabic).
- **LTR**: Left-to-right (English).
- **ESC/POS**: Epson Standard Code for Point of Sale printers.
- **JWT**: JSON Web Token.
- **OAuth2.0**: Authorization framework.
- **Flavor**: Predefined configuration set for UI/workflow.
- **Soft Delete**: Deactivation via flag instead of deletion.

---

## 23. Appendices

### 23.1 Sample Invoice JSON

```json
{
  "invoice_number": "INV-000123",
  "customer_id": 5,
  "invoice_date": "2025-01-15",
  "items": [
    {
      "item_type": "service",
      "item_id": 10,
      "description": "Dry Clean",
      "quantity": 2,
      "rate": 15.00,
      "amount": 30.00,
      "modifiers": {"starch": true}
    },
    {
      "item_type": "product",
      "item_id": 3,
      "description": "Shirt",
      "quantity": 2,
      "rate": 5.00,
      "amount": 10.00
    }
  ],
  "subtotal": 40.00,
  "discount": 5.00,
  "tax": 1.75,
  "grand_total": 36.75,
  "amount_paid": 20.00,
  "balance_due": 16.75,
  "payment_status": "partial"
}
```

### 23.2 Localization File Snippet

`en.json`:
```json
{
  "app_name": "LaundryPro UAE",
  "login": "Login",
  "username": "Username",
  "password": "Password",
  "new_sale": "New Sale",
  "customers": "Customers",
  "services": "Services",
  "reports": "Reports"
}
```

`ar.json`:
```json
{
  "app_name": "لوندري برو الإمارات",
  "login": "تسجيل الدخول",
  "username": "اسم المستخدم",
  "password": "كلمة المرور",
  "new_sale": "بيع جديد",
  "customers": "العملاء",
  "services": "الخدمات",
  "reports": "التقارير"
}
```

### 23.3 Backup Script (PHP)

```php
<?php
// backup.php
$timestamp = date('Ymd_His');
$dbName = 'laundrypro';
$backupDir = 'C:/LaundryPro/backups/';
$backupFile = $backupDir . "db_{$timestamp}.sql";
$command = "mysqldump -u root -psecret {$dbName} > {$backupFile}";
exec($command);
$zip = new ZipArchive();
$zipFile = $backupDir . "db_{$timestamp}.zip";
if ($zip->open($zipFile, ZipArchive::CREATE) === TRUE) {
    $zip->addFile($backupFile, basename($backupFile));
    $zip->close();
    unlink($backupFile);
}
// Cleanup old backups
$backups = glob($backupDir . "db_*.zip");
if (count($backups) > 30) {
    usort($backups, function($a, $b) { return filemtime($a) - filemtime($b); });
    for ($i = 0; $i < count($backups) - 30; $i++) {
        unlink($backups[$i]);
    }
}
```

---

**End of Project Memory Context Instructions**