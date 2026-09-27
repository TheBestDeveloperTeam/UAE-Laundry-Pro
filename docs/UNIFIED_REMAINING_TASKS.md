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
