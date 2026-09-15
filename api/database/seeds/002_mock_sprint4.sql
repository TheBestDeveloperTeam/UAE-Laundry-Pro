
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

