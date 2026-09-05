import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:laundrypro_uae/peripherals/core/storage/app_database.dart';
import 'package:laundrypro_uae/peripherals/core/printer/receipt_template.dart';

class ReceiptTemplateRepository {
  ReceiptTemplateRepository({required AppDatabase database})
      : _database = database;

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  Future<List<ReceiptTemplate>> list() async {
    final rows = await _database.db.query(
      'receipt_templates',
      orderBy: 'created_at DESC',
    );
    return rows.map(ReceiptTemplate.fromRow).toList(growable: false);
  }

  Future<ReceiptTemplate> save(ReceiptTemplate template) async {
    final next = ReceiptTemplate(
      id: template.id.isEmpty ? _uuid.v4() : template.id,
      name: template.name,
      lines: template.lines,
      paper: template.paper,
      createdAt: template.createdAt,
    );
    await _database.db.insert(
      'receipt_templates',
      next.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return next;
  }

  Future<void> delete(String id) async {
    await _database.db.delete(
      'receipt_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
