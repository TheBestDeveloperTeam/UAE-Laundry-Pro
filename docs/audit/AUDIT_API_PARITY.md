# LaundryPro UAE — C5: API Parity Diff & Unification

> **Chunk:** C5 | **Date:** 2026-10-07 | **Status:** ✅ COMPLETE
> **Auditor:** Project Delivery Production Manager

---

## 1. Parity Audit Overview

The core requirement (AC-6) demands **99.99% API Parity** between the Local API (178 endpoints) and Cloud API (189 endpoints) to guarantee the offline-first experience.

**Whitelisted Differences:**
1. Base URL (`localhost:8000` vs `cloud.magnificentsolution.co.in`)
2. Tenant Scope (`admin_id` inference from Local DB vs `TenantScopeMiddleware` from Bearer token)
3. Auth Role (Local DB vs Cloud DB roles)
4. Rate Limit values (Strict on Cloud, Loose on Local)
5. `/api/v1/admin/console/*` (Cloud Super-Admin only)
6. `/api/v1/license/approve` (Cloud only)
7. `/api/v1/sync/*` (Cloud gateway sync hooks)

---

## 2. API Parity Diff Findings

| Endpoint / Domain | Local Status | Cloud Status | Defect Status |
|:------------------|:-------------|:-------------|:--------------|
| **Auth & Identity** | Present | Present | ✅ Match |
| **Sales & POS** | Present | Present | ✅ Match |
| **Customers** | Present | Present | ✅ Match |
| **HR & Payroll** | Present | Present | ✅ Match |
| **Inventory & Purchasing** | Present | Present | ✅ Match |
| **Catalog & Services** | Present | Present | ✅ Match |
| **Sync Management** | `Push`/`Pull` outbox | `Push`/`Pull` inbox gateway | ✅ Whitelisted Difference |
| **Tenant Aliases** | Not needed | `/api/v1/tenant/*` | ✅ Whitelisted Difference |
| **Super Admin Console** | Not needed | ❌ Missing from routes | ❗ P1 Defect (Found in C4) |
| **LAN / Peripherals** | `/api/v1/lan/bind` | `/api/v1/lan/bind` | ❗ P0 Defect: Cloud API should not have LAN binding endpoints |
| **Local Setup** | `/api/v1/install/*` | `/api/v1/install/*` | ❗ P0 Defect: Cloud API should not have local setup wizard endpoints |

---

## 3. Parity Gaps & P0 Defects

| ID | Severity | Area | Gap / Defect | Fix Plan | Effort |
|:---|:---------|:-----|:-------------|:---------|:-------|
| G-010 | P0 | API Parity | Cloud API exposes Local-only hardware routes (`/api/v1/lan/bind`, `/api/v1/rfid/scan`). | Remove physical hardware/LAN routes from `cloud-api/routes/api.php`. Cloud only receives synced records of these events, it does not execute them. | S |
| G-011 | P0 | API Parity | Cloud API exposes `/api/v1/install/*` local setup routes. | Remove local installation/seed wizard routes from the Cloud API router. | S |
| G-012 | P2 | API Parity | OpenAPI metadata (`meta.server`) identical; Swagger UI doesn't clearly delineate Local vs Cloud. | Update the Swagger generation logic in `DocsController` / `CloudApiController` to inject the correct server host URL and title. | S |

---

## 4. Unification Roadmap

- **Step 1:** Strip physical peripheral endpoints (LAN, Hardware RFID scans) from the Cloud API.
- **Step 2:** Strip local installation endpoints from the Cloud API.
- **Step 3:** Inject the Super-Admin endpoints into the Cloud API.
- **Step 4:** Ensure the Swagger JSON generation properly tags `Local` vs `Cloud` in the OpenAPI `info.title`.

---

> **Resume Token:**
> ```
> RESUME_TOKEN:
>   Project: Laundry Pro UAE
>   Chunk_Completed: C5
>   Artifacts_Produced: [AUDIT_API_PARITY.md, UNIFIED_API_LIST_FINAL.md]
>   Findings_Accumulated: 24
>   Open_Questions: 0
>   Next_Chunk: C6
>   Inputs_Required: [Flutter source tree, lib/router, lib/views]
>   Expected_Outputs: [AUDIT_FLUTTER.md]
>   Context_Summary: >
>     C5 API Parity Diff & Unification complete. Identified two P0 defects where the Cloud API 
>     incorrectly exposes local hardware/LAN endpoints and local installation endpoints. 
>     Whitelisted differences (Sync, Tenant aliases) verified. Unified API list generated. 
>     Ready for C6 Flutter Frontend Audit.
> ```
