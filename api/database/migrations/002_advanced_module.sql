-- Laundry Pro Desktop � Advanced Module Additive Schema
-- Sprint 2: Data Model Extension
CREATE TABLE IF NOT EXISTS advanced_cycle_presets (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    service_id INT UNSIGNED NOT NULL,
    cycle_name VARCHAR(150) NOT NULL,
    temperature_c DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    duration_minutes INT NOT NULL DEFAULT 0,
    detergent_ratio DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    spin_speed_rpm INT NOT NULL DEFAULT 0,
    chemical_dosage_map JSON NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_cycle_preset_service FOREIGN KEY (service_id) REFERENCES services(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS equipment (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    asset_tag VARCHAR(100) NOT NULL UNIQUE,
    equipment_type VARCHAR(100) NOT NULL,
    last_calibration_date DATE NULL,
    next_calibration_due DATE NULL,
    out_of_service TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS advanced_cycle_runs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE,
    sales_order_line_id INT UNSIGNED NOT NULL,
    preset_id INT UNSIGNED NOT NULL,
    equipment_id INT UNSIGNED NOT NULL,
    operator_employee_id INT UNSIGNED NOT NULL,
    status ENUM('running', 'exception', 'completed') NOT NULL DEFAULT 'running',
    started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    CONSTRAINT fk_cycle_run_sol FOREIGN KEY (sales_order_line_id) REFERENCES sales_order_lines(id),
    CONSTRAINT fk_cycle_run_preset FOREIGN KEY (preset_id) REFERENCES advanced_cycle_presets(id),
    CONSTRAINT fk_cycle_run_equipment FOREIGN KEY (equipment_id) REFERENCES equipment(id),
    CONSTRAINT fk_cycle_run_operator FOREIGN KEY (operator_employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS process_logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cycle_run_id INT UNSIGNED NOT NULL,
    metric_type ENUM('ph', 'temperature') NOT NULL,
    reading_value DECIMAL(18,2) NOT NULL,
    threshold_min DECIMAL(18,2) NOT NULL,
    threshold_max DECIMAL(18,2) NOT NULL,
    pass_fail TINYINT(1) NOT NULL,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_process_log_cycle FOREIGN KEY (cycle_run_id) REFERENCES advanced_cycle_runs(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS sterilization_logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cycle_run_id INT UNSIGNED NOT NULL,
    autoclave_program VARCHAR(150) NOT NULL,
    pressure_kpa DECIMAL(18,2) NOT NULL,
    temperature_c DECIMAL(18,2) NOT NULL,
    duration_minutes INT NOT NULL,
    validation_result ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sterilization_log_cycle FOREIGN KEY (cycle_run_id) REFERENCES advanced_cycle_runs(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS chemical_usage_logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id INT UNSIGNED NOT NULL,
    cycle_run_id INT UNSIGNED NOT NULL,
    lot_number VARCHAR(100) NOT NULL,
    expiry_date DATE NOT NULL,
    quantity_used DECIMAL(18,2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_chemical_log_product FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_chemical_log_cycle FOREIGN KEY (cycle_run_id) REFERENCES advanced_cycle_runs(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS batch_lots (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    lot_number VARCHAR(100) NOT NULL UNIQUE,
    expiry_date DATE NOT NULL,
    origin_sales_order_id INT UNSIGNED NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_batch_lot_order FOREIGN KEY (origin_sales_order_id) REFERENCES sales_orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS batch_scan_events (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    batch_lot_id INT UNSIGNED NOT NULL,
    scan_type ENUM('in', 'out') NOT NULL,
    device_id VARCHAR(100) NOT NULL,
    scanned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_batch_scan_lot FOREIGN KEY (batch_lot_id) REFERENCES batch_lots(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS calibration_records (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    equipment_id INT UNSIGNED NOT NULL,
    calibrated_at DATE NOT NULL,
    performed_by VARCHAR(150) NOT NULL,
    certificate_ref VARCHAR(150) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_calibration_equipment FOREIGN KEY (equipment_id) REFERENCES equipment(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS operator_certifications (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    certification_name VARCHAR(150) NOT NULL,
    issued_at DATE NOT NULL,
    expires_at DATE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_operator_cert_emp FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS electronic_signatures (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cycle_run_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NOT NULL,
    signature_hash CHAR(64) NOT NULL,
    meaning VARCHAR(150) NOT NULL,
    signed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_esign_cycle FOREIGN KEY (cycle_run_id) REFERENCES advanced_cycle_runs(id),
    CONSTRAINT fk_esign_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS controlled_garments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED NOT NULL,
    garment_tag VARCHAR(100) NOT NULL UNIQUE,
    iso_class VARCHAR(50) NOT NULL,
    wash_cycle_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cg_customer FOREIGN KEY (customer_id) REFERENCES customers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS gowning_logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    controlled_garment_id INT UNSIGNED NOT NULL,
    employee_id INT UNSIGNED NOT NULL,
    event_type ENUM('gowning', 'degowning') NOT NULL,
    event_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_gl_garment FOREIGN KEY (controlled_garment_id) REFERENCES controlled_garments(id),
    CONSTRAINT fk_gl_emp FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS cloud_agent (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id INT UNSIGNED NOT NULL,
    cloud_agent_id CHAR(36) NOT NULL UNIQUE,
    agent_secret_hash VARCHAR(255) NOT NULL,
    registered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_handshake_at TIMESTAMP NULL,
    CONSTRAINT fk_cloud_agent_business FOREIGN KEY (business_id) REFERENCES business(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS loyalty_ledger (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED NOT NULL,
    points_delta INT NOT NULL,
    reason VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ll_customer FOREIGN KEY (customer_id) REFERENCES customers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE sync_outbox ADD COLUMN status ENUM('pending', 'synced', 'failed') NOT NULL DEFAULT 'pending', ADD COLUMN next_retry_at TIMESTAMP NULL DEFAULT NULL;
