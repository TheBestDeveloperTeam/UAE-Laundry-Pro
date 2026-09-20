# LaundryPro UAE: Algorithms & Feature Review

## 1. Core Algorithms

### 1.1 Financial Precision Engine (`bcmath`)
All financial aggregations in the API strictly avoid native floating-point math to prevent IEEE-754 precision drift.

**Algorithm:**
1. Fetch lines from DB as `DECIMAL(18,2)` strings.
2. Initialize `grand_total = '0.00'`.
3. Loop lines:
   - `line_total = bcmul(qty_string, price_string, 2)`
   - `line_total = bcsub(line_total, discount_string, 2)`
   - `grand_total = bcadd(grand_total, line_total, 2)`
4. Apply VAT (5%):
   - `tax_amount = bcmul(grand_total, '0.05', 2)`
   - `final_grand_total = bcadd(grand_total, tax_amount, 2)`
5. Return JSON payload encapsulating values as strings.

### 1.2 Offline-First Sync Backoff Algorithm
When pushing local changes to the cloud from `sync_outbox`, network failures trigger an exponential backoff to preserve system resources.

**Algorithm:**
1. Daemon queries `SELECT * FROM sync_outbox WHERE status IN ('pending', 'failed') AND next_retry_at <= NOW() LIMIT 100`.
2. For each record, `POST` to cloud.
3. If `200 OK`, `UPDATE status = 'synced'`.
4. If Network Timeout or `5xx`:
   - `attempts = attempts + 1`
   - If `attempts > 10`: `status = 'dead_letter'`
   - Else: `delay = power(2, attempts) * 60` seconds.
   - `next_retry_at = NOW() + delay`

### 1.3 Inventory Concurrency Lock
To prevent negative inventory when two terminals sell the same product simultaneously.

**Algorithm:**
1. `BEGIN TRANSACTION;`
2. `SELECT qty_on_hand FROM products WHERE id = X FOR UPDATE;` (Locks row)
3. If `qty_on_hand - req_qty < 0`: Rollback & throw `InsufficientStockException`.
4. `UPDATE products SET qty_on_hand = qty_on_hand - req_qty;`
5. `INSERT INTO inventory_movements ...`
6. `COMMIT;` (Releases lock)

---

## 2. Feature Review & Screen Index

| UI Screen | Feature Set | State |
|---|---|---|
| **AppShell** | Navigation rail, localized RTL/LTR, sync status indicator, dynamic theming. | Production Ready |
| **Dashboard** | 60s auto-refresh, top KPIs, financial trend arrows, quick actions. | Production Ready |
| **POS Screen** | Barcode scanning integration, split payments panel, `bcmath` mirrored calculations. | Production Ready |
| **Catalog** | `AppDataTable` integration, 2000+ item pagination, image attachment mapping. | Production Ready |
| **Customers** | CRM tracking, outstanding balance calculations, WhatsApp quick-link integration. | Production Ready |
| **Peripherals** | Epson/Citizen thermal printer integration via ESC/POS protocol, cash drawer pulse testing. | Production Ready |
| **Shift Close** | Blind cash entry, variance calculation logic, forced Z-Report printing. | Production Ready |
| **Settings** | UI bindings to `system_settings` table, dynamic VAT adjustments, licensing UMAC verifications. | Production Ready |

### Final Readiness Assessment
The runtime features operate accurately. The frontend is fully decoupled from the backend state via offline repositories. All components meet strict deployment specifications.
