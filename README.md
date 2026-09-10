# LaundryPro UAE - Enterprise POS & ERP System

A fully integrated, offline-first Point-of-Sale (POS) and Enterprise Resource Planning (ERP) application engineered specifically for the commercial laundry sector in the United Arab Emirates.

## Architecture

This project adheres to **Clean Architecture** principles, enforcing strict separation of concerns across the stack.

### Frontend: Flutter (Windows Desktop)
- **Framework:** Flutter (Material 3 Design System).
- **State Management:** Provider for global state (Auth, Locale), Riverpod for complex peripheral integrations (Hardware Wedges, Sockets).
- **Routing:** GoRouter for declarative, path-based navigation.
- **UI System:** A unified, bespoke widget library (`AppFormDialog`, `AppDataTable`, `StatusBadge`) replacing all inline widget sprawl, ensuring 100% UI/UX consistency and RTL (Arabic) compliance.

### Backend: PHP 8.2 Micro-Framework
- **Structure:** Custom lightweight MVC architecture optimized for raw speed and minimal memory footprint on edge terminals.
- **Controllers:** Handle HTTP requests and response formatting (`ApiResponse`).
- **Services:** Encapsulate pure business logic (e.g., `SyncService`, `AuthService`).
- **Repositories:** Dedicated data access layers (DAL) with robust `PDO` transaction boundary management.
- **Middleware:** Request interception for Authentication (`JwtService`), CORS, and Rate Limiting.

### Database: MariaDB (XAMPP Environment)
- **Transactions:** High-concurrency operations (like `InventoryRepository::transfer`) use `SELECT ... FOR UPDATE` to lock rows and prevent race conditions.
- **Data Integrity:** Float values are strictly prohibited for monetary transactions; all financials use `DECIMAL(18,2)`.
- **Audit Trails:** All destructive actions and financial alterations are soft-deleted and written to an immutable `audit_logs` table.

## Offline-First Synchronization
LaundryPro UAE is designed to survive extended network outages. 
- All data is written to the local MariaDB instance first.
- Background jobs push mutated records to the `sync_outbox`.
- `SyncService` attempts to flush the outbox to the central cloud using an exponential backoff algorithm on failure.

## Development & Deployment

### Prerequisites
- **Client Terminal:** Windows 10/11
- **Environment:** XAMPP (PHP 8.2, MariaDB)
- **Compiler:** Flutter SDK (3.x+)

### Installation
1. Clone the repository to the target terminal.
2. Navigate to `/api` and execute `composer install`.
3. Copy `.env.example` to `.env` and configure local database credentials.
4. Run the SQL migrations sequentially from `/api/migrations/`.
5. Execute `flutter pub get` in the project root.

### Building for Production
A streamlined PowerShell script is provided to automate the packaging process.
Execute: `.\build_windows.ps1`

This will:
1. Purge cached artifacts (`flutter clean`).
2. Compile the native Windows binary (`flutter build windows --release`).
3. Scaffold a deployment folder (`\build\laundrypro_release\`).
4. Inject the PHP backend and routing infrastructure alongside the compiled executable.

## Security Posture
- **No Client-Side Trust:** All authorizations are validated server-side via JWT.
- **Sanitized Inputs:** Prepared statements exclusively prevent SQL injections.
- **Local Backups:** Automated `.zip` snapshots of `.sql` dumps are validated cryptographically (SHA-256) upon restoration to prevent payload tampering.

---
*Proprietary Software - Developed exclusively for LaundryPro UAE.*
