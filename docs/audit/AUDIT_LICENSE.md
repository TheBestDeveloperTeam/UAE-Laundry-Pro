# LaundryPro UAE — C10: License 3-Way Handshake Audit

> **Chunk:** C10 | **Date:** 2026-10-07 | **Status:** ✅ COMPLETE
> **Auditor:** Project Delivery Production Manager

---

## 1. Handshake Architecture Overview

The mandate requires a strict **3-Way Handshake** to prevent piracy and ensure secure offline capability:
1. **Flutter POS:** Captures the License Key and hardware details.
2. **Local API (PHP):** Validates the key, generates a hardware UMAC, records the identity, and verifies with the Cloud API using a cryptographic signature.
3. **Cloud API (PHP):** Issues the token and signs the response.
4. **Registry Guard:** A Windows OS-level Write-Once registry key must be set to prevent infinite trial resets by simply dropping the local database.

---

## 2. Component Verification

| Step | Component | Status | Observation |
|:-----|:----------|:-------|:------------|
| 1 | Flutter Key Capture | ✅ PASS | Flutter captures the key and routes it to the local `/api/v1/license/activate`. |
| 2 | UMAC Generation | ✅ PASS | `LicenseService::activate` correctly generates a hardware-bound UMAC and records it. |
| 3 | Cloud Verification | ❌ **FAIL** | Local `LicenseService` blindly inserts the license into the local DB. It **never verifies** the key against the Cloud API's cryptographic signature. |
| 4 | Registry Guard | ❌ **FAIL** | No OS-level Windows Registry guard is implemented. Hardware identity is stored in a local MySQL table (`hardware_identity`), which is easily bypassed by wiping the DB. |
| 5 | Dev Bypass | ❌ **FAIL** | `license.bypass_development_mode` is seeded in the DB but is completely ignored by the PHP code. |

---

## 3. Gap Analysis (Findings)

| ID | Severity | Area | Gap / Defect | Fix Plan | Effort |
|:---|:---------|:-----|:-------------|:---------|:-------|
| G-023 | P0 | Security / Licensing | **Blind Activation Bypass:** Local `LicenseService::activate` accepts *any* arbitrary string and blindly activates the local POS without verifying the Cloud API's cryptographic signature. | Rewrite `LicenseService::activate` to synchronously call Cloud `/api/v1/license/validate`, verify the HMAC SHA-256 signature, and only activate if valid. | M |
| G-024 | P1 | Security / Licensing | **Missing Registry Guard:** The Write-Once Windows Registry integration is completely missing. | Implement a PowerShell wrapper or PHP `exec()` script to write/read a protected HKLM registry key during activation and trial tracking. | M |
| G-025 | P2 | Configuration | `bypass_development_mode` config is seeded but never evaluated. | Add logic in `LicenseService` to read this config and bypass checks gracefully if set to true. | S |

---

## 4. Next Steps & Fix Roadmap

- **Sprint 1 (Immediate Blockers):**
  - Refactor `LicenseService.php` to strictly enforce the cryptographic signature verification (G-023).
  - Scaffold the PowerShell script for the Windows Registry Write-Once guard and bind it to the Local API (G-024).

- **Sprint 2 (Polish):**
  - Implement the `bypass_development_mode` evaluation flag (G-025).

---

> **Resume Token:**
> ```
> RESUME_TOKEN:
>   Project: Laundry Pro UAE
>   Chunk_Completed: C10
>   Artifacts_Produced: [AUDIT_LICENSE.md]
>   Findings_Accumulated: 37
>   Open_Questions: 0
>   Next_Chunk: C11
>   Inputs_Required: [Auth/RBAC logic, Audit Trail scripts]
>   Expected_Outputs: [AUDIT_SECURITY.md]
>   Context_Summary: >
>     C10 License 3-Way Handshake Audit complete. Discovered a P0 security vulnerability: 
>     the Local API blindly accepts any license key string and activates locally without verifying 
>     the Cloud API's cryptographic signature. Furthermore, the OS-level Windows Registry guard 
>     is missing (P1). Ready for C11 Security, RBAC, & Audit Trail Audit.
> ```
