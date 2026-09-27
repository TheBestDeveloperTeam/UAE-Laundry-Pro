import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundrypro_uae/app.dart';
import 'package:laundrypro_uae/peripherals/bootstrap.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/providers/locale_provider.dart';
import 'package:laundrypro_uae/providers/sync_provider.dart';
import 'package:laundrypro_uae/services/api_client.dart';
import 'package:laundrypro_uae/services/auth_service.dart';
import 'package:laundrypro_uae/services/global_config_service.dart';
import 'package:provider/provider.dart' as legacy_provider;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise global path config + auto-create all directories
  await GlobalConfigService().init();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    try {
      final file = File('${GlobalConfigService().logPath}crash.log');
      file.writeAsStringSync('${DateTime.now()}: ${details.exceptionAsString()}\n', mode: FileMode.append);
    } catch (_) {}
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    try {
      final file = File('${GlobalConfigService().logPath}crash.log');
      file.writeAsStringSync('${DateTime.now()}: $error\n$stack\n', mode: FileMode.append);
    } catch (_) {}
    return true;
  };

  final peripheralContainer = await bootstrapPeripherals();
  final authService = AuthService();
  final apiClient = ApiClient();

  runApp(
    UncontrolledProviderScope(
      container: peripheralContainer,
      child: legacy_provider.MultiProvider(
        providers: [
          legacy_provider.Provider<ApiClient>.value(value: apiClient),
          legacy_provider.ChangeNotifierProvider(
            create: (_) => AuthProvider(authService),
          ),
          legacy_provider.ChangeNotifierProvider(
            create: (context) => SyncProvider(context.read<ApiClient>()),
          ),
          legacy_provider.ChangeNotifierProvider(
            create: (_) => LocaleProvider(),
          ),
        ],
        child: const LaundryProApp(),
      ),
    ),
  );
}
