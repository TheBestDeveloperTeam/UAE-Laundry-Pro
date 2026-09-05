import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:laundrypro_uae/peripherals/core/storage/app_database.dart';
import 'package:laundrypro_uae/peripherals/core/printer/printer_models.dart';

class PrintQueueManager {
  PrintQueueManager({required AppDatabase database}) : _database = database;

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  Future<void> enqueue(PrintJobModel job) async {
    await _database.db.insert('print_queue', {
      'id': _uuid.v4(),
      'printer_name': job.printerName,
      'connection_type': job.connectionType,
      'payload_base64': base64Encode(job.payload),
      'status': 'queued',
      'retries': 0,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> pendingByPrinter(String printerName) {
    return _database.db.query(
      'print_queue',
      where: 'status = ? AND printer_name = ?',
      whereArgs: ['queued', printerName],
      orderBy: 'created_at ASC',
      limit: 50,
    );
  }
}
