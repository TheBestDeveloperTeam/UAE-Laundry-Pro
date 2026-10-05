import 'dart:io';

void main() {
  final dir = Directory('e:/Projects/Flutter/UAE-Laundry-Pro/lib/views');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  const importStmt = "import 'package:laundrypro_uae/widgets/glass_card.dart';";

  for (final file in files) {
    // Skip already explicitly refactored ones
    if (file.path.endsWith('dashboard_screen.dart') || file.path.endsWith('pos_screen.dart') || file.path.endsWith('app_shell.dart')) {
      continue;
    }
    
    String content = file.readAsStringSync();
    if (content.contains('Card(') && !content.contains(importStmt)) {
      // Find the last import
      final lastImportIndex = content.lastIndexOf(RegExp(r"import '.*';"));
      if (lastImportIndex != -1) {
        final endOfImport = content.indexOf(';', lastImportIndex) + 1;
        content = '${content.substring(0, endOfImport)}\n$importStmt${content.substring(endOfImport)}';
      } else {
        content = '$importStmt\n$content';
      }
      content = content.replaceAll('Card(', 'GlassCard(padding: const EdgeInsets.all(0), ');
      file.writeAsStringSync(content);
      stdout.writeln('Refactored ${file.path}');
    }
  }
}
