// Bulk Dart Hardcoded String Replacer
// Converts hardcoded English strings in Dart views to l10n.t() calls

const fs = require('fs');
const path = require('path');

const projectRoot = 'e:/Projects/Flutter/UAE-Laundry-Pro';

// Define replacements as [file, old, new] tuples
// We'll do file-by-file

function replaceInFile(filePath, replacements) {
    let content = fs.readFileSync(filePath, 'utf8');
    let count = 0;
    for (const [old, replacement] of replacements) {
        if (content.includes(old)) {
            content = content.replace(old, replacement);
            count++;
        }
    }
    if (count > 0) {
        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`  [${count} replacements] ${path.basename(filePath)}`);
    }
    return count;
}

let totalCount = 0;

// ===== settings_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/settings_screen.dart'), [
    ["title: const Text('Global Paths & Directories', style: TextStyle(fontWeight: FontWeight.bold))", "title: Text(l10n.t('settings_global_paths'), style: const TextStyle(fontWeight: FontWeight.bold))"],
    ["subtitle: const Text('Backup, logs, receipts, images, and export directories')", "subtitle: Text(l10n.t('settings_global_paths_desc'))"],
    ["title: const Text('Roles & Permissions', style: TextStyle(fontWeight: FontWeight.bold))", "title: Text(l10n.t('settings_roles_perms'), style: const TextStyle(fontWeight: FontWeight.bold))"],
    ["subtitle: const Text('Manage user authorization and access roles')", "subtitle: Text(l10n.t('settings_roles_perms_desc'))"],
    ["const Text('Disaster recovery, SHA-256 verification, and snapshot restore', style: TextStyle(fontSize: 12, color: Colors.grey))", "Text(l10n.t('settings_disaster_recovery'), style: const TextStyle(fontSize: 12, color: Colors.grey))"],
    ["Text('Backup Snapshots History', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700))", "Text(l10n.t('settings_backup_snapshots'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700))"],
    ["child: Center(child: Text('No backup archives created yet.', style: TextStyle(color: Colors.grey)))", "child: Center(child: Text(l10n.t('settings_no_backups'), style: const TextStyle(color: Colors.grey)))"],
    ["Text('File: $fileName', style: const TextStyle(fontWeight: FontWeight.bold))", "Text(l10n.t('settings_file_label').replaceAll('{file}', fileName), style: const TextStyle(fontWeight: FontWeight.bold))"],
    ["Text('Target Archive: $fileName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))", "Text(l10n.t('settings_target_archive').replaceAll('{file}', fileName), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))"],
]);

// ===== sterilization_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/sterilization_screen.dart'), [
    ["SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed)", "SnackBar(content: Text(l10n.t('sterilization_error').replaceAll('{error}', e.toString())), backgroundColor: AppTheme.errorRed)"],
    ["content: Text('Please enter supervisor name and security PIN')", "content: Text(l10n.t('sterilization_enter_details'))"],
    ["child: const Text('Sign & Certify')", "child: Text(l10n.t('sterilization_sign_certify'))"],
    ["content: Text('Sterilization Lot certified with digital e-signature')", "content: Text(l10n.t('sterilization_lot_certified'))"],
    ["SnackBar(content: Text('Signing error: $e'), backgroundColor: AppTheme.errorRed)", "SnackBar(content: Text(l10n.t('sterilization_signing_error').replaceAll('{error}', e.toString())), backgroundColor: AppTheme.errorRed)"],
    ["label: const Text('Affix Electronic Signature')", "label: Text(l10n.t('sterilization_affix_signature'))"],
    ["label: const Text('Close Details')", "label: Text(l10n.t('sterilization_close_details'))"],
    ["label: const Text('Needs Sign')", "label: Text(l10n.t('sterilization_needs_sign'))"],
    ["tooltip: 'Affix Signature'", "tooltip: l10n.t('sterilization_affix_sig_tooltip')"],
    ["labelText: 'Certified Supervisor / QA Name *'", "labelText: l10n.t('sterilization_supervisor_name')"],
    ["hintText: 'e.g. Dr. Amina Al-Zaabi'", "hintText: l10n.t('sterilization_supervisor_hint')"],
    ["labelText: 'Operator Security PIN *'", "labelText: l10n.t('sterilization_pin')"],
    ["hintText: '4-digit authorization code'", "hintText: l10n.t('sterilization_pin_hint')"],
    ["labelText: 'Regulatory Attestation / Meaning *'", "labelText: l10n.t('sterilization_attestation')"],
    ["labelText: 'Sterilization Autoclave Program'", "labelText: l10n.t('sterilization_autoclave_program')"],
    ["labelText: 'Target Temp (°C)'", "labelText: l10n.t('sterilization_target_temp')"],
    ["labelText: 'Pressure (bar)'", "labelText: l10n.t('sterilization_pressure')"],
    ["labelText: 'Duration (min)'", "labelText: l10n.t('sterilization_duration')"],
]);

// ===== sync_settings_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/sync_settings_screen.dart'), [
    ["SnackBar(content: Text('Sync Error: $e'), backgroundColor: AppTheme.errorRed)", "SnackBar(content: Text(l10n.t('sync_error').replaceAll('{error}', e.toString())), backgroundColor: AppTheme.errorRed)"],
    ["label: const Text('Inspect Staged Payloads')", "label: Text(l10n.t('sync_inspect_payloads'))"],
    ["label: const Text('View Conflict History')", "label: Text(l10n.t('sync_view_conflicts'))"],
    ["title: const Text('Deterministic 3-Way Merge Strategy Active')", "title: Text(l10n.t('sync_merge_strategy_title'))"],
    ["subtitle: const Text('Cloud Master Sequence ID tracking with automated replay recovery.')", "subtitle: Text(l10n.t('sync_merge_strategy_desc'))"],
    ["Text('Sync Conflict Audit Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))", "Text(l10n.t('sync_conflict_audit_log'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))"],
]);

// ===== setup_wizard_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/setup_wizard_screen.dart'), [
    ["content: Text('Installation & initial setup completed successfully!')", "content: Text(l10n.t('wizard_install_complete'))"],
    ["content: Text('Installation error: $e')", "content: Text(l10n.t('wizard_install_error').replaceAll('{error}', e.toString()))"],
    ["child: Text('UAE Dirham (AED / Fils)')", "child: Text(l10n.t('wizard_currency_aed'))"],
    ["child: Text('Saudi Riyal (SAR / Halala)')", "child: Text(l10n.t('wizard_currency_sar'))"],
    ["child: Text('Thermal Roll Paper (80mm / 48 chars)')", "child: Text(l10n.t('wizard_printer_80mm'))"],
    ["child: Text('Thermal Roll Paper (58mm / 32 chars)')", "child: Text(l10n.t('wizard_printer_58mm'))"],
    ["child: Text('Laser/Inkjet A4 Standard')", "child: Text(l10n.t('wizard_printer_a4'))"],
    ["child: Text('Dot-Matrix 80-Col (Carbon Copy)')", "child: Text(l10n.t('wizard_printer_dot'))"],
    ["decoration: const InputDecoration(labelText: 'Email')", "decoration: InputDecoration(labelText: l10n.t('wizard_email_label'))"],
    ["decoration: const InputDecoration(labelText: 'Emirate')", "decoration: InputDecoration(labelText: l10n.t('wizard_emirate_label'))"],
    ["decoration: const InputDecoration(labelText: 'Physical Address')", "decoration: InputDecoration(labelText: l10n.t('wizard_address_label'))"],
    ["decoration: const InputDecoration(labelText: 'Currency')", "decoration: InputDecoration(labelText: l10n.t('wizard_currency_label'))"],
    ["decoration: const InputDecoration(labelText: 'Invoice Prefix (e.g. INV-)')", "decoration: InputDecoration(labelText: l10n.t('wizard_invoice_prefix'))"],
    ["decoration: const InputDecoration(labelText: 'Receipt Prefix (e.g. REC-)')", "decoration: InputDecoration(labelText: l10n.t('wizard_receipt_prefix'))"],
    ["decoration: const InputDecoration(labelText: 'Challan Prefix (e.g. CHL-)')", "decoration: InputDecoration(labelText: l10n.t('wizard_challan_prefix'))"],
    ["decoration: const InputDecoration(labelText: 'GRN Prefix (e.g. GRN-)')", "decoration: InputDecoration(labelText: l10n.t('wizard_grn_prefix'))"],
    ["labelText: 'API Installation Secret (from api/.env)'", "labelText: l10n.t('wizard_api_secret')"],
    ["labelText: 'Canonical Backup Directory (BACKUP_PATH)'", "labelText: l10n.t('wizard_backup_dir')"],
    ["decoration: const InputDecoration(labelText: 'Primary Slip Printer Default')", "decoration: InputDecoration(labelText: l10n.t('wizard_printer_label'))"],
    ["hintText: 'Optional: Enter activation key or leave blank for 7-day evaluation'", "hintText: l10n.t('wizard_license_hint')"],
]);

// ===== terminals_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/terminals_screen.dart'), [
    ["const SnackBar(content: Text('Please create a branch first before pairing terminals'))", "SnackBar(content: Text(l10n.t('terminal_create_branch_first')))"],
    ["labelText: 'LAN Binding IP Address'", "labelText: l10n.t('terminal_lan_ip')"],
    ["hintText: '192.168.1.100'", "hintText: l10n.t('terminal_lan_ip_hint')"],
    ["labelText: 'Hardware MAC Address'", "labelText: l10n.t('terminal_mac')"],
    ["hintText: 'XX:XX:XX:XX:XX:XX'", "hintText: l10n.t('terminal_mac_hint')"],
    ["labelText: 'Hardware Security Auth Token'", "labelText: l10n.t('terminal_auth_token')"],
    ["tooltip: 'Regenerate Token'", "tooltip: l10n.t('terminal_regen_token')"],
]);

// ===== role_editor_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/role_editor_screen.dart'), [
    ["const SnackBar(content: Text('Failed to load roles'))", "SnackBar(content: Text(l10n.t('role_load_failed')))"],
    ["const SnackBar(content: Text('Role updated successfully'))", "SnackBar(content: Text(l10n.t('role_updated')))"],
    ["const SnackBar(content: Text('Failed to update role'))", "SnackBar(content: Text(l10n.t('role_update_failed')))"],
    ["label: const Text('Grant All (*)')", "label: Text(l10n.t('role_grant_all'))"],
    ["label: const Text('Clear All')", "label: Text(l10n.t('role_clear_all'))"],
    ["labelText: 'Role Title (e.g. Branch Supervisor)'", "labelText: l10n.t('role_title_hint')"],
]);

// ===== vendors_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/vendors_screen.dart'), [
    ["SnackBar(content: Text('Failed to save vendor: $e'))", "SnackBar(content: Text(l10n.t('vendor_save_failed').replaceAll('{error}', e.toString())))"],
    ["hintText: 'e.g. Emirates NBD, IBAN: AE070260000000000000000'", "hintText: l10n.t('vendor_bank_hint')"],
]);

// ===== salary_advances_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/salary_advances_screen.dart'), [
    ["labelText: 'Reason / Notes'", "labelText: l10n.t('salary_reason_notes')"],
]);

// ===== rfid_tracking_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/rfid_tracking_screen.dart'), [
    ["labelText: 'Reader IPv4 Address'", "labelText: l10n.t('rfid_reader_ip')"],
    ["hintText: '192.168.1.180'", "hintText: l10n.t('rfid_reader_ip_hint')"],
    ["labelText: 'TCP Port (LLRP/ASCII)'", "labelText: l10n.t('rfid_tcp_port')"],
    ["hintText: '5084'", "hintText: l10n.t('rfid_tcp_port_hint')"],
    ["tooltip: 'Reader Hardware Settings'", "tooltip: l10n.t('rfid_reader_settings')"],
    ["tooltip: 'Clear Scanned'", "tooltip: l10n.t('rfid_clear_scanned')"],
]);

// ===== purchasing_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/purchasing_screen.dart'), [
    ["labelText: 'Product'", "labelText: l10n.t('purchasing_product')"],
    ["decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder(), isDense: true)", "decoration: InputDecoration(labelText: l10n.t('purchasing_qty'), border: const OutlineInputBorder(), isDense: true)"],
    ["decoration: const InputDecoration(labelText: 'Unit Cost', border: OutlineInputBorder(), isDense: true, prefixText: 'AED ')", "decoration: InputDecoration(labelText: l10n.t('purchasing_unit_cost_label'), border: const OutlineInputBorder(), isDense: true, prefixText: '${l10n.t('currency_aed')} ')"],
    ["labelText: 'Supplier Delivery Note / Bill of Lading (BOL)'", "labelText: l10n.t('purchasing_delivery_note')"],
    ["hintText: 'e.g. DN-984321'", "hintText: l10n.t('purchasing_delivery_note_hint')"],
    ["labelText: 'Receiving Inspector Notes / Quality Checks'", "labelText: l10n.t('purchasing_inspector_notes')"],
    ["hintText: 'Packaging intact, seals verified, stored in Bay A'", "hintText: l10n.t('purchasing_inspector_notes_hint')"],
]);

// ===== production_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/production_screen.dart'), [
    ["labelText: 'QC / Audit Notes (Optional)'", "labelText: l10n.t('production_qc_notes')"],
]);

// ===== pending_invoices_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/pending_invoices_screen.dart'), [
    ["labelText: 'Amount (AED) / \u0627\u0644\u0645\u0628\u0644\u063a'", "labelText: l10n.t('pending_amount_label')"],
]);

// ===== operator_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/operator_screen.dart'), [
    ["labelText: 'Select Employee *'", "labelText: l10n.t('operator_select_employee')"],
    ["labelText: 'Certification Program *'", "labelText: l10n.t('operator_cert_program')"],
    ["tooltip: 'Refresh'", "tooltip: l10n.t('refresh_action')"],
]);

// ===== leave_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/leave_screen.dart'), [
    ["labelText: 'Leave Type'", "labelText: l10n.t('leave_type_label')"],
    ["labelText: 'Reason for Leave'", "labelText: l10n.t('leave_reason')"],
    ["tooltip: 'Approve Leave'", "tooltip: l10n.t('leave_approve_tooltip')"],
    ["tooltip: 'Reject Leave'", "tooltip: l10n.t('leave_reject_tooltip')"],
]);

// ===== expenses_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/expenses_screen.dart'), [
    ["tooltip: 'Approve'", "tooltip: l10n.t('expense_approve_tooltip')"],
    ["tooltip: 'Reject'", "tooltip: l10n.t('expense_reject_tooltip')"],
]);

// ===== equipment_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/equipment_screen.dart'), [
    ["labelText: 'Technician / Performed By *'", "labelText: l10n.t('equipment_technician')"],
    ["hintText: 'e.g. Eng. Sarah Ahmed'", "hintText: l10n.t('equipment_technician_hint')"],
    ["labelText: 'Certificate Reference / Report # *'", "labelText: l10n.t('equipment_cert_ref')"],
    ["hintText: 'e.g. CAL-2026-0891'", "hintText: l10n.t('equipment_cert_ref_hint')"],
    ["tooltip: 'Refresh'", "tooltip: l10n.t('refresh_action')"],
]);

// ===== employees_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/employees_screen.dart'), [
    ["labelText: 'PIN (Clock-In)'", "labelText: l10n.t('employee_pin_label')"],
    ["hintText: '784-XXXX-XXXXXXX-X'", "hintText: l10n.t('employee_eid_hint')"],
]);

// ===== customer_portal_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/customer_portal_screen.dart'), [
    ["labelText: 'Drop-off / Delivery Address *'", "labelText: l10n.t('portal_address_label')"],
    ["decoration: const InputDecoration(labelText: 'Preferred Time Slot', border: OutlineInputBorder())", "decoration: InputDecoration(labelText: l10n.t('portal_time_slot'), border: const OutlineInputBorder())"],
    ["hintText: 'e.g. ORD-2026-0042 or 8-char token'", "hintText: l10n.t('portal_tracking_hint')"],
]);

// ===== customers_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/customers_screen.dart'), [
    ["decoration: const InputDecoration(labelText: 'Phone Number (Mobile) *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))", "decoration: InputDecoration(labelText: l10n.t('customer_phone_label'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.phone))"],
    ["decoration: const InputDecoration(labelText: 'Full Customer Name *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))", "decoration: InputDecoration(labelText: l10n.t('customer_name_label'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.person))"],
    ["decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))", "decoration: InputDecoration(labelText: l10n.t('customer_email_label'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.email))"],
    ["decoration: const InputDecoration(labelText: 'Tax TRN (B2B)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.verified))", "decoration: InputDecoration(labelText: l10n.t('customer_trn_label'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.verified))"],
    ["decoration: const InputDecoration(labelText: 'Delivery Address / Villa / Apt', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home))", "decoration: InputDecoration(labelText: l10n.t('customer_address_label'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.home))"],
    ["decoration: const InputDecoration(labelText: 'Loyalty Tier', border: OutlineInputBorder(), isDense: true)", "decoration: InputDecoration(labelText: l10n.t('customer_loyalty_label'), border: const OutlineInputBorder(), isDense: true)"],
]);

// ===== challans_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/challans_screen.dart'), [
    ["hintText: 'e.g. Clean Linen Bundles'", "hintText: l10n.t('challan_desc_hint')"],
]);

// ===== branches_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/branches_screen.dart'), [
    ["hintText: 'e.g. 08:00 - 22:00 (Sat-Thu), 14:00 - 22:00 (Fri)'", "hintText: l10n.t('branch_hours_hint')"],
]);

// ===== attendance_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/attendance_screen.dart'), [
    ["hintText: 'PIN or Badge Scan'", "hintText: l10n.t('attendance_pin_hint')"],
]);

// ===== advanced_cycle_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/advanced_cycle_screen.dart'), [
    ["hintText: 'e.g. 101'", "hintText: l10n.t('cycle_rack_hint')"],
    ["hintText: 'e.g. 1'", "hintText: l10n.t('cycle_qty_hint')"],
]);

// ===== global_config_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/global_config_screen.dart'), [
    ["hintText: 'e.g. C:/LaundryPro/backups/'", "hintText: l10n.t('config_backup_path_hint')"],
]);

// ===== notifications_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/notifications_screen.dart'), [
    ["tooltip: 'Mark as read'", "tooltip: l10n.t('notification_mark_read')"],
]);

// ===== reports_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/reports_screen.dart'), [
    ["tooltip: 'Export CSV'", "tooltip: l10n.t('reports_export_csv')"],
    ["tooltip: 'Export PDF'", "tooltip: l10n.t('reports_export_pdf')"],
    ["tooltip: 'Refresh'", "tooltip: l10n.t('reports_refresh')"],
]);

// ===== POS screen =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/features/pos/pos_screen.dart'), [
    ["tooltip: 'Manual Sync'", "tooltip: l10n.t('pos_manual_sync')"],
    ["tooltip: 'Settings & Peripherals'", "tooltip: l10n.t('pos_settings_peripherals')"],
]);

// ===== Printer widgets =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/peripherals/features/printer/widgets/printer_panel.dart'), [
    ["tooltip: 'Refresh printers'", "tooltip: l10n.t('printer_refresh')"],
    ["tooltip: 'Discover network printers'", "tooltip: l10n.t('printer_discover_network')"],
    ["tooltip: 'Remove line'", "tooltip: l10n.t('printer_remove_line')"],
]);

totalCount += replaceInFile(path.join(projectRoot, 'lib/peripherals/features/printer/widgets/print_queue_panel.dart'), [
    ["tooltip: 'Refresh'", "tooltip: l10n.t('print_queue_refresh')"],
    ["tooltip: 'Retry'", "tooltip: l10n.t('print_queue_retry')"],
    ["tooltip: 'Delete'", "tooltip: l10n.t('print_queue_delete')"],
]);

totalCount += replaceInFile(path.join(projectRoot, 'lib/peripherals/features/printer/widgets/template_picker_dialog.dart'), [
    ["tooltip: 'Delete template'", "tooltip: l10n.t('printer_delete_template')"],
]);

// ===== license_screen.dart =====
totalCount += replaceInFile(path.join(projectRoot, 'lib/views/license_screen.dart'), [
    ["hintText: 'Enter activation stamp or key'", "hintText: l10n.t('wizard_license_stamp')"],
]);

console.log(`\n=== Bulk Dart String Replacement Complete ===`);
console.log(`Total replacements: ${totalCount}`);
