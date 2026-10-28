const fs = require('fs');
const path = require('path');

const viewsDir = 'e:/Projects/Flutter/UAE-Laundry-Pro/lib/views';
const files = fs.readdirSync(viewsDir).filter(f => f.endsWith('.dart'));

files.forEach(file => {
  const filePath = path.join(viewsDir, file);
  let content = fs.readFileSync(filePath, 'utf8');
  let original = content;

  // 1. Remove incorrect import if added
  content = content.replace(/import\s+'\.\.\/core\/localization\/app_localizations\.dart';\s*\n?/g, '');

  // 2. Ensure localization_extension.dart import is present
  if (content.includes('l10n') && !content.includes('localization_extension.dart')) {
    content = "import 'package:laundrypro_uae/core/localization_extension.dart';\n" + content;
  }

  // 3. Replace AppLocalizations.of(context) or AppLocalizations.of(ctx) with context.l10n or ctx.l10n
  content = content.replace(/AppLocalizations\.of\(([a-zA-Z0-9_]+)\)/g, '$1.l10n');

  // 4. Ensure builder functions have `final l10n = ...` if they reference l10n inside
  // e.g. builder: (ctx) => or builder: (context) {
  content = content.replace(/builder:\s*\(\s*([a-zA-Z0-9_]+)\s*\)\s*\{/g, (match, param) => {
    return `${match}\n    final l10n = ${param}.l10n;`;
  });

  // Also remove duplicate `final l10n = ` within 3 lines of each other
  content = content.replace(/(final\s+l10n\s*=\s*[a-zA-Z0-9_]+\.l10n;\s*\n)(\s*final\s+l10n\s*=\s*[a-zA-Z0-9_]+\.l10n;\s*\n)+/g, '$1');

  // 5. Remove any leftover invalid const Text(l10n.t(...)) or const Widget(l10n.t(...))
  content = content.replace(/const\s+Text\s*\(\s*l10n\.t/g, 'Text(l10n.t');
  content = content.replace(/const\s+DropdownMenuItem\s*\(\s*value:\s*([^,]+),\s*child:\s*Text\s*\(\s*l10n\.t/g, 'DropdownMenuItem(value: $1, child: Text(l10n.t');

  if (content !== original) {
    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`Cleaned up ${file}`);
  }
});
