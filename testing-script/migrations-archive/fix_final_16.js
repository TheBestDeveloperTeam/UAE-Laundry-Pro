const fs = require('fs');

// 1. wizard_screen.dart: change `List<Step> get _steps => [` to `List<Step> _steps(BuildContext context) { final l10n = context.l10n; return [`
let wizard = fs.readFileSync('e:/Projects/Flutter/UAE-Laundry-Pro/lib/features/wizard/wizard_screen.dart', 'utf8');
wizard = wizard.replace(/List<Step>\s+get\s+_steps\s*=>\s*\[/g, 'List<Step> _steps(BuildContext context) {\n    final l10n = context.l10n;\n    return [');
wizard = wizard.replace(/(steps:\s*)_steps,/g, '$1_steps(context),');
wizard = wizard.replace(/(\]\s*;\s*\}\s*)$/m, '];\n  }');
// ensure closing brace matching the new method if needed
if (!wizard.includes('List<Step> _steps(BuildContext context)')) {
  // alternative replace
  wizard = wizard.replace('List<Step> get _steps => [', 'List<Step> _steps(BuildContext context) {\n    final l10n = context.l10n;\n    return [');
  wizard = wizard.replace('steps: _steps,', 'steps: _steps(context),');
  wizard = wizard.replace(/\];\s*\n\s*@override\s*\n\s*Widget build/, '];\n  }\n\n  @override\n  Widget build');
}
fs.writeFileSync('e:/Projects/Flutter/UAE-Laundry-Pro/lib/features/wizard/wizard_screen.dart', wizard, 'utf8');
console.log('Fixed wizard_screen.dart');

// 2. print_queue_panel.dart: add import and l10n in build
let pQueue = fs.readFileSync('e:/Projects/Flutter/UAE-Laundry-Pro/lib/peripherals/features/printer/widgets/print_queue_panel.dart', 'utf8');
if (!pQueue.includes('localization_extension.dart')) {
  pQueue = "import 'package:laundrypro_uae/core/localization_extension.dart';\n" + pQueue;
}
pQueue = pQueue.replace(/(Widget\s+build\s*\(\s*BuildContext\s+context\s*,\s*WidgetRef\s+ref\s*\)\s*\{)/, '$1\n    final l10n = context.l10n;');
fs.writeFileSync('e:/Projects/Flutter/UAE-Laundry-Pro/lib/peripherals/features/printer/widgets/print_queue_panel.dart', pQueue, 'utf8');
console.log('Fixed print_queue_panel.dart');

// 3. printer_panel.dart: inside _saveAsTemplate, builder: (dialogCtx) => AlertDialog(title: Text(l10n.t(...)))
let pPanel = fs.readFileSync('e:/Projects/Flutter/UAE-Laundry-Pro/lib/peripherals/features/printer/widgets/printer_panel.dart', 'utf8');
if (!pPanel.includes('localization_extension.dart')) {
  pPanel = "import 'package:laundrypro_uae/core/localization_extension.dart';\n" + pPanel;
}
pPanel = pPanel.replace(/builder:\s*\(dialogCtx\)\s*=>\s*AlertDialog\(\s*title:\s*Text\(l10n\.t/g, 'builder: (dialogCtx) => AlertDialog(\n        title: Text(dialogCtx.l10n.t');
fs.writeFileSync('e:/Projects/Flutter/UAE-Laundry-Pro/lib/peripherals/features/printer/widgets/printer_panel.dart', pPanel, 'utf8');
console.log('Fixed printer_panel.dart');

// 4. print_preview_dialog.dart: ensure l10n is available inside build
let pPreview = fs.readFileSync('e:/Projects/Flutter/UAE-Laundry-Pro/lib/peripherals/features/printer/widgets/print_preview_dialog.dart', 'utf8');
if (!pPreview.includes('localization_extension.dart')) {
  pPreview = "import 'package:laundrypro_uae/core/localization_extension.dart';\n" + pPreview;
}
pPreview = pPreview.replace(/return\s+Text\(l10n\.t\('print_no_printers'\)\);/g, "return Text(context.l10n.t('print_no_printers'));");
fs.writeFileSync('e:/Projects/Flutter/UAE-Laundry-Pro/lib/peripherals/features/printer/widgets/print_preview_dialog.dart', pPreview, 'utf8');
console.log('Fixed print_preview_dialog.dart');

// 5. template_picker_dialog.dart: inside itemBuilder: (context, index)
let tPicker = fs.readFileSync('e:/Projects/Flutter/UAE-Laundry-Pro/lib/peripherals/features/printer/widgets/template_picker_dialog.dart', 'utf8');
if (!tPicker.includes('localization_extension.dart')) {
  tPicker = "import 'package:laundrypro_uae/core/localization_extension.dart';\n" + tPicker;
}
tPicker = tPicker.replace(/tooltip:\s*l10n\.t\('printer_delete_template'\)/g, "tooltip: context.l10n.t('printer_delete_template')");
fs.writeFileSync('e:/Projects/Flutter/UAE-Laundry-Pro/lib/peripherals/features/printer/widgets/template_picker_dialog.dart', tPicker, 'utf8');
console.log('Fixed template_picker_dialog.dart');
