# Algorithms & Business Logic Reference

This document details all algorithmic formulas, security evaluations, state transition matrices, and business rules implemented across **LaundryPro UAE**.

---

## 1. Hardware Identity & Anti-Tamper Evaluation (UMAC)

### 1.1 Unique Machine Access Code (UMAC) Derivation
To prevent unlicensed multi-machine copying of pre-installed XAMPP instances, the workstation generates a non-spoofable hardware fingerprint:

\text{Seed} = \text{CPU\_ID} \parallel \text{Motherboard\_Serial} \parallel \text{Machine\_GUID}

1. **Extraction (WMI):**
   - CPU Identifier: wmic cpu get processorid
   - Motherboard Serial: wmic baseboard get serialnumber
   - OS GUID: HKLM\SOFTWARE\Microsoft\Cryptography\MachineGuid
2. **Hashing & Formatting:**
   \text{Hash} = \text{SHA256}(\text{Seed})
   \text{UMAC} = \text{''UMAC-''} \parallel \text{Upper}(\text{Substring}(\text{Hash}, 0, 4)) \parallel \text{''-''} \parallel \text{Upper}(\text{Substring}(\text{Hash}, 4, 4)) \parallel \text{''-''} \parallel \text{Upper}(\text{Substring}(\text{Hash}, 8, 4))
   Example: UMAC-8F2A-49C1-77B0

### 1.2 Clock-Rollback Tamper Guard (Registry Pulse)
To detect user tampering with Windows system time:
- The app stores InstallPulse (epoch timestamp) and RunCount encrypted in HKCU\Software\LaundryProUAE\Evaluation.
- On boot, if:
  \text{CurrentSystemTime} < \text{StoredInstallPulse}
  The system immediately triggers EvaluationStatus::CLOCK_TAMPERED, locks transactional POS operations, and forces administrator recovery.

### 1.3 Trial Hard-Limits
In unactivated or evaluation mode:
- **Maximum Lifespan:** 7 days ($\le 604,800$ seconds from irst_run_at).
- **Maximum Total Invoices:** $\le 9$ orders (sales_orders).
- **Maximum Total Customers:** $\le 9$ customers (customers).
If any threshold is exceeded, POS cart transitions to read-only with a modal prompt to input or import a .lic key.

---

## 2. Sales, VAT & Pricing Calculation

### 2.1 Standard Line-Item Calculation
For any order line item with unit price $, quantity $, discount amount {line}$, and tax rate $ (default \%$ in UAE):

\text{Subtotal} = P \times Q
\text{TaxableAmount} = \max(0, \text{Subtotal} - D_{line})
\text{TaxAmount} = \text{Round}_{2}\left(\text{TaxableAmount} \times \frac{T}{100}\right)
\text{LineTotal} = \text{TaxableAmount} + \text{TaxAmount}

### 2.2 Order Level Aggregation & Rounding (Fils Compliance)
\text{OrderSubtotal} = \sum \text{LineSubtotal}
\text{OrderDiscount} = \sum D_{line} + D_{order}
\text{OrderTax} = \sum \text{TaxAmount}
\text{GrossTotal} = \text{Round}_{2}(\text{OrderSubtotal} - \text{OrderDiscount} + \text{OrderTax})
All currency calculations round strictly using standard Banker''s Rounding (PHP_ROUND_HALF_UP) to 2 decimal places (Fils precision: .00 \text{ AED} = 100 \text{ Fils}$).

### 2.3 Immutable Order Snapshots
When an order is confirmed:
- A JSON snapshot of the service name, category, modifier selections, and tax rate is frozen into sales_order_line_snapshots.
- Changes to future catalog prices or tax laws never alter historically finalized invoices or reprint receipts.

---

## 3. Order Lifecycle State Machine

`
[DRAFT]
   │ (Confirm Order)
   ▼
[RECEIVED] ──────────────────────────┐
   │ (Send to Factory/Washing)       │
   ▼                                 │
[PROCESSING]                         │ (Direct Quick Delivery)
   │ (Ironed, Packed & QC Passed)    │
   ▼                                 ▼
[READY] ───────────────────────────> [DELIVERED]
   │                                     │
   ▼                                     ▼
[CANCELLED]                          [ARCHIVED]
`

- Transition to DELIVERED requires:
  \text{TotalPaid} \ge \text{GrossTotal} \quad \lor \quad \text{Customer.AllowCredit} = \text{true}

---

## 4. Payroll & WPS Salary Calculation

Under UAE Federal Decree-Law No. 33 of 2021 (UAE Labour Law) and WPS:

### 4.1 Daily Rate Derivation
\text{DailyRate} = \frac{\text{BasicSalary}}{30}

### 4.2 Net Pay Formula
\text{AllowancesTotal} = \text{Housing} + \text{Transport} + \text{Other}
\text{GrossEarnings} = \text{BasicSalary} + \text{AllowancesTotal} + \text{OvertimePay}
\text{Deductions} = \text{UnpaidLeaveDeduction} + \text{SalaryAdvances} + \text{Penalties}
\text{NetSalary} = \max(0, \text{GrossEarnings} - \text{Deductions})

Where:
\text{UnpaidLeaveDeduction} = \text{UnpaidDays} \times \text{DailyRate}
\text{OvertimePay} = \text{OvertimeHours} \times \left( \frac{\text{DailyRate}}{8} \times 1.25 \right)

---

## 5. Offline-First Bi-Directional Delta Sync Algorithm

`mermaid
graph TD
    A[Local Event Occurs<br/>Create / Update / Status] --> B[Write to Local Domain Table]
    B --> C[Write Event Record to sync_outbox<br/>status='pending', retry_count=0]
    C --> D{Scheduler Tick<br/>sync_scheduler.php}
    D -->|Check Internet & Cloud Health| E[Package Batch up to 50 Records]
    E --> F[POST /api/v1/sync/push<br/>to Central Cloud]
    F -->|200 OK Response| G[Update sync_outbox<br/>status='synced', synced_at=NOW()]
    F -->|Failure / Offline| H[Increment retry_count<br/>Exponential Backoff: 2^n * 5s]
`

### 5.1 Conflict Resolution Strategy: Last-Write-Wins (LWW) with Tenant Authority
- **Local Master Records:** Sales orders, customer balances, payments, and stock movements generated on the local node take precedence.
- If a cloud conflict occurs, the record with the higher microsecond timestamp updated_at wins, and a conflict audit log entry is preserved in cloud_audit_logs.
