# LaundryPro UAE — Offline Edge Cases & Failure Modes

> **Version:** 2.0.0 | **Authoritative Resilience & Fault-Tolerance Manual**

---

## 1. Matrix of Critical Failure Modes & Self-Healing Behaviors

| Failure Mode | Root Cause | System Immediate Reaction | Self-Healing / Recovery Path |
|---|---|---|---|
| **Abrupt Power Loss Mid-Checkout** | Store blackout or unplugged cord | OS ungraceful shutdown | SQLite / MariaDB WAL rollback ensures atomicity; uncommitted order is cleanly aborted; no partial financial records |
| **Extended Offline Period (> 7 Days)** | Telecom ISP fiber cut | System continues 100% normal POS operations locally | Sync outbox queues mutations; upon reconnect, backoff throttles batch size to prevent saturating cloud link |
| **Printer Cutter Jam / Out of Paper** | Paper roll depleted mid-print | Printer asserts offline status byte | POS displays "Printer Offline" modal; once paper is replaced, "Reprint Last Receipt" button executes without duplicating sales record |
| **Clock Skew / Dead CMOS Battery** | BIOS battery fails; date reverts to year 2000 | System clock verification check fails | POS locks checkout to prevent invalid tax invoice timestamps; displays prompt to synchronize NTP or update Windows clock |
| **SQLite Busy / Lock Contention** | Multiple background threads query DB simultaneously | SQLite database lock timeout | Retry policy with exponential jitter (max 5 retries, 250ms backoff); WAL mode enables concurrent readers while writing |
| **Corrupted Local DB File** | Bad storage sector or sudden disk crash | SQLite reports `database disk image is malformed` | System alerts cashier; switches to emergency fallback DB and triggers automated restore from last nightly snapshot |

---

## 2. Deep Dive: Handling Sync Outbox Buffer Overflow

If a store remains offline for months while processing thousands of transactions:
1. **Queue Prioritization**:
   - High Priority: Customer balance settlements, Invoices, Payments.
   - Medium Priority: Sales order status changes, Garment tracking tags.
   - Low Priority: Inventory adjustments, Attendance logs.
2. **Chunked Streaming**:
   - `SyncDaemon` enforces a maximum batch ceiling of **100 records per HTTP request**.
   - Cloud API responds with individual accepted UUIDs, ensuring that if a transmission is interrupted at record 75, records 1–74 remain acknowledged and will not be retransmitted.
