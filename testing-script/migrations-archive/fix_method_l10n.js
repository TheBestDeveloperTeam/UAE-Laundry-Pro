const fs = require('fs');
const path = require('path');

const viewsDir = 'e:/Projects/Flutter/UAE-Laundry-Pro/lib/views';
const files = fs.readdirSync(viewsDir).filter(f => f.endsWith('.dart'));

files.forEach(file => {
  const filePath = path.join(viewsDir, file);
  let content = fs.readFileSync(filePath, 'utf8');
  let original = content;

  // In State classes or methods that use l10n but don't define it:
  // e.g. void _show...() {
  content = content.replace(/(void\s+_[a-zA-Z0-9_]+\s*\([^)]*\)\s*(?:async\s*)?\{)(?![\s\S]{0,100}final\s+l10n\s*=)/g, (match, prefix) => {
    return `${prefix}\n    final l10n = context.l10n;`;
  });

  // e.g. Future<...> _...() {
  content = content.replace(/(Future<[^>]+>\s+_[a-zA-Z0-9_]+\s*\([^)]*\)\s*(?:async\s*)?\{)(?![\s\S]{0,100}final\s+l10n\s*=)/g, (match, prefix) => {
    return `${prefix}\n    final l10n = context.l10n;`;
  });

  // Also in builder: (dlgCtx, setModalState) =>
  content = content.replace(/builder:\s*\(\s*([a-zA-Z0-9_]+)\s*,\s*([a-zA-Z0-9_]+)\s*\)\s*=>/g, (match, ctxParam, stateParam) => {
    return `builder: (${ctxParam}, ${stateParam}) { final l10n = ${ctxParam}.l10n; return`;
  });
  // If we changed `=>` to `{ return`, we need to balance closing parenthesis of StatefulBuilder if needed, but safer is:
  // let's not break arrow functions unless they were already blocks.

  // Let's remove duplicate `final l10n = context.l10n;\n    final l10n = context.l10n;`
  content = content.replace(/(final\s+l10n\s*=\s*context\.l10n;\s*\n)(\s*final\s+l10n\s*=\s*context\.l10n;\s*\n)+/g, '$1');

  if (content !== original) {
    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`Method-scoped l10n added in ${file}`);
  }
});
