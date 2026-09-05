import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:laundrypro_uae/peripherals/core/logging/app_logger.dart';
import 'package:laundrypro_uae/peripherals/core/printer/receipt_template_repository.dart';
import 'package:laundrypro_uae/peripherals/core/printer/receipt_template_seed.dart';
import 'package:laundrypro_uae/peripherals/core/storage/app_database.dart';

Future<ProviderContainer> bootstrapPeripherals() async {
  final appDir = await getApplicationSupportDirectory();
  final dbPath = p.join(appDir.path, 'laundrypro_peripherals.db');
  final logsDir = Directory(p.join(appDir.path, 'logs', 'peripherals'));
  if (!logsDir.existsSync()) {
    logsDir.createSync(recursive: true);
  }

  final database = AppDatabase(dbPath: dbPath);
  await database.open();

  final logger = AppLogger(logDirectoryPath: logsDir.path, database: database);
  await logger.initialize();
  await ReceiptTemplateSeed(
    repository: ReceiptTemplateRepository(database: database),
  ).ensureBundledPosTemplate();
  logger.info('Peripherals bootstrapped');

  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      appLoggerProvider.overrideWithValue(logger),
    ],
  );
}
