-- LaundryPro UAE consolidated seed data (roles, users, phase-2 permissions)
-- Applied by SeedService / run_dev_seed.php

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000001', 'administrator', JSON_ARRAY('*'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'administrator');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000002', 'cashier', JSON_ARRAY('sales.create', 'sales.read', 'customers.read', 'catalog.read', 'inventory.read'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'cashier');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000003', 'manager', JSON_ARRAY('sales.*', 'inventory.*', 'customers.*', 'reports.sales'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'manager');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000004', 'storekeeper', JSON_ARRAY('inventory.*', 'purchase.receive'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'storekeeper');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000005', 'hr', JSON_ARRAY('hr.*', 'reports.hr'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'hr');

INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000006', 'auditor', JSON_ARRAY('reports.*'), 1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'auditor');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'business.name', JSON_QUOTE('LaundryPro UAE'), 'business'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'business.name' AND scope = 'business');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'locale.default', JSON_QUOTE('en'), 'system'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'locale.default' AND scope = 'system');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'currency.default', JSON_OBJECT('major', 'AED', 'minor', 'Fils', 'digits', 2), 'system'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'currency.default' AND scope = 'system');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'tax.vat_rate', JSON_QUOTE('0.05'), 'business'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'tax.vat_rate' AND scope = 'business');

INSERT INTO settings (setting_key, setting_value, scope)
SELECT 'tax.trn', JSON_QUOTE('100000000000003'), 'business'
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'tax.trn' AND scope = 'business');

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

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE batch_lots;
TRUNCATE TABLE batch_scan_events;
TRUNCATE TABLE sterilization_logs;
TRUNCATE TABLE process_logs;
TRUNCATE TABLE electronic_signatures;

INSERT IGNORE INTO equipment (id, asset_tag, equipment_type) VALUES (1, 'TAG-100', 'autoclave');
INSERT IGNORE INTO advanced_cycle_presets (id, service_id, cycle_name) VALUES (1, 1, 'Sterilization Default');
INSERT IGNORE INTO advanced_cycle_runs (id, uuid, sales_order_line_id, preset_id, equipment_id, operator_employee_id, status) VALUES (1, 'uuid-cycle-1', 1, 1, 1, 1, 'running');

SET FOREIGN_KEY_CHECKS = 1;

-- Default Super-Admin credentials:
-- Username: superadmin
-- Password: SuperAdmin@LaundryPro2026!
-- Hash generated via password_hash('SuperAdmin@LaundryPro2026!', PASSWORD_DEFAULT)

INSERT INTO cloud_super_admins (id, username, email, password_hash, full_name, role, is_active)
VALUES (
  1,
  'superadmin',
  'superadmin@magnificentsolution.co.in',
  '$2y$10$eE0oI9uL5O9B7zT7w7Nq6.H.w187QjXo2bWqC6cZyS85Ewh9bK87y',
  'Master Super Administrator',
  'super_admin',
  1
) ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;
-- ===== Append Missing Seed Data =====
INSERT INTO services (uuid, name, is_active) VALUES
('00000000-0000-4000-8000-000000000100', 'Dry-Clean', 1),
('00000000-0000-4000-8000-000000000101', 'Wash', 1),
('00000000-0000-4000-8000-000000000102', 'Iron-Normal', 1),
('00000000-0000-4000-8000-000000000103', 'Steam-Iron', 1),
('00000000-0000-4000-8000-000000000104', 'Steam-Wash', 1)
ON DUPLICATE KEY UPDATE is_active=1;

INSERT INTO settings (setting_key, setting_value, scope) VALUES
('license.bypass_development_mode', 'true', 'system')
ON DUPLICATE KEY UPDATE setting_value='true';
