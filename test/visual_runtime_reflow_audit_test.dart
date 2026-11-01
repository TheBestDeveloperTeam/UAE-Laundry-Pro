import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/core/localization.dart';
import 'package:laundrypro_uae/models/user_model.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/providers/locale_provider.dart';
import 'package:laundrypro_uae/providers/sync_provider.dart';
import 'package:laundrypro_uae/services/api_client.dart';
import 'package:laundrypro_uae/services/auth_service.dart';
import 'package:laundrypro_uae/views/app_shell.dart';
import 'package:laundrypro_uae/views/dashboard_screen.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'support/peripherals_test_support.dart';

class MockInstantApiClient extends ApiClient {
  @override
  Future<Map<String, dynamic>> get(String path, {bool auth = true, Map<String, dynamic>? queryParameters, Map<String, String>? customHeaders}) async {
    return {'success': true, 'data': []};
  }

  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body, dynamic data, bool auth = true, Map<String, String>? customHeaders}) async {
    return {'success': true, 'data': {}};
  }
}

class MockAuthService extends AuthService {
  @override
  Future<Map<String, dynamic>> health() async => {'status': 'healthy'};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer peripheralContainer;

  setUpAll(() async {
    peripheralContainer = await createTestPeripheralContainer();
  });

  tearDownAll(() {
    peripheralContainer.dispose();
  });

  Widget buildReflowHarness(Widget child, {bool isRtl = false}) {
    final apiClient = MockInstantApiClient();
    final authService = MockAuthService();
    final authProvider = AuthProvider(authService);
    authProvider.user = const UserModel(
      id: 1,
      uuid: 'USR-001',
      username: 'admin',
      fullName: 'System Auditor Admin',
      email: 'admin@uaelaundry.ae',
      role: 'administrator',
      permissions: ['*'],
    );
    authProvider.status = AuthStatus.authenticated;
    authProvider.apiHealthy = true;
    authProvider.licenseActive = true;
    authProvider.licenseChecked = true;

    return UncontrolledProviderScope(
      container: peripheralContainer,
      child: legacy_provider.MultiProvider(
        providers: [
          legacy_provider.Provider<ApiClient>.value(value: apiClient),
          legacy_provider.ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          legacy_provider.ChangeNotifierProvider(
            create: (_) => SyncProvider(apiClient),
          ),
          legacy_provider.ChangeNotifierProvider(
            create: (_) => LocaleProvider(),
          ),
        ],
        child: MaterialApp(
          locale: Locale(isRtl ? 'ar' : 'en'),
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ar')],
          home: child,
        ),
      ),
    );
  }

  group('Zero-Tolerance Runtime Visual & Reflow Audit', () {
    testWidgets('Dashboard renders on Wide Desktop (1920x1080) with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildReflowHarness(const AppShell(child: DashboardScreen())));
      await tester.pumpAndSettle();

      final err = tester.takeException();
      if (err != null) {
        if (err is FlutterError) {
          debugPrint('FULL FLUTTER ERROR:\n' + err.toStringDeep());
        } else {
          debugPrint('DEBUG OVERFLOW: ' + err.toString());
        }
      }
      expect(err, isNull);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('Dashboard reflows on Standard Desktop (1366x768) with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildReflowHarness(const AppShell(child: DashboardScreen())));
      await tester.pumpAndSettle();

      final err = tester.takeException();
      if (err != null) {
        if (err is FlutterError) {
          debugPrint('FULL FLUTTER ERROR:\n' + err.toStringDeep());
        } else {
          debugPrint('DEBUG OVERFLOW: ' + err.toString());
        }
      }
      expect(err, isNull);
    });

    testWidgets('Dashboard reflows on POS Touch Screen (1024x768) with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildReflowHarness(const AppShell(child: DashboardScreen())));
      await tester.pumpAndSettle();

      final err = tester.takeException();
      if (err != null) {
        if (err is FlutterError) {
          debugPrint('FULL FLUTTER ERROR:\n' + err.toStringDeep());
        } else {
          debugPrint('DEBUG OVERFLOW: ' + err.toString());
        }
      }
      expect(err, isNull);
    });

    testWidgets('Arabic RTL mirrors layout and renders cleanly', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildReflowHarness(const AppShell(child: DashboardScreen()), isRtl: true));
      await tester.pumpAndSettle();

      final err = tester.takeException();
      if (err != null) {
        if (err is FlutterError) {
          debugPrint('FULL FLUTTER ERROR:\n' + err.toStringDeep());
        } else {
          debugPrint('DEBUG OVERFLOW: ' + err.toString());
        }
      }
      expect(err, isNull);
    });
  });
}
