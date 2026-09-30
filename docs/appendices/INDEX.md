# LaundryPro UAE — Master Documentation Index & ADRs

> **Version:** 2.0.0 | **Authoritative Documentation Sitemap** | **Status:** Active

---

## 1. Documentation Library Sitemap

```
docs/
├── architecture/
│   ├── SYSTEM_ARCHITECTURE.md        # Comprehensive architecture & request lifecycles
│   └── COMPONENT_MAP.md              # File-level component inventory & responsibility matrix
├── api/
│   ├── LOCAL_API_REFERENCE.md        # Local Station REST API endpoints & envelopes
│   ├── CLOUD_API_REFERENCE.md        # Central Cloud Multi-Tenant REST API endpoints
│   └── RESPONSE_CODES.md             # Standard error codes & HTTP response glossary
├── sync/
│   ├── SYNC_ARCHITECTURE.md          # Outbox/Inbox delta synchronization pipeline
│   └── CONFLICT_RESOLUTION.md        # 3-Way merge algorithm & dead-letter queue rules
├── licensing/
│   └── LICENSE_ARCHITECTURE.md       # 3-Way hardware handshake (UMAC & Windows Registry)
├── security/
│   ├── SECURITY_MODEL.md             # Cryptographic tokens, RBAC & server authorization
│   └── THREAT_MODEL.md               # STRIDE threat matrix & hardening controls
├── compliance/
│   └── UAE_COMPLIANCE.md             # UAE FTA 5% VAT, bilingual e-invoicing & WPS SIF
├── flows/
│   ├── ORDER_LIFECYCLE.md            # Intake, heat-seal tagging, factory dispatch & rack staging
│   └── PAYMENT_FLOW.md               # Multi-tender settlement, split payments & credit notes
├── testing/
│   ├── TEST_PLAN.md                  # Unit, integration, contract & sync stress test plans
│   └── UAT_SCRIPTS.md                # Cashier & manager step-by-step validation scripts
├── operations/
│   ├── DEPLOYMENT_GUIDE.md           # Local Apache/XAMPP, Windows daemon & Docker cloud setup
│   └── BACKUP_RESTORE.md             # 3-2-1 backup strategy & disaster recovery runbook
├── peripherals/
│   └── PRINTER_INTEGRATION.md        # 80mm ESC/POS thermal printers, care tags & cash drawers
├── ui/
│   └── THEME_SPECIFICATION.md        # "Purple Dark" enterprise theme tokens & AdminLTE overrides
├── training/
│   ├── ADMIN_GUIDE.md                # Store manager & portal administration manual
│   └── CASHIER_GUIDE.md              # Front-desk POS cashier training guide
├── multitenancy/
│   └── TENANT_ISOLATION.md           # Cloud row-level isolation & tenant query scoping
├── blueprints/
│   └── ENTERPRISE_DEPLOYMENT_BLUEPRINT.md # Boutique, LAN branch & central factory topologies
├── requirements/
│   └── PRD_FUNCTIONAL_REQUIREMENTS.md# Product requirements document & non-functionals
├── user-journeys/
│   └── CUSTOMER_JOURNEYS.md          # Walk-in, home delivery & corporate contract journeys
├── workflows/
│   └── BUSINESS_WORKFLOWS.md         # Garment classification, chemical dosing & QC
├── edge-cases/
│   └── OFFLINE_FAILURE_MODES.md      # Outage recovery, SQLite lock contention & clock skew
├── integrations/
│   └── ERP_GATEWAY_INTEGRATIONS.md   # Tally/Zoho export, banking terminals & WhatsApp API
├── data/
│   └── DATA_DICTIONARY.md            # Master database table definitions & indexing schema
├── forms/
│   └── FORM_SPECIFICATIONS.md        # Field rules, input masks & bilingual error messages
├── reference/
│   └── GLOSSARY.md                   # Laundry, textile care & UAE fiscal glossary
├── appendices/
│   └── INDEX.md                      # Master documentation index & ADR records
├── dependencies/
│   └── DEPENDENCY_MATRIX.md          # Software requirements, PHP extensions & Flutter packages
├── marketing/
│   └── FEATURE_MATRIX.md             # Edition feature matrix: Standard vs Premium vs Enterprise
└── swagger/
    ├── UNIFIED_SWAGGER.yaml          # Authoritative unified OpenAPI 3.0.3 YAML spec
    ├── local-api.yaml                # Local Station OpenAPI 3.0.3 YAML spec
    └── cloud-api.yaml                # Cloud Gateway OpenAPI 3.0.3 YAML spec
```

---

## 2. Architectural Decision Records (ADRs)

### ADR-001: Separation of Local API and Cloud Multi-Tenant API
- **Context**: A single monolithic codebase running both workstation POS operations and central cloud hosting led to tangled dependencies, insecure privilege boundaries, and database bloat.
- **Decision**: Physically separate the repository into two clean PHP 8.2 projects:
  1. `api/`: Local Station API running on localhost:8080.
  2. `cloud-api/`: Central Multi-Tenant Cloud API running on central HTTPS servers.
- **Status**: **Approved & Implemented**.

### ADR-002: Dual-Database Schema Split
- **Context**: A unified monolithic `schema.sql` contained duplicate table definitions (`businesses`, `sync_records`) and conflated local store data with central multi-tenant licenses.
- **Decision**: Split into `database/local/schema.sql` (single-tenant per workstation) and `database/cloud/schema.sql` (central multi-tenant with `tenant_id` foreign keys).
- **Status**: **Approved & Implemented**.

### ADR-003: Pure Outbox/Inbox V2 Sync Architecture
- **Context**: Direct synchronization between the Flutter UI client and Cloud API caused UI freezes, connection drops, and bypassed local business validation rules.
- **Decision**: Enforce that the Flutter app communicates **exclusively with Local API**. Synchronization is handled strictly by the local PHP background daemon talking to Cloud API using an asynchronous outbox/inbox pipeline.
- **Status**: **Approved & Implemented**.

### ADR-004: Strict Server-Side Authorization
- **Context**: Client-side role checking allowed malicious clients or rogue API calls to elevate privileges.
- **Decision**: All authorization decisions, role evaluations, and tenant query scoping are executed strictly on the server via `AuthMiddleware`, `PermissionMiddleware`, and `TenantScopeMiddleware`.
- **Status**: **Approved & Implemented**.

### ADR-005: 3-Way Hardware Handshake Anti-Tamper
- **Context**: Desktop POS installations were vulnerable to unauthorized copying and license piracy.
- **Decision**: Implement a 3-way cryptographic handshake combining physical hardware UMAC, write-once Windows Registry flags, and Cloud API RSA verification.
- **Status**: **Approved & Implemented**.

### ADR-006: "Purple Dark" Unified Design System
- **Context**: Inconsistent visual styling between Flutter desktop screens and web admin portals created a disjointed user experience.
- **Decision**: Mandate the "Purple Dark" enterprise theme (`#0d0f17` canvas, `#161926` surface, `#7c3aed` violet accent) across all Flutter views and AdminLTE v4 portal views.
- **Status**: **Approved & Implemented**.

### ADR-007: Mandatory `bcmath` Precision for Financial Calculations
- **Context**: Standard floating-point math (`float`) in PHP can produce IEEE-754 rounding inaccuracies in 5% UAE VAT calculations.
- **Decision**: Enforce PHP `bcmath` arbitrary-precision mathematics across all monetary, discount, and tax calculations.
- **Status**: **Approved & Implemented**.
