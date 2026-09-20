# Unified Development Roadmap â€” LaundryPro UAE
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