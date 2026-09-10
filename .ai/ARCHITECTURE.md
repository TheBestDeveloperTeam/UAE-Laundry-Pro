# Architecture: LaundryPro UAE

## Layers
`
Flutter UI (Views)
  └── ViewModels / Providers (Provider/Riverpod)
        └── Services (api_client.dart → PHP API)
              └── PHP Controllers → Repositories → MariaDB
`

## Key Patterns
- **MVVM**: UI ↔ ViewModel ↔ Service ↔ API
- **Adapter Pattern**: All hardware behind generic interfaces (ScanService, PrinterService, CashDrawerService)
- **Repository Pattern**: PHP Repositories wrap all SQL — never raw SQL in controllers
- **Offline-First**: Local MariaDB is source of truth; optional cloud sync via outbox
- **Idempotency**: All write APIs accept X-Idempotency-Key header

## Hardware Adapter Layer
`
lib/peripherals/
├── core/
│   ├── printer/      ← ESC/POS + Win32 spooler adapters
│   ├── scanner/      ← HID keyboard wedge + serial adapters
│   ├── cash_drawer/  ← RJ11 via printer + direct serial
│   ├── hardware/     ← connectivity manager, auto-discovery
│   └── config/       ← hardware_config.json read/write
└── features/
    ├── printer/      ← print UI, template designer, print queue
    ├── scanner/      ← scanner config UI, test screen
    ├── cash_drawer/  ← session management UI
    └── dashboard/    ← hardware health dashboard
`

## Settings Precedence
System Default < Business Override < Branch Override < Terminal Override

## Critical Anti-Patterns (PROHIBITED)
1. Storing monetary totals as floating-point
2. Updating posted invoices in place
3. Deleting inventory movement records
4. Hardcoding service/product hierarchy depth
5. Hardcoded English UI strings in widgets
6. Client-only authorization checks
7. Raw SQL in Flutter widgets
8. Manufacturer-specific SDK calls in business services

## Document Number Format
INV-YYYY-000001 | REC-YYYY-000001 | CM-YYYY-000001 | DM-YYYY-000001 | CHL-YYYY-000001 | GRN-YYYY-000001
Order: LP-{YYYY}-{BRANCH_CODE}-{00001}
All generated server-side atomically.
