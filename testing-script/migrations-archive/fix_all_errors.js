const fs = require('fs');
const path = require('path');

// 1. Fix static/constant Dropdown lists in views: channels_screen, pending_invoices_screen, setup_wizard_screen, accounting_screen
function fixStaticDropDowns() {
  const fixes = [
    {
      file: 'e:/Projects/Flutter/UAE-Laundry-Pro/lib/views/accounting_screen.dart',
      from: /DropdownMenuItem\(value:\s*([^,]+),\s*child:\s*Text\((?:l10n|context\.l10n)\.t\(([^)]+)\)\)\)/g,
      to: 'DropdownMenuItem(value: $1, child: Text($2))' // Or use build-time evaluation
    }
  ];
}

// Let's create targeted fixes for each file identified with errors
const targetFiles = [
  'lib/views/accounting_screen.dart',
  'lib/views/channels_screen.dart',
  'lib/views/pending_invoices_screen.dart',
  'lib/views/setup_wizard_screen.dart',
  'lib/views/advanced_cycle_screen.dart',
  'lib/features/pos/pos_screen.dart',
  'lib/features/wizard/wizard_screen.dart',
  'lib/peripherals/features/dashboard/screens/dashboard_shell_screen.dart',
  'lib/peripherals/features/printer/widgets/hex_preview_dialog.dart',
  'lib/peripherals/features/printer/widgets/print_preview_dialog.dart',
  'lib/peripherals/features/printer/widgets/printer_panel.dart',
  'lib/peripherals/features/printer/widgets/template_picker_dialog.dart',
  'lib/peripherals/features/scanner/screens/scanner_screen.dart',
  'lib/peripherals/features/sql_database/screens/sql_database_screen.dart'
];

targetFiles.forEach(relPath => {
  const fullPath = path.resolve('e:/Projects/Flutter/UAE-Laundry-Pro', relPath);
  if (!fs.existsSync(fullPath)) return;
  let content = fs.readFileSync(fullPath, 'utf8');
  let original = content;

  // Ensure localization extension is imported
  if (!content.includes('localization_extension.dart')) {
    content = "import 'package:laundrypro_uae/core/localization_extension.dart';\n" + content;
  }

  // Ensure build methods define `final l10n = context.l10n;`
  content = content.replace(/(Widget\s+build\s*\(\s*BuildContext\s+([a-zA-Z0-9_]+)\s*\)\s*\{)(?![\s\S]{0,100}final\s+l10n\s*=)/g, (match, prefix, ctxName) => {
    return `${prefix}\n    final l10n = ${ctxName}.l10n;`;
  });

  // Ensure helper methods like _build... have l10n
  content = content.replace(/(Widget\s+_[a-zA-Z0-9_]+\s*\(\s*(?:BuildContext\s+([a-zA-Z0-9_]+))?[^)]*\)\s*\{)(?![\s\S]{0,100}final\s+l10n\s*=)/g, (match, prefix, ctxName) => {
    const ctx = ctxName || 'context';
    return `${prefix}\n    final l10n = ${ctx}.l10n;`;
  });

  // Fix static const lists with DropdownMenuItem where l10n.t was placed:
  // e.g. static const _types = [DropdownMenuItem(..., child: Text(l10n.t(...)))] -> remove const
  content = content.replace(/static\s+const\s+List<DropdownMenuItem<([^>]+)>>\s+([a-zA-Z0-9_]+)\s*=\s*\[/g, 'static final List<DropdownMenuItem<$1>> $2 = [');
  content = content.replace(/const\s+List<DropdownMenuItem<([^>]+)>>\s+([a-zA-Z0-9_]+)\s*=\s*\[/g, 'final List<DropdownMenuItem<$1>> $2 = [');
  content = content.replace(/const\s+\[\s*DropdownMenuItem/g, '[DropdownMenuItem');

  // Also replace any static method l10n calls with raw strings or getters if inside static context
  // Remove const from enclosing lists or widgets
  content = content.replace(/const\s+<DropdownMenuItem<([^>]+)>>\s*\[/g, '<DropdownMenuItem<$1>>[');

  if (content !== original) {
    fs.writeFileSync(fullPath, content, 'utf8');
    console.log(`Fixed errors in ${relPath}`);
  }
});
