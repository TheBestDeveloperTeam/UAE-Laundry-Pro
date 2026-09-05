import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundrypro_uae/peripherals/core/logging/app_logger.dart';
import 'package:laundrypro_uae/peripherals/core/storage/app_database.dart';

Future<ProviderContainer> createTestPeripheralContainer() async {
  final tempDir = Directory.systemTemp.createTempSync('laundrypro_peripheral_test_');
  final dbPath = '${tempDir.path}/peripherals.db';
  final logsDir = Directory('${tempDir.path}/logs');
  logsDir.createSync(recursive: true);

  final database = AppDatabase(dbPath: dbPath);
  await database.open();

  final logger = AppLogger(logDirectoryPath: logsDir.path, database: database);
  await logger.initialize();

  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      appLoggerProvider.overrideWithValue(logger),
    ],
  );
}
