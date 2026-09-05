import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'package:laundrypro_uae/peripherals/core/storage/app_database.dart';

final appLoggerProvider = Provider<AppLogger>((_) {
  throw UnimplementedError('Bootstrap did not initialize AppLogger');
});

class AppLogEntry {
  AppLogEntry({
    required this.id,
    required this.level,
    required this.scope,
    required this.message,
    required this.createdAt,
    this.payload,
  });

  final String id;
  final String level;
  final String scope;
  final String message;
  final DateTime createdAt;
  final Map<String, dynamic>? payload;

  Map<String, dynamic> toJson() => {
        'id': id,
        'level': level,
        'scope': scope,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'payload': payload,
      };
}

class AppLogger {
  AppLogger({required this.logDirectoryPath, required this.database});

  final String logDirectoryPath;
  final AppDatabase database;
  final Uuid _uuid = const Uuid();
  final StreamController<AppLogEntry> _streamController =
      StreamController<AppLogEntry>.broadcast();
  late final File _dailyFile;

  Stream<AppLogEntry> get stream => _streamController.stream;

  Future<void> initialize() async {
    final date = DateTime.now().toIso8601String().split('T').first;
    _dailyFile = File(p.join(logDirectoryPath, 'logs_$date.jsonl'));
    if (!_dailyFile.existsSync()) {
      _dailyFile.createSync(recursive: true);
    }
  }

  Future<void> info(String message, {String scope = 'app', Map<String, dynamic>? payload}) async {
    await _write(level: 'INFO', message: message, scope: scope, payload: payload);
  }

  Future<void> warning(String message, {String scope = 'app', Map<String, dynamic>? payload}) async {
    await _write(level: 'WARN', message: message, scope: scope, payload: payload);
  }

  Future<void> error(String message, {String scope = 'app', Map<String, dynamic>? payload}) async {
    await _write(level: 'ERROR', message: message, scope: scope, payload: payload);
  }

  Future<void> _write({
    required String level,
    required String scope,
    required String message,
    Map<String, dynamic>? payload,
  }) async {
    final entry = AppLogEntry(
      id: _uuid.v4(),
      level: level,
      scope: scope,
      message: message,
      payload: payload,
      createdAt: DateTime.now().toUtc(),
    );
    _streamController.add(entry);
    await _dailyFile.writeAsString('${jsonEncode(entry.toJson())}\n', mode: FileMode.append);
    await database.db.insert(
      'log_entries',
      {
        'id': entry.id,
        'level': entry.level,
        'scope': entry.scope,
        'message': entry.message,
        'payload': entry.payload == null ? null : jsonEncode(entry.payload),
        'created_at': entry.createdAt.toIso8601String(),
      },
    );
  }
}
