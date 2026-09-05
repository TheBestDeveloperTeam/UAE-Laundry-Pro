ALTER TABLE sales_orders
  ADD COLUMN branch_id INT UNSIGNED NULL AFTER business_owner_id,
  ADD COLUMN terminal_id INT UNSIGNED NULL AFTER branch_id;

ALTER TABLE inventory_movements
  ADD COLUMN branch_id INT UNSIGNED NULL AFTER business_owner_id;

ALTER TABLE employees
  ADD COLUMN branch_id INT UNSIGNED NULL AFTER business_owner_id;

ALTER TABLE expenses
  ADD COLUMN branch_id INT UNSIGNED NULL AFTER business_owner_id;

UPDATE sales_orders SET branch_id = (SELECT id FROM branches LIMIT 1) WHERE branch_id IS NULL;
UPDATE employees SET branch_id = (SELECT id FROM branches LIMIT 1) WHERE branch_id IS NULL;
