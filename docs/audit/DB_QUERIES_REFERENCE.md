# LaundryPro UAE — DB_QUERIES_REFERENCE

## 1. CRUD & Prepared Statements

### 1.1 Customer Operations

**Create Customer:**
```sql
INSERT INTO customers (
  uuid, admin_id, local_id, customer_code, name, phone, email, 
  address_line1, city, emirate, customer_type, credit_limit
) VALUES (
  :uuid, :admin_id, :local_id, :customer_code, :name, :phone, :email, 
  :address_line1, :city, :emirate, :customer_type, :credit_limit
);
```

**Get Customer by ID (Tenant Scoped):**
```sql
SELECT * FROM customers 
WHERE id = :id AND admin_id = :admin_id 
LIMIT 1;
```

**Update Outstanding Balance:**
```sql
UPDATE customers 
SET outstanding_balance = outstanding_balance + :amount,
    updated_at = UTC_TIMESTAMP()
WHERE id = :id AND admin_id = :admin_id;
```

### 1.2 Sales Operations

**Create Sales Order:**
```sql
INSERT INTO sales_orders (
  uuid, admin_id, local_id, branch_id, terminal_id, customer_id, user_id,
  order_number, status, subtotal, discount, tax, total, 
  amount_paid, amount_due, created_at
) VALUES (
  :uuid, :admin_id, :local_id, :branch_id, :terminal_id, :customer_id, :user_id,
  :order_number, :status, :subtotal, :discount, :tax, :total,
  :amount_paid, :amount_due, UTC_TIMESTAMP()
);
```

## 2. Reporting & Aggregation

**Daily Sales Summary (by branch):**
```sql
SELECT 
  branch_id, 
  DATE(created_at) as sales_date,
  COUNT(id) as total_orders,
  SUM(total) as gross_sales,
  SUM(tax) as total_tax,
  SUM(amount_paid) as collected
FROM sales_orders
WHERE admin_id = :admin_id
  AND status NOT IN ('cancelled', 'void')
  AND created_at BETWEEN :start_date AND :end_date
GROUP BY branch_id, DATE(created_at);
```

## 3. Sync Push/Pull

**Fetch Pending Outbox Records (Local to Cloud):**
```sql
SELECT * FROM sync_outbox 
WHERE admin_id = :admin_id AND status = 'pending' 
ORDER BY id ASC 
LIMIT :limit;
```

**Mark Outbox as Synced:**
```sql
UPDATE sync_outbox 
SET status = 'synced', synced_at = UTC_TIMESTAMP(), updated_at = UTC_TIMESTAMP() 
WHERE id = :id;
```

## 4. License Validation

**Check Active License:**
```sql
SELECT * FROM license 
WHERE is_active = 1 
ORDER BY id DESC 
LIMIT 1;
```

## 5. Audit Log

**Insert Audit Log Entry:**
```sql
INSERT INTO audit_logs (
  user_id, action, entity_type, entity_id, payload, created_at
) VALUES (
  :user_id, :action, :entity_type, :entity_id, :payload, UTC_TIMESTAMP()
);
```
