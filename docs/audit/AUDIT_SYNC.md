# LaundryPro UAE — C9: Sync Engine Audit

> **Chunk:** C9 | **Date:** 2026-10-07 | **Status:** ✅ COMPLETE
> **Auditor:** Project Delivery Production Manager

---

## 1. Sync Architecture Overview

The multi-tenant architecture relies on a **Row-by-Row Outbox Pattern** to maintain 99.99% parity between the Local XAMPP instances and the Central Cloud.

**Observed Flow:**
1. **Local Outbox:** Data mutations are captured in `sync_outbox` locally.
2. **Push Scheduler:** `api/sync_scheduler.php` runs periodically (e.g., cron/Task Scheduler), fetching batches of 100 pending tasks.
3. **Cloud Inbox:** `CloudApiController::syncPush` receives the JSON payload, verifies UMAC and tenant tokens, and writes to `sync_records`.
4. **Acknowledgement:** Cloud returns `accepted` and `rejected` UUIDs; Local updates the outbox status/retry counts.

---

## 2. Sync Verification Checklist

| Mechanism | Status | Notes |
|:----------|:-------|:------|
| **Bidirectional Push/Pull** | ❌ **FAIL** | `sync_scheduler.php` only implements `PUSH`. There is no logic fetching or applying Cloud-to-Local updates (`PULL`). |
| **Idempotency** | ✅ PASS | Cloud `syncPush` uses `ON DUPLICATE KEY UPDATE` to gracefully handle duplicated packets. |
| **Failure Backoff** | ⚠️ MIXED | Retries increment `attempts`, but there is no exponential backoff or poison-pill quarantine if a payload repeatedly fails. |
| **Data Application** | ❌ **FAIL** | The Cloud API writes pushed data into the `sync_records` table, but **never unpacks or applies** the JSON payloads into the actual business tables (`customers`, `sales_orders`, etc.). |

---

## 3. Gap Analysis (Findings)

| ID | Severity | Area | Gap / Defect | Fix Plan | Effort |
|:---|:---------|:-----|:-------------|:---------|:-------|
| G-019 | P1 | Sync Engine | `CloudApiController::syncPush` only stores data in `sync_records` and does not apply the payload to actual operational tables. | Implement an asynchronous queue or synchronous unpacker in Cloud API to hydrate `sync_records` into real tables. | L |
| G-020 | P1 | Sync Engine | Local `sync_scheduler.php` lacks the `PULL` implementation. | Add `syncPull` call after `syncPush` succeeds, and write a local applicator to unpack Cloud updates into Local tables. | M |
| G-021 | P2 | Sync Engine | Missing exponential backoff for failed sync attempts. | Update `sync_scheduler.php` query to ignore rows where `attempts > 5` or apply backoff timing. | S |
| G-022 | P2 | Sync Engine | No deterministic conflict resolution strategy implemented. | Introduce a Last-Write-Wins (LWW) or version-based comparison before applying incoming payloads on both ends. | M |

---

## 4. Next Steps & Fix Roadmap

- **Sprint 1 (Immediate Blockers):**
  - Build the Cloud Hydration Engine to unpack `sync_records` into the Cloud database (G-019).
  - Implement `syncPull` logic inside the Local `sync_scheduler.php` daemon (G-020).

- **Sprint 2 (Technical Debt):**
  - Implement Last-Write-Wins conflict resolution (G-022).
  - Add exponential backoff to `sync_scheduler.php` (G-021).

---

> **Resume Token:**
> ```
> RESUME_TOKEN:
>   Project: Laundry Pro UAE
>   Chunk_Completed: C9
>   Artifacts_Produced: [AUDIT_SYNC.md]
>   Findings_Accumulated: 34
>   Open_Questions: 0
>   Next_Chunk: C10
>   Inputs_Required: [License verification logic, registry scripts]
>   Expected_Outputs: [AUDIT_LICENSE.md]
>   Context_Summary: >
>     C9 Sync Engine Audit complete. Identified two P1 gaps: The Cloud API never unpacks 
>     the incoming payloads into the actual business tables (it just dumps them in sync_records), 
>     and the Local daemon (sync_scheduler.php) only PUSHES data but never PULLS it. 
>     Idempotency is respected. Ready for C10 License Handshake Audit.
> ```
