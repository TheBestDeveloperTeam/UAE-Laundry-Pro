import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundrypro_uae/app.dart';
import 'package:laundrypro_uae/peripherals/bootstrap.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/providers/locale_provider.dart';
import 'package:laundrypro_uae/services/api_client.dart';
import 'package:laundrypro_uae/services/auth_service.dart';
import 'package:provider/provider.dart' as legacy_provider;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
            create: (_) => LocaleProvider(),
          ),
        ],
        child: const LaundryProApp(),
      ),
    ),
  );
}
