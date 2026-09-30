# LaundryPro UAE — Threat Model & Security Posture

> **Version:** 2.0.0 | **Authoritative Security Review** | **Standard:** STRIDE & OWASP ASVS 4.0

---

## 1. Threat Classification (STRIDE Matrix)

| Threat Category | Description in LaundryPro UAE Context | Inherent Risk | Implemented Countermeasure | Residual Risk |
|---|---|:---:|---|:---:|
| **Spoofing** | Attacker impersonates a cashier or cloud sync agent | High | RS256 JWT tokens; UMAC hardware fingerprint binding; 3-way handshake | Low |
| **Tampering** | User modifies local SQLite database directly or intercepts HTTP traffic | Critical | Write-once Windows Registry flags; DB password protection; TLS 1.3 | Low |
| **Repudiation** | Cashier deletes an order and claims it was never entered | High | Append-only `audit_logs` table; non-resettable sequential receipt numbering | Very Low |
| **Information Disclosure** | Competitor extracts customer database or pricing formulas | High | Argon2id password hashing; column-level encryption for sensitive tokens | Low |
| **Denial of Service** | Malicious local loop or external bot floods API | Medium | Token bucket rate limiting (120 req/min); payload size ceilings | Low |
| **Elevation of Privilege** | Cashier attempts to approve their own discount or view payroll | Critical | RBAC enforced strictly at API router level via `PermissionMiddleware` | Very Low |

---

## 2. Attack Vectors & Defensive Controls

### 2.1 Hardware Tampering & Clock Drift
- **Attack Scenario:** Store owner rolls back system clock on workstation to re-open a closed accounting period or bypass license expiration dates.
- **Defense:**
  - `system_guard_service.dart` and `LicenseController.php` verify monotonic forward progression of timestamps.
  - Periodic pings to Cloud NTP/API time servers.
  - If `system_time < last_recorded_transaction_time`, system enters emergency read-only lock.

### 2.2 Offline SQLite Database Extraction
- **Attack Scenario:** Disgruntled employee copies `laundrypro_offline.db` file from Windows workstation to an external flash drive.
- **Defense:**
  - Windows file system permissions restricted to `LOCAL_SERVICE` and dedicated app service accounts.
  - SQLCipher AES-256 database file encryption enabled on production client builds.

### 2.3 Cross-Tenant Data Leakage
- **Attack Scenario:** Tenant A submits a crafted `tenant_id` or UUID to inspect orders belonging to Tenant B on the central Cloud API.
- **Defense:**
  - `TenantScopeMiddleware` ignores client-submitted tenant IDs and binds queries strictly to the authenticated `tenant_id` extracted from the cryptographically verified JWT or Cloud Token.
  - Foreign key constraints strictly enforce tenant ownership across all child records.

### 2.4 Replay Attacks on Sync Ingestion
- **Attack Scenario:** Intercepted sync batch is re-submitted multiple times to duplicate orders or financial lines.
- **Defense:**
  - `entity_uuid` uniqueness constraint in `sync_records` and `sales_orders`.
  - Duplicate submissions are acknowledged as `accepted` without re-executing inserts (idempotency).
