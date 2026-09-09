-- Add account lockout fields for Sprint 02

ALTER TABLE users
  ADD COLUMN failed_attempts INT UNSIGNED NOT NULL DEFAULT 0 AFTER is_active,
  ADD COLUMN locked_until TIMESTAMP NULL DEFAULT NULL AFTER failed_attempts;

