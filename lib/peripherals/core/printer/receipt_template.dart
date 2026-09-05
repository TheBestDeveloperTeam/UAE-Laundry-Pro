import 'dart:convert';

import 'package:laundrypro_uae/peripherals/core/printer/paper_size.dart';

class ReceiptTemplate {
  ReceiptTemplate({
    required this.id,
    required this.name,
    required this.lines,
    required this.paper,
    required this.createdAt,
  });

  final String id;
  final String name;
  final List<String> lines;
  final PaperSize paper;
  final DateTime createdAt;

  Map<String, Object?> toRow() => {
        'id': id,
        'name': name,
        'lines_json': jsonEncode(lines),
        'paper_id': paper.id,
        'created_at': createdAt.toIso8601String(),
      };

  static ReceiptTemplate fromRow(Map<String, Object?> row) {
    final raw = row['lines_json']?.toString() ?? '[]';
    final decoded = (jsonDecode(raw) as List).cast<dynamic>().map((e) => e.toString()).toList();
    return ReceiptTemplate(
      id: row['id']!.toString(),
      name: row['name']!.toString(),
      lines: decoded,
      paper: PaperSize.fromId(row['paper_id']?.toString()),
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}
