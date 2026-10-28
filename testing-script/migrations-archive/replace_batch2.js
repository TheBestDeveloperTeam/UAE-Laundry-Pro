// Batch 2: More L10N key injection + string replacement

const fs = require('fs');
const path = require('path');

const projectRoot = 'e:/Projects/Flutter/UAE-Laundry-Pro';
const enPath = path.join(projectRoot, 'assets/lang/en.json');
const arPath = path.join(projectRoot, 'assets/lang/ar.json');

let en = JSON.parse(fs.readFileSync(enPath, 'utf8'));
let ar = JSON.parse(fs.readFileSync(arPath, 'utf8'));

// === New keys batch 2 ===
const newKeys2 = {
    // Advanced Cycle
    "cycle_complete_run": ["Complete Cycle Run", "\u0625\u062a\u0645\u0627\u0645 \u062f\u0648\u0631\u0629 \u0627\u0644\u062a\u0634\u063a\u064a\u0644"],
    "cycle_process_logs": ["Process Logs & Quality Telemetry", "\u0633\u062c\u0644\u0627\u062a \u0627\u0644\u0639\u0645\u0644\u064a\u0629 \u0648\u0642\u064a\u0627\u0633 \u0627\u0644\u062c\u0648\u062f\u0629"],
    "cycle_select_preset": ["Select Cycle Preset Program", "\u0627\u062e\u062a\u064a\u0627\u0631 \u0628\u0631\u0646\u0627\u0645\u062c \u0627\u0644\u062f\u0648\u0631\u0629 \u0627\u0644\u0645\u0639\u062f \u0645\u0633\u0628\u0642\u0627\u064b"],
    "cycle_start_advanced": ["START ADVANCED CYCLE", "\u0628\u062f\u0621 \u0627\u0644\u062f\u0648\u0631\u0629 \u0627\u0644\u0645\u062a\u0642\u062f\u0645\u0629"],
    "cycle_record_telemetry": ["Record Real-Time In-Cycle Telemetry", "\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u0642\u064a\u0627\u0633 \u0627\u0644\u0645\u0628\u0627\u0634\u0631 \u0623\u062b\u0646\u0627\u0621 \u0627\u0644\u062f\u0648\u0631\u0629"],
    "cycle_record_validate": ["RECORD METRIC & VALIDATE", "\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u0642\u064a\u0627\u0633 \u0648\u0627\u0644\u062a\u062d\u0642\u0642"],

    // Accounting
    "accounting_export_zatca": ["Export KSA ZATCA Phase 2 UBL XML", "\u062a\u0635\u062f\u064a\u0631 ZATCA \u0627\u0644\u0645\u0631\u062d\u0644\u0629 2 UBL XML"],

    // Peripherals - SQL
    "sql_connect": ["Connect", "\u0627\u062a\u0635\u0627\u0644"],
    "sql_disconnect": ["Disconnect", "\u0642\u0637\u0639 \u0627\u0644\u0627\u062a\u0635\u0627\u0644"],
    "sql_query": ["Query", "\u0627\u0633\u062a\u0639\u0644\u0627\u0645"],

    // Peripherals - Scanner
    "scanner_latest_barcode": ["Latest decoded barcode", "\u0622\u062e\u0631 \u0628\u0627\u0631\u0643\u0648\u062f \u0645\u0641\u0643\u0648\u0643"],
    "scanner_raw_json": ["Raw packet JSON", "\u062d\u0632\u0645\u0629 JSON \u0627\u0644\u062e\u0627\u0645"],

    // Peripherals - Printer Preview
    "print_page_setup": ["Page Setup", "\u0625\u0639\u062f\u0627\u062f \u0627\u0644\u0635\u0641\u062d\u0629"],
    "print_action": ["Print", "\u0637\u0628\u0627\u0639\u0629"],
    "print_no_printers": ["No printers found.", "\u0644\u0627 \u062a\u0648\u062c\u062f \u0637\u0627\u0628\u0639\u0627\u062a."],

    // Peripherals - Printer Panel
    "printer_save_template": ["Save Template", "\u062d\u0641\u0638 \u0627\u0644\u0642\u0627\u0644\u0628"],
    "printer_default_source": ["Default / single source", "\u0627\u0644\u0645\u0635\u062f\u0631 \u0627\u0644\u0627\u0641\u062a\u0631\u0627\u0636\u064a / \u0627\u0644\u0648\u062d\u064a\u062f"],
    "printer_reverse_arabic": ["Reverse Arabic runs for RTL output", "\u0639\u0643\u0633 \u0627\u0644\u0646\u0635 \u0627\u0644\u0639\u0631\u0628\u064a \u0644\u0644\u0625\u062e\u0631\u0627\u062c \u0645\u0646 \u0627\u0644\u064a\u0645\u064a\u0646 \u0644\u0644\u064a\u0633\u0627\u0631"],
    "printer_insert_arabic": ["Insert Arabic sample lines", "\u0625\u062f\u0631\u0627\u062c \u0623\u0633\u0637\u0631 \u0639\u0631\u0628\u064a\u0629 \u0646\u0645\u0648\u0630\u062c\u064a\u0629"],
    "printer_preview_receipt": ["Preview POS Receipt", "\u0645\u0639\u0627\u064a\u0646\u0629 \u0625\u064a\u0635\u0627\u0644 \u0646\u0642\u0637\u0629 \u0627\u0644\u0628\u064a\u0639"],
    "printer_load_editor": ["Load into Editor", "\u062a\u062d\u0645\u064a\u0644 \u0641\u064a \u0627\u0644\u0645\u062d\u0631\u0631"],
    "printer_beep_1": ["Beep \u00d71", "\u0635\u0641\u064a\u0631 \u00d71"],
    "printer_beep_3": ["Beep \u00d73", "\u0635\u0641\u064a\u0631 \u00d73"],
    "printer_feed_3": ["Feed 3 lines", "\u062a\u063a\u0630\u064a\u0629 3 \u0623\u0633\u0637\u0631"],
    "printer_feed_9": ["Feed 9 lines", "\u062a\u063a\u0630\u064a\u0629 9 \u0623\u0633\u0637\u0631"],
    "printer_cut_1": ["Cut \u00d71", "\u0642\u0637\u0639 \u00d71"],
    "printer_cut_3": ["Cut \u00d73", "\u0642\u0637\u0639 \u00d73"],
    "printer_load": ["Load", "\u062a\u062d\u0645\u064a\u0644"],
    "printer_silent_print": ["Silent Print (Ctrl+P)", "\u0637\u0628\u0627\u0639\u0629 \u0635\u0627\u0645\u062a\u0629 (Ctrl+P)"],
    "printer_preview_print": ["Preview & Print", "\u0645\u0639\u0627\u064a\u0646\u0629 \u0648\u0637\u0628\u0627\u0639\u0629"],
    "printer_preview_hex": ["Preview Hex", "\u0645\u0639\u0627\u064a\u0646\u0629 Hex"],
    "printer_queue_job": ["Queue Job", "\u0625\u0636\u0627\u0641\u0629 \u0644\u0644\u0642\u0627\u0626\u0645\u0629"],
    "printer_flush_queue": ["Flush Queue", "\u062a\u0641\u0631\u064a\u063a \u0627\u0644\u0642\u0627\u0626\u0645\u0629"],

    // Peripherals - Hex Preview
    "hex_close": ["Close", "\u0625\u063a\u0644\u0627\u0642"],

    // Peripherals - Dashboard
    "peripheral_console": ["Peripheral Framework Console", "\u0648\u062d\u062f\u0629 \u062a\u062d\u0643\u0645 \u0627\u0644\u0623\u062c\u0647\u0632\u0629 \u0627\u0644\u0637\u0631\u0641\u064a\u0629"],
    "peripheral_detecting": ["Detecting...", "\u062c\u0627\u0631\u064a \u0627\u0644\u0643\u0634\u0641..."],
    "peripheral_collecting": ["Collecting...", "\u062c\u0627\u0631\u064a \u0627\u0644\u062c\u0645\u0639..."],
    "peripheral_open_drawer": ["OPEN DRAWER", "\u0641\u062a\u062d \u0627\u0644\u062f\u0631\u062c"],

    // Wizard Screen
    "wizard_welcome": ["Welcome", "\u0645\u0631\u062d\u0628\u0627\u064b"],
    "wizard_welcome_msg": ["Welcome to LaundryPro UAE!", "\u0645\u0631\u062d\u0628\u0627\u064b \u0628\u0643 \u0641\u064a \u0644\u0648\u0646\u062f\u0631\u064a \u0628\u0631\u0648 \u0627\u0644\u0625\u0645\u0627\u0631\u0627\u062a!"],
    "wizard_select_language": ["Select your preferred language:", "\u0627\u062e\u062a\u0631 \u0644\u063a\u062a\u0643 \u0627\u0644\u0645\u0641\u0636\u0644\u0629:"],
    "wizard_business_profile": ["Business Profile", "\u0645\u0644\u0641 \u0627\u0644\u0645\u0646\u0634\u0623\u0629"],
    "wizard_hardware_setup": ["Hardware Setup", "\u0625\u0639\u062f\u0627\u062f \u0627\u0644\u0623\u062c\u0647\u0632\u0629"],
    "wizard_printers_drawers": ["Printers & Cash Drawers", "\u0627\u0644\u0637\u0627\u0628\u0639\u0627\u062a \u0648\u0623\u062f\u0631\u0627\u062c \u0627\u0644\u0646\u0642\u062f"],
    "wizard_scanners": ["Scanners", "\u0627\u0644\u0645\u0627\u0633\u062d\u0627\u062a"],
    "wizard_test_print": ["Test Print", "\u0637\u0628\u0627\u0639\u0629 \u062a\u062c\u0631\u064a\u0628\u064a\u0629"],
    "wizard_status_connected": ["Status: Connected", "\u0627\u0644\u062d\u0627\u0644\u0629: \u0645\u062a\u0635\u0644"],
    "wizard_complete_setup": ["Complete Setup", "\u0625\u062a\u0645\u0627\u0645 \u0627\u0644\u0625\u0639\u062f\u0627\u062f"],
};

let addedEn = 0, addedAr = 0;
for (const [key, [enVal, arVal]] of Object.entries(newKeys2)) {
    if (!en[key]) { en[key] = enVal; addedEn++; }
    if (!ar[key]) { ar[key] = arVal; addedAr++; }
}

fs.writeFileSync(enPath, JSON.stringify(en, null, 4) + '\n', 'utf8');
fs.writeFileSync(arPath, JSON.stringify(ar, null, 4) + '\n', 'utf8');

console.log(`Keys injected: +${addedEn} en, +${addedAr} ar (${Object.keys(en).length} total)`);

// === Now replace in Dart files ===
function replaceInFile(filePath, replacements) {
    if (!fs.existsSync(filePath)) { console.log(`  [SKIP] ${filePath} not found`); return 0; }
    let content = fs.readFileSync(filePath, 'utf8');
    let count = 0;
    for (const [old, rep] of replacements) {
        if (content.includes(old)) {
            content = content.replace(old, rep); count++;
        }
    }
    if (count > 0) { fs.writeFileSync(filePath, content, 'utf8'); console.log(`  [${count}] ${path.basename(filePath)}`); }
    return count;
}

let total = 0;

// advanced_cycle_screen.dart
total += replaceInFile(path.join(projectRoot, 'lib/views/advanced_cycle_screen.dart'), [
    ["title: const Text('Complete Cycle Run')", "title: Text(l10n.t('cycle_complete_run'))"],
    ["const Text('Process Logs & Quality Telemetry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))", "Text(l10n.t('cycle_process_logs'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))"],
    ["label: const Text('Complete Cycle Run')", "label: Text(l10n.t('cycle_complete_run'))"],
    ["const Text('Select Cycle Preset Program', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))", "Text(l10n.t('cycle_select_preset'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))"],
    ["label: const Text('START ADVANCED CYCLE', style: TextStyle(fontWeight: FontWeight.bold))", "label: Text(l10n.t('cycle_start_advanced'), style: const TextStyle(fontWeight: FontWeight.bold))"],
    ["const Text('Record Real-Time In-Cycle Telemetry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))", "Text(l10n.t('cycle_record_telemetry'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))"],
    ["label: const Text('RECORD METRIC & VALIDATE', style: TextStyle(fontWeight: FontWeight.bold))", "label: Text(l10n.t('cycle_record_validate'), style: const TextStyle(fontWeight: FontWeight.bold))"],
]);

// accounting_screen.dart
total += replaceInFile(path.join(projectRoot, 'lib/views/accounting_screen.dart'), [
    ["label: const Text('Export KSA ZATCA Phase 2 UBL XML', style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold))", "label: Text(l10n.t('accounting_export_zatca'), style: const TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold))"],
]);

// SQL database screen
total += replaceInFile(path.join(projectRoot, 'lib/peripherals/features/sql_database/screens/sql_database_screen.dart'), [
    ["label: const Text('Connect')", "label: Text(l10n.t('sql_connect'))"],
    ["label: const Text('Disconnect')", "label: Text(l10n.t('sql_disconnect'))"],
    ["label: const Text('Query')", "label: Text(l10n.t('sql_query'))"],
]);

// Scanner screen
total += replaceInFile(path.join(projectRoot, 'lib/peripherals/features/scanner/screens/scanner_screen.dart'), [
    ["subtitle: const Text('Latest decoded barcode')", "subtitle: Text(l10n.t('scanner_latest_barcode'))"],
    ["title: const Text('Raw packet JSON')", "title: Text(l10n.t('scanner_raw_json'))"],
]);

// Print preview dialog
total += replaceInFile(path.join(projectRoot, 'lib/peripherals/features/printer/widgets/print_preview_dialog.dart'), [
    ["label: const Text('Page Setup')", "label: Text(l10n.t('print_page_setup'))"],
    ["label: const Text('Print')", "label: Text(l10n.t('print_action'))"],
    ["return const Text('No printers found.');", "return Text(l10n.t('print_no_printers'));"],
]);

// Printer panel
total += replaceInFile(path.join(projectRoot, 'lib/peripherals/features/printer/widgets/printer_panel.dart'), [
    ["title: const Text('Save Template')", "title: Text(l10n.t('printer_save_template'))"],
    ["child: const Text('Default / single source')", "child: Text(l10n.t('printer_default_source'))"],
    ["title: const Text('Reverse Arabic runs for RTL output')", "title: Text(l10n.t('printer_reverse_arabic'))"],
    ["label: const Text('Insert Arabic sample lines')", "label: Text(l10n.t('printer_insert_arabic'))"],
    ["label: const Text('Preview POS Receipt')", "label: Text(l10n.t('printer_preview_receipt'))"],
    ["label: const Text('Load into Editor')", "label: Text(l10n.t('printer_load_editor'))"],
    ["label: const Text('Beep \u00d71')", "label: Text(l10n.t('printer_beep_1'))"],
    ["label: const Text('Beep \u00d73')", "label: Text(l10n.t('printer_beep_3'))"],
    ["label: const Text('Feed 3 lines')", "label: Text(l10n.t('printer_feed_3'))"],
    ["label: const Text('Feed 9 lines')", "label: Text(l10n.t('printer_feed_9'))"],
    ["label: const Text('Cut \u00d71')", "label: Text(l10n.t('printer_cut_1'))"],
    ["label: const Text('Cut \u00d73')", "label: Text(l10n.t('printer_cut_3'))"],
    ["label: const Text('Load')", "label: Text(l10n.t('printer_load'))"],
    ["label: const Text('Silent Print (Ctrl+P)')", "label: Text(l10n.t('printer_silent_print'))"],
    ["label: const Text('Preview & Print')", "label: Text(l10n.t('printer_preview_print'))"],
    ["label: const Text('Preview Hex')", "label: Text(l10n.t('printer_preview_hex'))"],
    ["label: const Text('Queue Job')", "label: Text(l10n.t('printer_queue_job'))"],
    ["label: const Text('Flush Queue')", "label: Text(l10n.t('printer_flush_queue'))"],
]);

// Hex preview dialog
total += replaceInFile(path.join(projectRoot, 'lib/peripherals/features/printer/widgets/hex_preview_dialog.dart'), [
    ["child: const Text('Close')", "child: Text(l10n.t('close'))"],
]);

// Dashboard shell screen
total += replaceInFile(path.join(projectRoot, 'lib/peripherals/features/dashboard/screens/dashboard_shell_screen.dart'), [
    ["title: const Text('Peripheral Framework Console')", "title: Text(l10n.t('peripheral_console'))"],
    ["loading: () => const Text('Detecting...')", "loading: () => Text(l10n.t('peripheral_detecting'))"],
    ["loading: () => const Text('Collecting...')", "loading: () => Text(l10n.t('peripheral_collecting'))"],
    ["label: const Text('OPEN DRAWER')", "label: Text(l10n.t('peripheral_open_drawer'))"],
]);

// Wizard screen
total += replaceInFile(path.join(projectRoot, 'lib/features/wizard/wizard_screen.dart'), [
    ["title: const Text('Welcome')", "title: Text(l10n.t('wizard_welcome'))"],
    ["const Text('Welcome to LaundryPro UAE!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))", "Text(l10n.t('wizard_welcome_msg'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))"],
    ["const Text('Select your preferred language:')", "Text(l10n.t('wizard_select_language'))"],
    ["child: const Text('English')", "child: Text(l10n.t('english'))"],
    ["title: const Text('Business Profile')", "title: Text(l10n.t('wizard_business_profile'))"],
    ["title: const Text('Hardware Setup')", "title: Text(l10n.t('wizard_hardware_setup'))"],
    ["const Text('Printers & Cash Drawers', style: TextStyle(fontWeight: FontWeight.bold))", "Text(l10n.t('wizard_printers_drawers'), style: const TextStyle(fontWeight: FontWeight.bold))"],
    ["const Text('Scanners', style: TextStyle(fontWeight: FontWeight.bold))", "Text(l10n.t('wizard_scanners'), style: const TextStyle(fontWeight: FontWeight.bold))"],
    ["child: const Text('Test Print')", "child: Text(l10n.t('wizard_test_print'))"],
    ["subtitle: const Text('Status: Connected')", "subtitle: Text(l10n.t('wizard_status_connected'))"],
]);

console.log(`\nBatch 2 total replacements: ${total}`);
