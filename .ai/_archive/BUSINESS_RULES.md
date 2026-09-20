# Business Rules: LaundryPro UAE

## Order Status Machine

### Standard Lifecycle
RECEIVED → IN_PROCESS → READY → DELIVERED

### Extended Lifecycle
DRAFT → CONFIRMED → RECEIVED → SORTING → PROCESSING → QUALITY_CHECK
      → PACKED → READY_FOR_COLLECTION → OUT_FOR_DELIVERY → DELIVERED → CLOSED

### Exception States
ON_HOLD | REWORK_REQUIRED | PARTIALLY_READY | LOST_DAMAGED_REVIEW | CANCELLED

### Quality Failure Loop
QUALITY_CHECK → REWORK_REQUIRED → PROCESSING → QUALITY_CHECK

Rules:
- Every transition: permission-controlled + audit-logged
- No direct table update from UI for status changes
- API enforces state machine transitions

## Pricing Rules
- Price profiles: Standard, Corporate, Premium, Walk-In, Seasonal, Customer-Specific
- UAE VAT: 5% applied on subtotal
- Line discount: permission-controlled (sales.discount_line)
- Order discount: permission-controlled (sales.discount_order)
- Rate override: permission-controlled (sales.override_rate) + mandatory reason
- All pricing snapshots at time of sale (historical integrity)
- Modifiers: Fixed / Per-Unit / Percentage pricing
- Rounding: to nearest Fils (2 decimal places AED)

## Inventory Rules
- Stock is movement-driven (ledger): append-only
- Movement types: Opening, Purchase Receipt, Purchase Return, Sale Issue, Sale Return,
  Adjustment In/Out, Transfer In/Out, Damage, Loss, Found, Bundle Explode/Assemble
- Negative stock: configurable (allow with warning | block)
- Low stock threshold: per-product, triggers alert
- Valuation: FIFO (weighted average as option)

## Payment Rules
- Payment types: Cash, Credit/Pending, Debit, Cheque
- Partial payment: allowed; creates outstanding balance
- Idempotency: X-Idempotency-Key on all write APIs
- Cash drawer: opens ONLY on cash payment or authorized manual open
- Every drawer open: audit-logged with user + reason + timestamp

## Discount Rules
- Line discount: before tax; does not affect tax base
- Order discount: after line sum, before tax
- Discount requires permission; maximum % may be role-limited

## Document Numbering
- All numbers: server-side atomic generation (never client-generated)
- Format: PREFIX-YYYY-000001 (sequential, no gaps)
- Invoice: INV-YYYY-000001
- Receipt: REC-YYYY-000001
- Credit Memo: CM-YYYY-000001
- Debit Memo: DM-YYYY-000001
- Challan: CHL-YYYY-000001
- GRN: GRN-YYYY-000001
- Order: LP-{YYYY}-{BRANCH}-{00001}
