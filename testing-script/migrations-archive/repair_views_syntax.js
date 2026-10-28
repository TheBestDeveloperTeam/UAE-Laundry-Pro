const fs = require('fs');
const path = require('path');

const viewsDir = 'e:/Projects/Flutter/UAE-Laundry-Pro/lib/views';
const files = fs.readdirSync(viewsDir).filter(f => f.endsWith('.dart'));

files.forEach(file => {
  const filePath = path.join(viewsDir, file);
  let content = fs.readFileSync(filePath, 'utf8');
  let original = content;

  // 1. Fix the StatefulBuilder conversion
  // If `builder: (dlgCtx, setModalState) { final l10n = dlgCtx.l10n; return AlertDialog(`
  // was used without matching `); }`, revert it to arrow function `builder: (dlgCtx, setModalState) => AlertDialog(`
  content = content.replace(/builder:\s*\(\s*([a-zA-Z0-9_]+)\s*,\s*([a-zA-Z0-9_]+)\s*\)\s*\{\s*final\s+l10n\s*=\s*[a-zA-Z0-9_]+\.l10n;\s*return\s+([A-Za-z0-9_]+)\(/g, 'builder: ($1, $2) => $3(');

  // 2. Remove const before any widget containing l10n.t or .replaceAll or string interpolation
  // Repeat several times to handle nested consts
  for (let i = 0; i < 5; i++) {
    content = content.replace(/const\s+([A-Za-z0-9_]+)\s*\(\s*([^;]+?l10n\.t[^;]+?)\)/g, '$1($2)');
    content = content.replace(/const\s+([A-Za-z0-9_]+)\s*\(\s*([^;]+?context\.l10n[^;]+?)\)/g, '$1($2)');
  }

  // 3. Remove unnecessary const warnings inside widgets
  content = content.replace(/const\s+SnackBar\s*\(/g, 'SnackBar(');
  content = content.replace(/const\s+InputDecoration\s*\(/g, 'InputDecoration(');

  if (content !== original) {
    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`Repaired ${file}`);
  }
});
