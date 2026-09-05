import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final appDatabaseProvider = Provider<AppDatabase>((_) {
  throw UnimplementedError('Bootstrap did not initialize AppDatabase');
});

class AppDatabase {
  AppDatabase({required this.dbPath});

  static const int schemaVersion = 2;

  final String dbPath;
  Database? _db;

  Future<void> open() async {
    sqfliteFfiInit();
    final databaseFactory = databaseFactoryFfi;
    _db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: (db, _) async {
          await _createV1(db);
          await _createV2(db);
        },
        onUpgrade: (db, fromVersion, toVersion) async {
          if (fromVersion < 2) {
            await _createV2(db);
          }
        },
      ),
    );
  }

  Future<void> _createV1(Database db) async {
    await db.execute('''
CREATE TABLE log_entries(
  id TEXT PRIMARY KEY,
  level TEXT NOT NULL,
  scope TEXT NOT NULL,
  message TEXT NOT NULL,
  payload TEXT,
  created_at TEXT NOT NULL
)
''');
    await db.execute('''
CREATE TABLE print_queue(
  id TEXT PRIMARY KEY,
  printer_name TEXT NOT NULL,
  connection_type TEXT NOT NULL,
  payload_base64 TEXT NOT NULL,
  status TEXT NOT NULL,
  retries INTEGER NOT NULL,
  created_at TEXT NOT NULL
)
''');
  }

  Future<void> _createV2(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS receipt_templates(
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  lines_json TEXT NOT NULL,
  paper_id TEXT NOT NULL,
  created_at TEXT NOT NULL
)
''');
  }

  Database get db {
    final current = _db;
    if (current == null) {
      throw StateError('Database not open');
    }
    return current;
  }
}
