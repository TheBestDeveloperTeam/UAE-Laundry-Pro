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
