-- LaundryPro UAE consolidated seed data (roles, users, phase-2 permissions)
-- Applied by SeedService / run_dev_seed.php

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000001', 'administrator', JSON_ARRAY('*'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'administrator');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000002', 'cashier', JSON_ARRAY('sales.create', 'sales.read', 'customers.read'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'cashier');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000003', 'hr_manager',
  JSON_ARRAY('hr.read', 'hr.write', 'payroll.read', 'payroll.run', 'attendance.write', 'leave.approve'),
  1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'hr_manager');

UPDATE roles SET permissions = JSON_ARRAY(
  'sales.create', 'sales.read', 'customers.read', 'catalog.read', 'inventory.read'
) WHERE name = 'cashier';

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'business.name', JSON_QUOTE('LaundryPro UAE'), 'business'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'business.name' AND scope = 'business');

INSERT INTO users (uuid, role_id, username, password_hash, full_name, email, is_active)
SELECT
  '00000000-0000-4000-8000-000000000010',
  r.id,
  'admin',
  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  'System Administrator',
  'admin@laundrypro.local',
  1
FROM roles r
WHERE r.name = 'administrator'
  AND NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');

INSERT INTO users (uuid, role_id, username, password_hash, full_name, email, is_active)
SELECT
  '00000000-0000-4000-8000-000000000011',
  r.id,
  'cashier',
  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  'POS Cashier',
  'cashier@laundrypro.local',
  1
FROM roles r
WHERE r.name = 'cashier'
  AND NOT EXISTS (SELECT 1 FROM users WHERE username = 'cashier');
