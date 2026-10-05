-- ============================================================================
-- Migration: 002_performance_compound_indexes.sql
-- Domain: Sales & Outbox Compound Indexes Optimization (TSK-1.2)
-- ============================================================================

-- 1. Compound index on sales_orders for tenant dashboard queries, filtering by status and date
CREATE INDEX IF NOT EXISTS idx_sales_admin_status_created 
  ON sales_orders (admin_id, status, created_at);

-- 2. Compound index on sales_orders for payment aging and reconciliation
CREATE INDEX IF NOT EXISTS idx_sales_admin_payment_status 
  ON sales_orders (admin_id, payment_status, created_at);

-- 3. Compound index on sync_outbox for high-throughput batch worker polling
CREATE INDEX IF NOT EXISTS idx_outbox_admin_synced_attempts 
  ON sync_outbox (admin_id, synced_at, sync_attempts, created_at);

-- 4. Compound index on customer search by tenant and phone
CREATE INDEX IF NOT EXISTS idx_customers_admin_phone 
  ON customers (admin_id, phone);
