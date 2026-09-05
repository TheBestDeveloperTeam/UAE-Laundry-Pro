CREATE TABLE IF NOT EXISTS analytics_daily_snapshots (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  branch_id INT UNSIGNED NULL,
  snapshot_date DATE NOT NULL,
  metric_key VARCHAR(50) NOT NULL,
  metric_value DECIMAL(18,4) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_analytics_day (business_owner_id, branch_id, snapshot_date, metric_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
