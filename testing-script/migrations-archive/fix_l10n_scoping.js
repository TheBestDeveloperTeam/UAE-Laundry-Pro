// Script to ensure AppLocalizations l10n is defined in build/dialogs and remove invalid const qualifiers
const fs = require('fs');
const path = require('path');

const viewsDir = 'e:/Projects/Flutter/UAE-Laundry-Pro/lib/views';
const files = fs.readdirSync(viewsDir).filter(f => f.endsWith('.dart'));

files.forEach(file => {
  const filePath = path.join(viewsDir, file);
  let content = fs.readFileSync(filePath, 'utf8');
  let original = content;

  // 1. Remove const before widgets containing l10n.t
  content = content.replace(/const\s+Text\s*\(\s*l10n\.t/g, 'Text(l10n.t');
  content = content.replace(/const\s+DropdownMenuItem\s*\(\s*value:\s*([^,]+),\s*child:\s*Text\s*\(\s*l10n\.t/g, 'DropdownMenuItem(value: $1, child: Text(l10n.t');
  content = content.replace(/const\s+([A-Za-z0-9_]+)\s*\(\s*([^)]*?l10n\.t\([^)]*\)[^)]*?)\)/g, (match, widget, inner) => {
    return `${widget}(${inner})`;
  });

  // 2. Ensure AppLocalizations import is present if l10n.t is used
  if (content.includes('l10n.t(') && !content.includes('AppLocalizations.of(') && !content.includes('app_localizations.dart')) {
    content = "import '../core/localization/app_localizations.dart';\n" + content;
  }

  // 3. In build methods: if l10n.t is used in a State/Widget class build method, ensure `final l10n = AppLocalizations.of(context);` exists
  // We can insert `final l10n = AppLocalizations.of(context);` right at the start of `Widget build(BuildContext context) {`
  content = content.replace(/(Widget\s+build\s*\(\s*BuildContext\s+context\s*\)\s*\{)(?![\s\S]{0,100}final\s+l10n\s*=)/g, (match, prefix) => {
    return `${prefix}\n    final l10n = AppLocalizations.of(context);`;
  });

  // 4. In builder methods like showDialog(builder: (ctx) => ...), builder: (context) { ... }
  content = content.replace(/(builder:\s*\(\s*(context|ctx|c)\s*\)\s*\{)(?![\s\S]{0,100}final\s+l10n\s*=)/g, (match, prefix, param) => {
    return `${prefix}\n    final l10n = AppLocalizations.of(${param});`;
  });

  if (content !== original) {
    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`Updated ${file}`);
  }
});
