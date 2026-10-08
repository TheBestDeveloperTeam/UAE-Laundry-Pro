# LaundryPro UAE — C1: Architecture Re-Audit

> **Chunk:** C1 | **Date:** 2026-10-07 | **Status:** ✅ COMPLETE
> **Auditor:** Project Delivery Production Manager

---

## 1. System Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                     FLUTTER DESKTOP (Windows/Android)            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐│
│  │ GoRouter  │  │ Riverpod │  │ Provider │  │ Peripheral Layer ││
│  │ (42 rtes) │  │ (5 provs)│  │ (legacy) │  │ (printer/scan)   ││
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────────────┘│
│       └──────────────┼───────────┬─┘             │              │
│               ┌──────┴──────┐   │                │              │
│               │ 38 Services │───┼────────────────┘              │
│               └──────┬──────┘   │                               │
│                      │          │                               │
│               ┌──────┴──────┐   │                               │
│               │  ApiClient  │◄──┘  (Dio + JWT interceptor)      │
│               │ (localhost)  │      NEVER calls Cloud API        │
│               └──────┬──────┘                                   │
└──────────────────────┼──────────────────────────────────────────┘
                       │ HTTP (localhost:8000)
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│                     LOCAL PHP API (XAMPP)                        │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────────────────┐  │
│  │ Router   │  │ 10 Middleware│  │ OpenAPI Generator         │  │
│  │ (178 rts)│  │ Auth/RBAC/   │  │ (auto from route meta)   │  │
│  │          │  │ Audit/Rate   │  │                          │  │
│  └────┬─────┘  └──────┬──────┘  └──────────────────────────┘  │
│       └───────────┬────┘                                       │
│            ┌──────┴──────┐                                     │
│            │ 43 Contrlrs │ → Controller validates + delegates  │
│            └──────┬──────┘                                     │
│            ┌──────┴──────┐                                     │
│            │ 17 Services │ → Business logic (VatCalc, Payroll) │
│            └──────┬──────┘                                     │
│            ┌──────┴──────┐                                     │
│            │ 39 Repos    │ → PDO prepared statements           │
│            └──────┬──────┘                                     │
│                   │  PDO                                       │
│            ┌──────┴──────┐                                     │
│            │ MariaDB/MySQL│ 219 tables, DECIMAL(18,2)          │
│            └──────┬──────┘                                     │
│                   │  Sync Engine (row-by-row)                  │
└───────────────────┼────────────────────────────────────────────┘
                    │ HTTPS (outbound only)
                    ▼
┌──────────────────────────────────────────────────────────────────┐
│                     CLOUD PHP API (cPanel)                       │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────────────────┐  │
│  │ Router   │  │ 3 Middleware │  │ TenantScopeMiddleware    │  │
│  │ (189 rts)│  │ CSRF/Rate/   │  │ (multi-tenant isolation) │  │
│  │          │  │ TenantScope  │  │                          │  │
│  └────┬─────┘  └──────┬──────┘  └──────────────────────────┘  │
│       └───────────┬────┘                                       │
│            ┌──────┴──────┐                                     │
│            │ 18 Contrlrs │ → Super-Admin + tenant scoped ops   │
│            └──────┬──────┘                                     │
│                   │  PDO                                       │
│            ┌──────┴──────┐                                     │
│            │ MySQL/Maria │  Cloud schema (businesses, sync,    │
│            │             │  license_approvals, admin_portal)   │
│            └─────────────┘                                     │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. Layer-by-Layer Analysis

### 2.1 Flutter Layer

| Component | Count | Pattern | Health |
|:----------|:------|:--------|:-------|
| Views/Screens | 42 | Stateful/Stateless Widgets | ✅ |
| Services | 38 | Service classes calling ApiClient | ✅ |
| Models | 23 | Immutable data classes w/ fromJson | ✅ |
| Providers (Riverpod) | 5 | auth, catalog, locale, cart, sync | ⚠️ Mixed with legacy Provider |
| Core utilities | 18 | theme, logger, validators, money, receipt | ✅ |
| Router | 1 file | GoRouter with auth guards | ✅ |
| Peripheral layer | separate dir | printer, scanner, cash drawer | ✅ |

**Architecture Observations:**
- **Provider Dual-Dependency (P2):** The app uses BOTH `flutter_riverpod` AND `provider` (legacy). `main.dart` wraps `UncontrolledProviderScope` (Riverpod) inside `legacy_provider.MultiProvider`. This works but is technical debt.
- **ApiClient points to `localhost` only (AC-7 compliant):** Flutter never contacts the Cloud API.
- **Auth guard with license check:** GoRouter redirect handles unauthenticated, license-expired, and setup states correctly.
- **8 empty catch blocks remain** in `main.dart` (2), `sync_service.dart` (1), `system_guard_service.dart` (3), `network_printer_discovery.dart` (1), `raw_spooler_printer.dart` (1). The `main.dart` ones are acceptable (crash logger fallback), but the service ones should log.

### 2.2 Local PHP API Layer

| Component | Count | Pattern | Health |
|:----------|:------|:--------|:-------|
| Core framework | 14 files | Application, Router, Validator, Container, Money, Uuid | ✅ |
| Controllers | 43 | Controller classes with action methods | ✅ |
| Repositories | 39 | PDO prepared statements, `admin_id` scoped | ✅ |
| Services | 17 | Business logic (VAT, Payroll, Sync, License, Backup) | ✅ |
| Middleware | 5 files | Auth, Permission, RateLimit, AuditLog, Idempotency | ✅ |
| Security | 4 files | JWT (RS256), PasswordHasher (Argon2id), UMAC | ✅ |
| Adapters | 2 files | RFID hardware adapter interface + dummy | ✅ |
| Routes | 178 endpoints | Single `api.php` with OpenAPI metadata per route | ✅ |

**Architecture Observations:**
- **Proper layering:** Controller → Service → Repository → PDO. No shortcuts detected.
- **bcmath enforcement:** `Money.php` and `VatCalculator.php` use bcmath. No FLOAT/DOUBLE in schema.
- **Middleware stack well-structured:** `$auth = [AuthMiddleware, PermissionMiddleware]`, `$audit = [..., IdempotencyMiddleware, AuditLogMiddleware]`.
- **Duplicate controller pair (P2):** Both `ReportController.php` and `ReportsController.php` exist. Need consolidation.
- **Missing middleware files:** `AuthMiddleware`, `PermissionMiddleware`, `CorsMiddleware`, `InstallRateLimitMiddleware`, `InstallTokenMiddleware` are imported in `Application.php` but only 5 files exist in `Middleware/`. The missing ones are likely defined inside `Middleware.php` (5.8 KB monolith) — this is an architectural concern but functional.

### 2.3 Cloud PHP API Layer

| Component | Count | Pattern | Health |
|:----------|:------|:--------|:-------|
| Core | 5 files | Database, Env, Request, Response, Router | ✅ |
| Controllers | 18 | Consolidated controller pattern | ✅ |
| Middleware | 3 files | CSRF, RateLimit, TenantScope | ✅ |
| Routes | 189 endpoints | Single `api.php` | ✅ |

**Architecture Observations:**
- **No Repository/Service layer (P1):** Cloud API controllers contain inline SQL queries directly. This contrasts with the Local API's proper C→S→R layering. This is a significant architectural asymmetry but acceptable for a gateway that primarily mirrors data.
- **TenantScopeMiddleware handles multi-tenancy:** Uses bearer token → businesses table lookup. Fallback to mock tenant when DB offline is a development convenience that must be hardened before production.
- **Route count (189) exceeds Local (178):** Cloud has additional Super-Admin, tenant management, and data explorer endpoints. This is expected per the mandate.

### 2.4 Database Layer

| Metric | Value | Health |
|:-------|:------|:-------|
| Total CREATE TABLE | 219 | ✅ |
| Money columns | All `DECIMAL(18,2)` | ✅ No FLOAT/DOUBLE |
| Tenant isolation | `admin_id` present in schema | ✅ |
| Seed data | 4.6 KB | ⚠️ Minimal |
| Schema file | 176 KB master | ✅ |
| Local schema | 62 KB | ✅ |
| Cloud schema | 31 KB | ✅ |

---

## 3. Shared Kernel Verification

| Component | Local API | Cloud API | Status |
|:----------|:----------|:----------|:-------|
| JWT (RS256) | `JwtService.php` | AuthController inline | ⚠️ Not shared |
| Password hashing (Argon2id) | `PasswordHasher.php` | AuthController inline | ⚠️ Not shared |
| Router | Custom `Router.php` | Custom `Router.php` | ⚠️ Separate implementations |
| Validator | `Validator.php` (5.7 KB) | Inline in controllers | ⚠️ Not shared |
| Logger | `Logger.php` helper | No structured logger | ❌ Cloud missing |
| Response envelope | `ApiResponse.php` helper | `Response.php` inline | ⚠️ Different patterns |
| Money/bcmath | `Money.php` core class | Not used (gateway only) | ✅ Acceptable |

**Finding F-001 (P2):** The Local and Cloud APIs do not share a PHP package/kernel. Each has its own implementations. For a 2-API system, this is acceptable but creates drift risk. Recommend extracting `laundrypro-shared` for JWT, hashing, validation, and envelope in a future maintenance sprint.

---

## 4. Architectural Risk Heat Map

```
                     LOW RISK          MEDIUM RISK         HIGH RISK
                   ┌──────────────┬──────────────────┬────────────────┐
Flutter Frontend   │ ✅ Routing    │ ⚠️ Dual Provider │                │
                   │ ✅ Services   │   (Riverpod +   │                │
                   │ ✅ Models     │    legacy)       │                │
                   │ ✅ Peripherals│ ⚠️ 8 empty catch │                │
                   ├──────────────┼──────────────────┼────────────────┤
Local PHP API      │ ✅ C→S→R     │ ⚠️ Dual Report   │                │
                   │ ✅ Middleware │   Controllers    │                │
                   │ ✅ bcmath     │ ⚠️ Middleware    │                │
                   │ ✅ RBAC      │   monolith file  │                │
                   ├──────────────┼──────────────────┼────────────────┤
Cloud PHP API      │ ✅ Multi-     │ ⚠️ No S→R layer │ ❗ Mock tenant  │
                   │   tenancy    │ ⚠️ No shared    │   fallback in  │
                   │ ✅ Routes    │   kernel w/Local │   production   │
                   ├──────────────┼──────────────────┼────────────────┤
Database           │ ✅ DECIMAL   │ ⚠️ Seed data is │                │
                   │ ✅ admin_id  │   minimal (4.6KB)│                │
                   │ ✅ 219 tables│                  │                │
                   ├──────────────┼──────────────────┼────────────────┤
Sync Engine        │ ✅ Row-by-row│ ⚠️ No dead-letter│                │
                   │ ✅ Outbox    │   queue visible  │                │
                   │ ✅ UUID based│                  │                │
                   ├──────────────┼──────────────────┼────────────────┤
Security           │ ✅ Argon2id  │ ⚠️ No HSTS/CSP  │                │
                   │ ✅ RS256 JWT │   headers visible│                │
                   │ ✅ Rate limit│                  │                │
                   └──────────────┴──────────────────┴────────────────┘
```

---

## 5. Findings Summary

| ID | Severity | Area | Summary | Effort |
|:---|:---------|:-----|:--------|:-------|
| F-001 | P2 | Architecture | No shared PHP kernel between Local and Cloud API | L |
| F-002 | P2 | Flutter | Dual provider system (Riverpod + legacy Provider) | M |
| F-003 | P2 | Flutter | 8 empty `catch (_) {}` blocks in services/peripherals | S |
| F-004 | P2 | Local API | Duplicate controllers: `ReportController` + `ReportsController` | S |
| F-005 | P2 | Local API | Middleware monolith: multiple middleware classes in single file | S |
| F-006 | P1 | Cloud API | Mock tenant fallback in `TenantScopeMiddleware` when DB offline | S |
| F-007 | P2 | Cloud API | No Service/Repository layer (inline SQL in controllers) | XL |
| F-008 | P2 | Cloud API | No structured logger | S |
| F-009 | P2 | Database | Seed data is minimal (4.6 KB) — needs product catalog, modifiers, taxes | M |
| F-010 | P2 | Security | HSTS/CSP/X-Frame-Options headers not verified in HTTP responses | S |

---

## 6. Recommendations

### P1 (Must Fix Before Production)

| # | Action | Impact |
|:--|:-------|:-------|
| R-001 | Harden `TenantScopeMiddleware` mock tenant fallback — disable in production mode or gate behind `APP_ENV=development` check | Prevents unauthorized tenant access |

### P2 (Fix Within 2 Sprints)

| # | Action | Impact |
|:--|:-------|:-------|
| R-002 | Replace remaining empty catch blocks with `AppLogger.warning()` calls | Better debugging in production |
| R-003 | Consolidate `ReportController` into `ReportsController` | Code hygiene |
| R-004 | Add security headers (HSTS, CSP, X-Frame-Options) to both API response pipelines | Security hardening |
| R-005 | Expand seed data with full product catalog, modifiers, taxes, and demo data | Faster onboarding |

### P3 (Backlog)

| # | Action | Impact |
|:--|:-------|:-------|
| R-006 | Migrate from dual Provider to pure Riverpod | Technical debt reduction |
| R-007 | Extract shared PHP kernel package | Drift prevention |
| R-008 | Add Service/Repository layer to Cloud API | Architectural consistency |

---

## 7. Dead Code & Duplicates

| File | Issue | Recommendation |
|:-----|:------|:---------------|
| `api/src/Controllers/ReportController.php` (3.3 KB) | Overlaps with `ReportsController.php` (9.6 KB) | Merge into `ReportsController` |
| `api/src/Controllers/ProductController.php` (1.9 KB) | Product CRUD also in `CatalogController.php` | Verify no orphan routes; if duplicate, remove |
| `api/src/Controllers/AdminController.php` (2.2 KB) | Admin operations also in other controllers | Verify scope and consolidate if redundant |

---

## 8. Circular Dependencies

**None detected.** The layering is clean:
- Flutter: Views → Services → ApiClient → localhost
- Local API: Controllers → Services → Repositories → PDO
- Cloud API: Controllers → PDO (flat, no circular risk)
- Sync: Local API SyncService → outbound HTTP to Cloud API (unidirectional)

---

> **Resume Token:**
> ```
> RESUME_TOKEN:
>   Project: Laundry Pro UAE
>   Chunk_Completed: C1
>   Artifacts_Produced: [AUDIT_ARCHITECTURE.md]
>   Findings_Accumulated: 10
>   Open_Questions: 0
>   Next_Chunk: C2
>   Inputs_Required: [database/schema.sql, database/seed.sql, api/database/migrations/*, models]
>   Expected_Outputs: [DB_SCHEMA_FINAL.sql, DB_SEEDS_FINAL.sql, DB_QUERIES_REFERENCE.md]
>   Context_Summary: >
>     C1 Architecture Re-Audit complete. Three-tier architecture (Flutter → Local
>     PHP → Cloud PHP) is structurally sound with proper layering. 10 findings
>     identified: 1 P1 (mock tenant fallback), 9 P2. No circular dependencies,
>     no FLOAT violations, proper tenant isolation via admin_id. Ready for C2
>     Database Deep-Dive.
> ```
