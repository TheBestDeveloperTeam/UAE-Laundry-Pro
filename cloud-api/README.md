# LaundryPro UAE — Central Multi-Tenant Cloud API & Super-Admin Web Portal

**Product Reference:** LaundryPro Cloud Platform  
**Target Environment:** cPanel Shared Hosting / Linux Apache / VPS  
**Technology Stack:** Pure PHP 8.2 + MariaDB/MySQL PDO (Zero external dependencies)  
**User Interface:** AdminLTE v4 (Bootstrap 5, Material styling)  

---

## 1. Overview & Architecture

The cloud-api/ application serves as the centralized cloud control plane and synchronization hub for all distributed local laundry workstations (LaundryPro Local).

Key capabilities:
1. **Multi-Tenant Synchronization:** Ingests and partitions transactional data (customers, sales_orders, payments, inventory, 	elemetry) from distributed local client nodes.
2. **Super-Admin Web Portal (/admin):** Complete management portal styled with AdminLTE v4 for system administrators.
3. **Cryptographic Licensing Engine:** Issues signed machine-locked license keys and handles offline/online license handshakes.
4. **Instant Remote Revocation:** Enables 1-click remote kill-switch to lock unpaid or suspended client installations.

---

## 2. Directory Structure

`
cloud-api/
├── .htaccess                 # Redirects web requests to public/
├── config/
│   ├── app.php               # Application keys, debug flags, session security
│   └── database.php          # Database credentials (PDO MySQL/MariaDB)
├── database/
│   ├── 001_cloud_schema.sql  # Core cloud tables and constraints
│   └── 002_cloud_seeds.sql   # Initial super-admin seed credentials
├── public/
│   ├── .htaccess             # mod_rewrite front-controller
│   ├── index.php             # Unified router entrypoint for API and Admin Portal
│   └── assets/               # AdminLTE CSS, JS, and image assets
├── src/
│   ├── Controllers/
│   │   ├── CloudApiController.php      # Multi-tenant REST sync endpoints
│   │   └── AdminPortalController.php   # AdminLTE web portal actions
│   ├── Core/
│   │   ├── Database.php      # PDO database wrapper
│   │   ├── Request.php       # HTTP request parser (JSON + Web forms)
│   │   ├── Response.php      # JSON responder & view renderer
│   │   └── Router.php        # Fast lightweight regex router
│   └── Views/                # AdminLTE PHP views
│       ├── layouts/main.php  # Sidebar, navbar, branding shell
│       ├── auth/login.php    # Super-admin login card
│       ├── dashboard/index.php
│       ├── tenants/index.php
│       ├── licenses/index.php
│       ├── sync/index.php
│       └── audit/index.php
`

---

## 3. Deployment Guide (cPanel / Shared Hosting / VPS)

1. Upload the entire cloud-api/ directory to your web server (e.g., public_html/cloud-api or dedicate a subdomain laundrypro-cloudapi.magnificentsolution.co.in).
2. Point the Document Root to cloud-api/public/ (or rely on root .htaccess).
3. Create database laundrypro_cloud in cPanel MySQL Database Wizard.
4. Import schema and seeds:
   - cloud-api/database/001_cloud_schema.sql
   - cloud-api/database/002_cloud_seeds.sql
5. Configure database credentials in cloud-api/config/database.php or set environment variables:
   - DB_HOST, DB_NAME, DB_USER, DB_PASS, DB_PORT.

---

## 4. Super-Admin Portal Access

- **Portal URL:** http://localhost/cloud-api/public/admin or http://cloud-api/admin
- **Default Username:** superadmin
- **Default Password:** SuperAdmin@LaundryPro2026!

*(Note: Change your password upon initial production login).*

---

## 5. Cloud REST API Specification

All tenant sync endpoints require headers:
- X-Business-Owner-Id: <tenant_id>
- Authorization: Bearer <cloud_token>

| Method | Route | Description |
|---|---|---|
| GET | /api/v1/health | Service health status check |
| POST | /api/v1/businesses/register | Auto-registers new local laundry node |
| POST | /api/v1/sync/push | Ingests queued local outbox delta payloads |
| GET | /api/v1/sync/pull | Fetches delta updates from cloud partitioned by tenant |
| POST | /api/v1/license/handshake | Hardware telemetry & license validity verification |