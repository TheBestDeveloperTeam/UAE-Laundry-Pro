INSERT INTO roles (uuid, name, permissions, is_active)
SELECT '00000000-0000-4000-8000-000000000003', 'hr_manager',
  JSON_ARRAY('hr.read', 'hr.write', 'payroll.read', 'payroll.run', 'attendance.write', 'leave.approve'),
  1
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'hr_manager');

UPDATE roles SET permissions = JSON_ARRAY(
  'sales.create', 'sales.read', 'customers.read', 'catalog.read', 'inventory.read'
) WHERE name = 'cashier';
