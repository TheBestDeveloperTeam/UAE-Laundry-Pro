CREATE TABLE IF NOT EXISTS employees (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  employee_no VARCHAR(50) NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  phone VARCHAR(30) NULL,
  email VARCHAR(150) NULL,
  job_title VARCHAR(100) NULL,
  base_salary DECIMAL(18,2) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_employee_no (business_owner_id, employee_no),
  INDEX idx_emp_owner (business_owner_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS attendance (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  employee_id INT UNSIGNED NOT NULL,
  attendance_date DATE NOT NULL,
  status ENUM('present', 'absent', 'half_day', 'leave') NOT NULL DEFAULT 'present',
  check_in TIME NULL,
  check_out TIME NULL,
  notes VARCHAR(255) NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_attendance_day (employee_id, attendance_date),
  CONSTRAINT fk_att_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
  CONSTRAINT fk_att_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS leave_types (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  name VARCHAR(100) NOT NULL,
  is_paid TINYINT(1) NOT NULL DEFAULT 1,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS leave_requests (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  employee_id INT UNSIGNED NOT NULL,
  leave_type_id INT UNSIGNED NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status ENUM('pending', 'approved', 'rejected', 'cancelled') NOT NULL DEFAULT 'pending',
  reason TEXT NULL,
  approved_by INT UNSIGNED NULL,
  approved_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_leave_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
  CONSTRAINT fk_leave_type FOREIGN KEY (leave_type_id) REFERENCES leave_types(id),
  CONSTRAINT fk_leave_approver FOREIGN KEY (approved_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payroll_periods (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  status ENUM('open', 'closed') NOT NULL DEFAULT 'open',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_payroll_period (business_owner_id, period_start, period_end)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payroll_runs (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  payroll_period_id INT UNSIGNED NOT NULL,
  run_no VARCHAR(50) NOT NULL,
  total_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
  status ENUM('draft', 'posted') NOT NULL DEFAULT 'posted',
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pr_period FOREIGN KEY (payroll_period_id) REFERENCES payroll_periods(id),
  CONSTRAINT fk_pr_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payroll_lines (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  payroll_run_id INT UNSIGNED NOT NULL,
  employee_id INT UNSIGNED NOT NULL,
  base_salary DECIMAL(18,2) NOT NULL DEFAULT 0,
  advance_deduction DECIMAL(18,2) NOT NULL DEFAULT 0,
  net_pay DECIMAL(18,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_pl_run FOREIGN KEY (payroll_run_id) REFERENCES payroll_runs(id) ON DELETE CASCADE,
  CONSTRAINT fk_pl_employee FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS salary_advances (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  business_owner_id INT UNSIGNED NOT NULL DEFAULT 1,
  employee_id INT UNSIGNED NOT NULL,
  amount DECIMAL(18,2) NOT NULL,
  balance_remaining DECIMAL(18,2) NOT NULL,
  status ENUM('open', 'recovered', 'cancelled') NOT NULL DEFAULT 'open',
  notes VARCHAR(255) NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sa_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
  CONSTRAINT fk_sa_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO leave_types (uuid, business_owner_id, name, is_paid)
SELECT UUID(), 1, 'Annual Leave', 1
WHERE NOT EXISTS (SELECT 1 FROM leave_types WHERE name = 'Annual Leave' AND business_owner_id = 1);

INSERT INTO leave_types (uuid, business_owner_id, name, is_paid)
SELECT UUID(), 1, 'Sick Leave', 1
WHERE NOT EXISTS (SELECT 1 FROM leave_types WHERE name = 'Sick Leave' AND business_owner_id = 1);
