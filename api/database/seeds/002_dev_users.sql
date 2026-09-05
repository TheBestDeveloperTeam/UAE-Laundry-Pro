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
