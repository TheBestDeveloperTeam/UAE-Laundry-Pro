# LaundryPro UAE — Comprehensive Master Test Plan

> **Version:** 2.0.0 | **Authoritative Quality Assurance Strategy**

---

## 1. Testing Strategy & Pyramid

```
           / \
          /   \     End-to-End (E2E) & User Acceptance Testing (UAT)
         / UAT \    (Hardware printers, offline simulation, scanner flow)
        /-------\
       /  Integ  \  Integration & Contract Tests
      /   Tests   \ (PHP API <-> MariaDB, Flutter Service <-> Mock API)
     /-------------\
    /     Unit      \ Unit Tests
   /     Tests       \ (Business rules, VAT math, JWT validation, 3-way merge)
  /-------------------\
```

---

## 2. Test Execution Matrix

| Test Suite | Scope | Target Framework / Tool | Frequency | Pass Criteria |
|---|---|---|---|---|
| **Core PHP Units** | Services, Repositories, Helpers, bcmath VAT logic | PHPUnit 10 / CLI Test Runner | Every Commit | 100% Pass; >80% Code Coverage |
| **API Contract Tests**| Response envelope validation against `docs/swagger/UNIFIED_SWAGGER.yaml` | PHP / Spectral CLI | Pre-Merge | Zero Schema Validation Errors |
| **Sync Engine Stress**| 1,000+ records pushed under network latency & disconnection | `tests/sync_stress.php` | Nightly | Zero Data Loss; Deterministic Convergence |
| **Hardware Emulation**| 80mm ESC/POS printer byte stream & barcode validation | Virtual Serial Port / Socket | Release Candidate| Correct TLV QR & Arabic Code Page |
| **Flutter Widget Tests**| POS Cart, Customer Search, Touch Keypad, Screen Navigation | `flutter test` | Every PR | All screens render without overflow |
| **Security Pen-Test** | Injection, IDOR, Broken Authentication, CSRF | OWASP ZAP & Custom Scripts | Major Release | Zero High/Critical Vulnerabilities |

---

## 3. Critical Path Test Scenarios

### 3.1 Scenario: Offline POS Checkout & Post-Reconnect Sync
1. Disconnect Ethernet cable from POS workstation.
2. Complete 5 customer orders with cash and card tenders in POS UI.
3. Verify that orders, invoices, and customer balances update in local SQLite database immediately.
4. Verify that thermal receipts print normally offline.
5. Reconnect Ethernet cable.
6. Verify that `SyncDaemon` automatically detects connectivity, pushes all 5 orders to Cloud API within 60 seconds, and receives ACKs without conflict.

### 3.2 Scenario: Concurrent Status Mutation (3-Way Merge Test)
1. Order #1001 exists on Cloud API with status `confirmed`.
2. Workstation A goes offline and marks Order #1001 as `in_process`.
3. Cloud Admin portal marks Order #1001 as `ready`.
4. Workstation A reconnects and executes sync pull.
5. Verify that the 3-way merge correctly applies `ready` (higher status precedence) and updates local state without throwing an exception.

### 3.3 Scenario: VAT Precision Verification
1. Create an order with 3 items of unit price 14.2857 AED.
2. Verify total gross amount, total taxable amount, and total VAT using `bcmath`.
3. Ensure rounding is exactly 2 decimal places and matches FTA tax schedule.
