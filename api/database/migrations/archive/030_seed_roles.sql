-- Seed the remaining roles for Sprint 02

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

