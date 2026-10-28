// Bulk L10N Key Injector for UAE-Laundry-Pro
// Uses Node.js to avoid PowerShell encoding issues with Arabic text

const fs = require('fs');
const path = require('path');

const projectRoot = 'e:/Projects/Flutter/UAE-Laundry-Pro';
const enPath = path.join(projectRoot, 'assets/lang/en.json');
const arPath = path.join(projectRoot, 'assets/lang/ar.json');

// Load existing
let en = JSON.parse(fs.readFileSync(enPath, 'utf8'));
let ar = JSON.parse(fs.readFileSync(arPath, 'utf8'));

// New keys to add
const newKeys = {
    // Settings Screen
    "settings_global_paths": ["Global Paths & Directories", "\u0627\u0644\u0645\u0633\u0627\u0631\u0627\u062a \u0648\u0627\u0644\u0645\u062c\u0644\u062f\u0627\u062a \u0627\u0644\u0639\u0627\u0645\u0629"],
    "settings_global_paths_desc": ["Backup, logs, receipts, images, and export directories", "\u0645\u062c\u0644\u062f\u0627\u062a \u0627\u0644\u0646\u0633\u062e \u0627\u0644\u0627\u062d\u062a\u064a\u0627\u0637\u064a \u0648\u0627\u0644\u0633\u062c\u0644\u0627\u062a \u0648\u0627\u0644\u0625\u064a\u0635\u0627\u0644\u0627\u062a \u0648\u0627\u0644\u0635\u0648\u0631 \u0648\u0627\u0644\u062a\u0635\u062f\u064a\u0631"],
    "settings_roles_perms": ["Roles & Permissions", "\u0627\u0644\u0623\u062f\u0648\u0627\u0631 \u0648\u0627\u0644\u0635\u0644\u0627\u062d\u064a\u0627\u062a"],
    "settings_roles_perms_desc": ["Manage user authorization and access roles", "\u0625\u062f\u0627\u0631\u0629 \u0627\u0644\u062a\u0641\u0648\u064a\u0636\u0627\u062a \u0648\u0623\u062f\u0648\u0627\u0631 \u0627\u0644\u0648\u0635\u0648\u0644 \u0644\u0644\u0645\u0633\u062a\u062e\u062f\u0645\u064a\u0646"],
    "settings_disaster_recovery": ["Disaster recovery, SHA-256 verification, and snapshot restore", "\u0627\u0633\u062a\u0639\u0627\u062f\u0629 \u0627\u0644\u0643\u0648\u0627\u0631\u062b\u060c \u0627\u0644\u062a\u062d\u0642\u0642 SHA-256\u060c \u0648\u0627\u0633\u062a\u0639\u0627\u062f\u0629 \u0627\u0644\u0644\u0642\u0637\u0627\u062a"],
    "settings_backup_snapshots": ["Backup Snapshots History", "\u0633\u062c\u0644 \u0644\u0642\u0637\u0627\u062a \u0627\u0644\u0646\u0633\u062e \u0627\u0644\u0627\u062d\u062a\u064a\u0627\u0637\u064a"],
    "settings_no_backups": ["No backup archives created yet.", "\u0644\u0627 \u062a\u0648\u062c\u062f \u0623\u0631\u0634\u064a\u0641\u0627\u062a \u0646\u0633\u062e \u0627\u062d\u062a\u064a\u0627\u0637\u064a \u0628\u0639\u062f."],
    "settings_file_label": ["File: {file}", "\u0627\u0644\u0645\u0644\u0641: {file}"],
    "settings_target_archive": ["Target Archive: {file}", "\u0627\u0644\u0623\u0631\u0634\u064a\u0641 \u0627\u0644\u0645\u0633\u062a\u0647\u062f\u0641: {file}"],
    "settings_dry_run_status": ["Dry Run Status: {status} ({count} SQL statements)", "\u062d\u0627\u0644\u0629 \u0627\u0644\u0627\u062e\u062a\u0628\u0627\u0631: {status} ({count} \u062c\u0645\u0644 SQL)"],

    // Sync Settings Screen
    "sync_outbox_queue": ["SQLite Outbox Queue ({count} Staged)", "\u0642\u0627\u0626\u0645\u0629 \u0627\u0646\u062a\u0638\u0627\u0631 SQLite ({count} \u0645\u064f\u0631\u062d\u0651\u0644)"],
    "sync_queued_label": ["Queued: {time}", "\u0641\u064a \u0627\u0644\u0627\u0646\u062a\u0638\u0627\u0631: {time}"],
    "sync_conflict_audit_log": ["Sync Conflict Audit Log", "\u0633\u062c\u0644 \u062a\u062f\u0642\u064a\u0642 \u062a\u0639\u0627\u0631\u0636\u0627\u062a \u0627\u0644\u0645\u0632\u0627\u0645\u0646\u0629"],
    "sync_inspect_payloads": ["Inspect Staged Payloads", "\u0641\u062d\u0635 \u0627\u0644\u062d\u0645\u0648\u0644\u0627\u062a \u0627\u0644\u0645\u0631\u062d\u0644\u0629"],
    "sync_view_conflicts": ["View Conflict History", "\u0639\u0631\u0636 \u0633\u062c\u0644 \u0627\u0644\u062a\u0639\u0627\u0631\u0636\u0627\u062a"],
    "sync_merge_strategy_title": ["Deterministic 3-Way Merge Strategy Active", "\u0627\u0633\u062a\u0631\u0627\u062a\u064a\u062c\u064a\u0629 \u0627\u0644\u062f\u0645\u062c \u062b\u0644\u0627\u062b\u064a \u0627\u0644\u0627\u062a\u062c\u0627\u0647 \u0646\u0634\u0637\u0629"],
    "sync_merge_strategy_desc": ["Cloud Master Sequence ID tracking with automated replay recovery.", "\u062a\u062a\u0628\u0639 \u0645\u0639\u0631\u0641 \u0627\u0644\u062a\u0633\u0644\u0633\u0644 \u0627\u0644\u0631\u0626\u064a\u0633\u064a \u0627\u0644\u0633\u062d\u0627\u0628\u064a \u0645\u0639 \u0627\u0633\u062a\u0631\u062f\u0627\u062f \u0625\u0639\u0627\u062f\u0629 \u0627\u0644\u062a\u0634\u063a\u064a\u0644 \u0627\u0644\u062a\u0644\u0642\u0627\u0626\u064a."],
    "sync_error": ["Sync Error: {error}", "\u062e\u0637\u0623 \u0641\u064a \u0627\u0644\u0645\u0632\u0627\u0645\u0646\u0629: {error}"],

    // Sterilization Screen
    "sterilization_supervisor_name": ["Certified Supervisor / QA Name *", "\u0627\u0633\u0645 \u0627\u0644\u0645\u0634\u0631\u0641 \u0627\u0644\u0645\u0639\u062a\u0645\u062f / \u0636\u0645\u0627\u0646 \u0627\u0644\u062c\u0648\u062f\u0629 *"],
    "sterilization_supervisor_hint": ["e.g. Dr. Amina Al-Zaabi", "\u0645\u062b\u0627\u0644: \u062f. \u0623\u0645\u064a\u0646\u0629 \u0627\u0644\u0632\u0639\u0627\u0628\u064a"],
    "sterilization_pin": ["Operator Security PIN *", "\u0631\u0645\u0632 \u0623\u0645\u0627\u0646 \u0627\u0644\u0645\u0634\u063a\u0644 *"],
    "sterilization_pin_hint": ["4-digit authorization code", "\u0631\u0645\u0632 \u062a\u0641\u0648\u064a\u0636 \u0645\u0646 4 \u0623\u0631\u0642\u0627\u0645"],
    "sterilization_attestation": ["Regulatory Attestation / Meaning *", "\u0625\u0642\u0631\u0627\u0631 \u062a\u0646\u0638\u064a\u0645\u064a / \u0627\u0644\u0645\u0639\u0646\u0649 *"],
    "sterilization_sign_certify": ["Sign & Certify", "\u062a\u0648\u0642\u064a\u0639 \u0648\u0627\u0639\u062a\u0645\u0627\u062f"],
    "sterilization_enter_details": ["Please enter supervisor name and security PIN", "\u064a\u0631\u062c\u0649 \u0625\u062f\u062e\u0627\u0644 \u0627\u0633\u0645 \u0627\u0644\u0645\u0634\u0631\u0641 \u0648\u0631\u0645\u0632 \u0627\u0644\u0623\u0645\u0627\u0646"],
    "sterilization_lot_certified": ["Sterilization Lot certified with digital e-signature", "\u062a\u0645 \u0627\u0639\u062a\u0645\u0627\u062f \u062f\u0641\u0639\u0629 \u0627\u0644\u062a\u0639\u0642\u064a\u0645 \u0628\u062a\u0648\u0642\u064a\u0639 \u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a \u0631\u0642\u0645\u064a"],
    "sterilization_signing_error": ["Signing error: {error}", "\u062e\u0637\u0623 \u0641\u064a \u0627\u0644\u062a\u0648\u0642\u064a\u0639: {error}"],
    "sterilization_affix_signature": ["Affix Electronic Signature", "\u062a\u062b\u0628\u064a\u062a \u0627\u0644\u062a\u0648\u0642\u064a\u0639 \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a"],
    "sterilization_close_details": ["Close Details", "\u0625\u063a\u0644\u0627\u0642 \u0627\u0644\u062a\u0641\u0627\u0635\u064a\u0644"],
    "sterilization_needs_sign": ["Needs Sign", "\u064a\u062d\u062a\u0627\u062c \u062a\u0648\u0642\u064a\u0639"],
    "sterilization_affix_sig_tooltip": ["Affix Signature", "\u062a\u062b\u0628\u064a\u062a \u0627\u0644\u062a\u0648\u0642\u064a\u0639"],
    "sterilization_autoclave_program": ["Sterilization Autoclave Program", "\u0628\u0631\u0646\u0627\u0645\u062c \u0623\u0648\u062a\u0648\u0643\u0644\u0627\u0641 \u0627\u0644\u062a\u0639\u0642\u064a\u0645"],
    "sterilization_target_temp": ["Target Temp (\u00b0C)", "\u062f\u0631\u062c\u0629 \u0627\u0644\u062d\u0631\u0627\u0631\u0629 \u0627\u0644\u0645\u0633\u062a\u0647\u062f\u0641\u0629 (\u00b0\u0645)"],
    "sterilization_pressure": ["Pressure (bar)", "\u0627\u0644\u0636\u063a\u0637 (\u0628\u0627\u0631)"],
    "sterilization_duration": ["Duration (min)", "\u0627\u0644\u0645\u062f\u0629 (\u062f\u0642\u064a\u0642\u0629)"],
    "sterilization_error": ["Error: {error}", "\u062e\u0637\u0623: {error}"],

    // Setup Wizard Screen
    "wizard_install_complete": ["Installation & initial setup completed successfully!", "\u0627\u0643\u062a\u0645\u0644 \u0627\u0644\u062a\u062b\u0628\u064a\u062a \u0648\u0627\u0644\u0625\u0639\u062f\u0627\u062f \u0627\u0644\u0623\u0648\u0644\u064a \u0628\u0646\u062c\u0627\u062d!"],
    "wizard_install_error": ["Installation error: {error}", "\u062e\u0637\u0623 \u0641\u064a \u0627\u0644\u062a\u062b\u0628\u064a\u062a: {error}"],
    "wizard_currency_aed": ["UAE Dirham (AED / Fils)", "\u062f\u0631\u0647\u0645 \u0625\u0645\u0627\u0631\u0627\u062a\u064a (AED / \u0641\u0644\u0633)"],
    "wizard_currency_sar": ["Saudi Riyal (SAR / Halala)", "\u0631\u064a\u0627\u0644 \u0633\u0639\u0648\u062f\u064a (SAR / \u0647\u0644\u0644\u0629)"],
    "wizard_printer_80mm": ["Thermal Roll Paper (80mm / 48 chars)", "\u0648\u0631\u0642 \u062d\u0631\u0627\u0631\u064a \u0645\u0644\u0641\u0648\u0641 (80 \u0645\u0645 / 48 \u062d\u0631\u0641)"],
    "wizard_printer_58mm": ["Thermal Roll Paper (58mm / 32 chars)", "\u0648\u0631\u0642 \u062d\u0631\u0627\u0631\u064a \u0645\u0644\u0641\u0648\u0641 (58 \u0645\u0645 / 32 \u062d\u0631\u0641)"],
    "wizard_printer_a4": ["Laser/Inkjet A4 Standard", "\u0637\u0627\u0628\u0639\u0629 \u0644\u064a\u0632\u0631/\u062d\u0628\u0631 A4 \u0642\u064a\u0627\u0633\u064a"],
    "wizard_printer_dot": ["Dot-Matrix 80-Col (Carbon Copy)", "\u0637\u0627\u0628\u0639\u0629 \u0646\u0642\u0637\u064a\u0629 80 \u0639\u0645\u0648\u062f (\u0646\u0633\u062e\u0629 \u0643\u0631\u0628\u0648\u0646\u064a\u0629)"],
    "wizard_email_label": ["Email", "\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a"],
    "wizard_emirate_label": ["Emirate", "\u0627\u0644\u0625\u0645\u0627\u0631\u0629"],
    "wizard_address_label": ["Physical Address", "\u0627\u0644\u0639\u0646\u0648\u0627\u0646 \u0627\u0644\u0641\u0639\u0644\u064a"],
    "wizard_currency_label": ["Currency", "\u0627\u0644\u0639\u0645\u0644\u0629"],
    "wizard_invoice_prefix": ["Invoice Prefix (e.g. INV-)", "\u0628\u0627\u062f\u0626\u0629 \u0627\u0644\u0641\u0627\u062a\u0648\u0631\u0629 (\u0645\u062b\u0627\u0644: INV-)"],
    "wizard_receipt_prefix": ["Receipt Prefix (e.g. REC-)", "\u0628\u0627\u062f\u0626\u0629 \u0627\u0644\u0625\u064a\u0635\u0627\u0644 (\u0645\u062b\u0627\u0644: REC-)"],
    "wizard_challan_prefix": ["Challan Prefix (e.g. CHL-)", "\u0628\u0627\u062f\u0626\u0629 \u0627\u0644\u0633\u0646\u062f (\u0645\u062b\u0627\u0644: CHL-)"],
    "wizard_grn_prefix": ["GRN Prefix (e.g. GRN-)", "\u0628\u0627\u062f\u0626\u0629 GRN (\u0645\u062b\u0627\u0644: GRN-)"],
    "wizard_api_secret": ["API Installation Secret (from api/.env)", "\u0645\u0641\u062a\u0627\u062d \u0623\u0645\u0627\u0646 API (\u0645\u0646 api/.env)"],
    "wizard_backup_dir": ["Canonical Backup Directory (BACKUP_PATH)", "\u0645\u062c\u0644\u062f \u0627\u0644\u0646\u0633\u062e \u0627\u0644\u0627\u062d\u062a\u064a\u0627\u0637\u064a \u0627\u0644\u0623\u0633\u0627\u0633\u064a (BACKUP_PATH)"],
    "wizard_printer_label": ["Primary Slip Printer Default", "\u0627\u0644\u0637\u0627\u0628\u0639\u0629 \u0627\u0644\u0627\u0641\u062a\u0631\u0627\u0636\u064a\u0629 \u0644\u0644\u0625\u064a\u0635\u0627\u0644\u0627\u062a"],
    "wizard_license_hint": ["Optional: Enter activation key or leave blank for 7-day evaluation", "\u0627\u062e\u062a\u064a\u0627\u0631\u064a: \u0623\u062f\u062e\u0644 \u0645\u0641\u062a\u0627\u062d \u0627\u0644\u062a\u0641\u0639\u064a\u0644 \u0623\u0648 \u0627\u062a\u0631\u0643\u0647 \u0641\u0627\u0631\u063a\u0627\u064b \u0644\u0644\u062a\u0642\u064a\u064a\u0645 \u0644\u0645\u062f\u0629 7 \u0623\u064a\u0627\u0645"],

    // Terminals Screen
    "terminal_lan_ip": ["LAN Binding IP Address", "\u0639\u0646\u0648\u0627\u0646 IP \u0644\u0644\u0634\u0628\u0643\u0629 \u0627\u0644\u0645\u062d\u0644\u064a\u0629"],
    "terminal_lan_ip_hint": ["192.168.1.100", "192.168.1.100"],
    "terminal_mac": ["Hardware MAC Address", "\u0639\u0646\u0648\u0627\u0646 MAC \u0644\u0644\u062c\u0647\u0627\u0632"],
    "terminal_mac_hint": ["XX:XX:XX:XX:XX:XX", "XX:XX:XX:XX:XX:XX"],
    "terminal_auth_token": ["Hardware Security Auth Token", "\u0631\u0645\u0632 \u0623\u0645\u0627\u0646 \u0627\u0644\u062c\u0647\u0627\u0632"],
    "terminal_create_branch_first": ["Please create a branch first before pairing terminals", "\u064a\u0631\u062c\u0649 \u0625\u0646\u0634\u0627\u0621 \u0641\u0631\u0639 \u0623\u0648\u0644\u0627\u064b \u0642\u0628\u0644 \u0631\u0628\u0637 \u0627\u0644\u0645\u062d\u0637\u0627\u062a"],
    "terminal_regen_token": ["Regenerate Token", "\u0625\u0639\u0627\u062f\u0629 \u0625\u0646\u0634\u0627\u0621 \u0627\u0644\u0631\u0645\u0632"],

    // Role Editor Screen
    "role_load_failed": ["Failed to load roles", "\u0641\u0634\u0644 \u0641\u064a \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0623\u062f\u0648\u0627\u0631"],
    "role_updated": ["Role updated successfully", "\u062a\u0645 \u062a\u062d\u062f\u064a\u062b \u0627\u0644\u062f\u0648\u0631 \u0628\u0646\u062c\u0627\u062d"],
    "role_update_failed": ["Failed to update role", "\u0641\u0634\u0644 \u0641\u064a \u062a\u062d\u062f\u064a\u062b \u0627\u0644\u062f\u0648\u0631"],
    "role_grant_all": ["Grant All (*)", "\u0645\u0646\u062d \u0627\u0644\u0643\u0644 (*)"],
    "role_clear_all": ["Clear All", "\u0645\u0633\u062d \u0627\u0644\u0643\u0644"],
    "role_title_hint": ["Role Title (e.g. Branch Supervisor)", "\u0639\u0646\u0648\u0627\u0646 \u0627\u0644\u062f\u0648\u0631 (\u0645\u062b\u0627\u0644: \u0645\u0634\u0631\u0641 \u0627\u0644\u0641\u0631\u0639)"],

    // Vendors Screen
    "vendor_save_failed": ["Failed to save vendor: {error}", "\u0641\u0634\u0644 \u062d\u0641\u0638 \u0627\u0644\u0645\u0648\u0631\u062f: {error}"],
    "vendor_bank_hint": ["e.g. Emirates NBD, IBAN: AE070260000000000000000", "\u0645\u062b\u0627\u0644: \u0628\u0646\u0643 \u0627\u0644\u0625\u0645\u0627\u0631\u0627\u062a \u062f\u0628\u064a \u0627\u0644\u0648\u0637\u0646\u064a\u060c IBAN: AE070260000000000000000"],
    "vendor_search_hint": ["Search by vendor name, phone, or TRN...", "\u0627\u0644\u0628\u062d\u062b \u0628\u0627\u0633\u0645 \u0627\u0644\u0645\u0648\u0631\u062f \u0623\u0648 \u0627\u0644\u0647\u0627\u062a\u0641 \u0623\u0648 \u0627\u0644\u0631\u0642\u0645 \u0627\u0644\u0636\u0631\u064a\u0628\u064a..."],

    // Salary Advances Screen
    "salary_reason_notes": ["Reason / Notes", "\u0627\u0644\u0633\u0628\u0628 / \u0645\u0644\u0627\u062d\u0638\u0627\u062a"],

    // RFID Screen
    "rfid_reader_ip": ["Reader IPv4 Address", "\u0639\u0646\u0648\u0627\u0646 IPv4 \u0644\u0644\u0642\u0627\u0631\u0626"],
    "rfid_reader_ip_hint": ["192.168.1.180", "192.168.1.180"],
    "rfid_tcp_port": ["TCP Port (LLRP/ASCII)", "\u0645\u0646\u0641\u0630 TCP (LLRP/ASCII)"],
    "rfid_tcp_port_hint": ["5084", "5084"],
    "rfid_reader_settings": ["Reader Hardware Settings", "\u0625\u0639\u062f\u0627\u062f\u0627\u062a \u0623\u062c\u0647\u0632\u0629 \u0627\u0644\u0642\u0627\u0631\u0626"],
    "rfid_clear_scanned": ["Clear Scanned", "\u0645\u0633\u062d \u0627\u0644\u0645\u0645\u0633\u0648\u062d"],

    // Purchasing Screen
    "purchasing_product": ["Product", "\u0627\u0644\u0645\u0646\u062a\u062c"],
    "purchasing_qty": ["Qty", "\u0627\u0644\u0643\u0645\u064a\u0629"],
    "purchasing_unit_cost_label": ["Unit Cost", "\u062a\u0643\u0644\u0641\u0629 \u0627\u0644\u0648\u062d\u062f\u0629"],
    "purchasing_delivery_note": ["Supplier Delivery Note / Bill of Lading (BOL)", "\u0645\u0630\u0643\u0631\u0629 \u062a\u0633\u0644\u064a\u0645 \u0627\u0644\u0645\u0648\u0631\u062f / \u0628\u0648\u0644\u064a\u0635\u0629 \u0627\u0644\u0634\u062d\u0646 (BOL)"],
    "purchasing_delivery_note_hint": ["e.g. DN-984321", "\u0645\u062b\u0627\u0644: DN-984321"],
    "purchasing_inspector_notes": ["Receiving Inspector Notes / Quality Checks", "\u0645\u0644\u0627\u062d\u0638\u0627\u062a \u0645\u0641\u062a\u0634 \u0627\u0644\u0627\u0633\u062a\u0644\u0627\u0645 / \u0641\u062d\u0648\u0635\u0627\u062a \u0627\u0644\u062c\u0648\u062f\u0629"],
    "purchasing_inspector_notes_hint": ["Packaging intact, seals verified, stored in Bay A", "\u0627\u0644\u062a\u063a\u0644\u064a\u0641 \u0633\u0644\u064a\u0645\u060c \u0627\u0644\u0623\u062e\u062a\u0627\u0645 \u0645\u062d\u0642\u0642\u0629\u060c \u0645\u062e\u0632\u0646 \u0641\u064a \u0627\u0644\u062e\u0644\u064a\u062c A"],

    // Production Screen
    "production_qc_notes": ["QC / Audit Notes (Optional)", "\u0645\u0644\u0627\u062d\u0638\u0627\u062a \u0627\u0644\u062c\u0648\u062f\u0629 / \u0627\u0644\u062a\u062f\u0642\u064a\u0642 (\u0627\u062e\u062a\u064a\u0627\u0631\u064a)"],

    // Pending Invoices Screen
    "pending_amount_label": ["Amount (AED)", "\u0627\u0644\u0645\u0628\u0644\u063a (\u062f\u0631\u0647\u0645)"],

    // Operator Screen
    "operator_select_employee": ["Select Employee *", "\u0627\u062e\u062a\u064a\u0627\u0631 \u0627\u0644\u0645\u0648\u0638\u0641 *"],
    "operator_cert_program": ["Certification Program *", "\u0628\u0631\u0646\u0627\u0645\u062c \u0627\u0644\u0634\u0647\u0627\u062f\u0629 *"],

    // Leave Screen
    "leave_type_label": ["Leave Type", "\u0646\u0648\u0639 \u0627\u0644\u0625\u062c\u0627\u0632\u0629"],
    "leave_reason": ["Reason for Leave", "\u0633\u0628\u0628 \u0627\u0644\u0625\u062c\u0627\u0632\u0629"],
    "leave_approve_tooltip": ["Approve Leave", "\u0627\u0644\u0645\u0648\u0627\u0641\u0642\u0629 \u0639\u0644\u0649 \u0627\u0644\u0625\u062c\u0627\u0632\u0629"],
    "leave_reject_tooltip": ["Reject Leave", "\u0631\u0641\u0636 \u0627\u0644\u0625\u062c\u0627\u0632\u0629"],

    // Expenses Screen
    "expense_approve_tooltip": ["Approve", "\u0645\u0648\u0627\u0641\u0642\u0629"],
    "expense_reject_tooltip": ["Reject", "\u0631\u0641\u0636"],

    // Equipment Screen
    "equipment_technician": ["Technician / Performed By *", "\u0627\u0644\u0641\u0646\u064a / \u0627\u0644\u0645\u0646\u0641\u0630 *"],
    "equipment_technician_hint": ["e.g. Eng. Sarah Ahmed", "\u0645\u062b\u0627\u0644: \u0645. \u0633\u0627\u0631\u0629 \u0623\u062d\u0645\u062f"],
    "equipment_cert_ref": ["Certificate Reference / Report # *", "\u0645\u0631\u062c\u0639 \u0627\u0644\u0634\u0647\u0627\u062f\u0629 / \u0631\u0642\u0645 \u0627\u0644\u062a\u0642\u0631\u064a\u0631 *"],
    "equipment_cert_ref_hint": ["e.g. CAL-2026-0891", "\u0645\u062b\u0627\u0644: CAL-2026-0891"],

    // Employees Screen
    "employee_pin_label": ["PIN (Clock-In)", "\u0627\u0644\u0631\u0645\u0632 \u0627\u0644\u0633\u0631\u064a (\u0627\u0644\u062d\u0636\u0648\u0631)"],
    "employee_eid_hint": ["784-XXXX-XXXXXXX-X", "784-XXXX-XXXXXXX-X"],

    // Customer Portal Screen
    "portal_address_label": ["Drop-off / Delivery Address *", "\u0639\u0646\u0648\u0627\u0646 \u0627\u0644\u062a\u0633\u0644\u064a\u0645 / \u0627\u0644\u0627\u0633\u062a\u0644\u0627\u0645 *"],
    "portal_time_slot": ["Preferred Time Slot", "\u0627\u0644\u0641\u062a\u0631\u0629 \u0627\u0644\u0632\u0645\u0646\u064a\u0629 \u0627\u0644\u0645\u0641\u0636\u0644\u0629"],
    "portal_tracking_hint": ["e.g. ORD-2026-0042 or 8-char token", "\u0645\u062b\u0627\u0644: ORD-2026-0042 \u0623\u0648 \u0631\u0645\u0632 \u0645\u0646 8 \u0623\u062d\u0631\u0641"],

    // Customers Screen
    "customer_phone_label": ["Phone Number (Mobile) *", "\u0631\u0642\u0645 \u0627\u0644\u0647\u0627\u062a\u0641 (\u0627\u0644\u062c\u0648\u0627\u0644) *"],
    "customer_name_label": ["Full Customer Name *", "\u0627\u0633\u0645 \u0627\u0644\u0639\u0645\u064a\u0644 \u0627\u0644\u0643\u0627\u0645\u0644 *"],
    "customer_email_label": ["Email Address", "\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a"],
    "customer_trn_label": ["Tax TRN (B2B)", "\u0627\u0644\u0631\u0642\u0645 \u0627\u0644\u0636\u0631\u064a\u0628\u064a TRN (\u0644\u0644\u0634\u0631\u0643\u0627\u062a)"],
    "customer_address_label": ["Delivery Address / Villa / Apt", "\u0639\u0646\u0648\u0627\u0646 \u0627\u0644\u062a\u0648\u0635\u064a\u0644 / \u0627\u0644\u0641\u064a\u0644\u0627 / \u0627\u0644\u0634\u0642\u0629"],
    "customer_loyalty_label": ["Loyalty Tier", "\u0641\u0626\u0629 \u0627\u0644\u0648\u0644\u0627\u0621"],

    // Challans Screen
    "challan_desc_hint": ["e.g. Clean Linen Bundles", "\u0645\u062b\u0627\u0644: \u062d\u0632\u0645 \u0627\u0644\u0643\u062a\u0627\u0646 \u0627\u0644\u0646\u0638\u064a\u0641"],

    // Branches Screen
    "branch_hours_hint": ["e.g. 08:00 - 22:00 (Sat-Thu), 14:00 - 22:00 (Fri)", "\u0645\u062b\u0627\u0644: 08:00 - 22:00 (\u0633\u0628\u062a-\u062e\u0645\u064a\u0633)\u060c 14:00 - 22:00 (\u0627\u0644\u062c\u0645\u0639\u0629)"],

    // Attendance Screen
    "attendance_pin_hint": ["PIN or Badge Scan", "\u0627\u0644\u0631\u0645\u0632 \u0627\u0644\u0633\u0631\u064a \u0623\u0648 \u0645\u0633\u062d \u0627\u0644\u0628\u0637\u0627\u0642\u0629"],

    // Advanced Cycle Screen
    "cycle_rack_hint": ["e.g. 101", "\u0645\u062b\u0627\u0644: 101"],
    "cycle_qty_hint": ["e.g. 1", "\u0645\u062b\u0627\u0644: 1"],

    // Global Config Screen
    "config_backup_path_hint": ["e.g. C:/LaundryPro/backups/", "\u0645\u062b\u0627\u0644: C:/LaundryPro/backups/"],

    // Notifications Screen
    "notification_mark_read": ["Mark as read", "\u062a\u0639\u0644\u064a\u0645 \u0643\u0645\u0642\u0631\u0648\u0621"],

    // Reports Screen
    "reports_export_csv": ["Export CSV", "\u062a\u0635\u062f\u064a\u0631 CSV"],
    "reports_export_pdf": ["Export PDF", "\u062a\u0635\u062f\u064a\u0631 PDF"],
    "reports_refresh": ["Refresh", "\u062a\u062d\u062f\u064a\u062b"],

    // POS Screen
    "pos_manual_sync": ["Manual Sync", "\u0645\u0632\u0627\u0645\u0646\u0629 \u064a\u062f\u0648\u064a\u0629"],
    "pos_settings_peripherals": ["Settings & Peripherals", "\u0627\u0644\u0625\u0639\u062f\u0627\u062f\u0627\u062a \u0648\u0627\u0644\u0623\u062c\u0647\u0632\u0629 \u0627\u0644\u0637\u0631\u0641\u064a\u0629"],

    // Printer Panel
    "printer_refresh": ["Refresh printers", "\u062a\u062d\u062f\u064a\u062b \u0627\u0644\u0637\u0627\u0628\u0639\u0627\u062a"],
    "printer_discover_network": ["Discover network printers", "\u0627\u0643\u062a\u0634\u0627\u0641 \u0637\u0627\u0628\u0639\u0627\u062a \u0627\u0644\u0634\u0628\u0643\u0629"],
    "printer_remove_line": ["Remove line", "\u0625\u0632\u0627\u0644\u0629 \u0627\u0644\u0633\u0637\u0631"],
    "print_queue_refresh": ["Refresh", "\u062a\u062d\u062f\u064a\u062b"],
    "print_queue_retry": ["Retry", "\u0625\u0639\u0627\u062f\u0629 \u0627\u0644\u0645\u062d\u0627\u0648\u0644\u0629"],
    "print_queue_delete": ["Delete", "\u062d\u0630\u0641"],
    "printer_delete_template": ["Delete template", "\u062d\u0630\u0641 \u0627\u0644\u0642\u0627\u0644\u0628"],

    // General
    "error_label": ["Error", "\u062e\u0637\u0623"],
    "confirm_action": ["Confirm", "\u062a\u0623\u0643\u064a\u062f"],
    "delete_action": ["Delete", "\u062d\u0630\u0641"],
    "edit_action": ["Edit", "\u062a\u0639\u062f\u064a\u0644"],
    "add_action": ["Add", "\u0625\u0636\u0627\u0641\u0629"],
    "approve_action": ["Approve", "\u0645\u0648\u0627\u0641\u0642\u0629"],
    "reject_action": ["Reject", "\u0631\u0641\u0636"],
    "refresh_action": ["Refresh", "\u062a\u062d\u062f\u064a\u062b"]
};

let addedEn = 0, addedAr = 0;
for (const [key, [enVal, arVal]] of Object.entries(newKeys)) {
    if (!en[key]) { en[key] = enVal; addedEn++; }
    if (!ar[key]) { ar[key] = arVal; addedAr++; }
}

fs.writeFileSync(enPath, JSON.stringify(en, null, 4) + '\n', 'utf8');
fs.writeFileSync(arPath, JSON.stringify(ar, null, 4) + '\n', 'utf8');

console.log(`\n=== L10N Keys Injection Complete ===`);
console.log(`en.json: ${Object.keys(en).length} total keys (+${addedEn} new)`);
console.log(`ar.json: ${Object.keys(ar).length} total keys (+${addedAr} new)`);
