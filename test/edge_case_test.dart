import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/core/localization.dart';
import 'peripherals_test_support.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/services/auth_service.dart';
import 'package:laundrypro_uae/services/license_service.dart';
import 'package:laundrypro_uae/services/sales_service.dart';
import 'package:laundrypro_uae/views/pos_screen.dart';

class FakeSalesService extends SalesService {
  FakeSalesService({
    this.services = const [],
    this.pending = const [],
    this.partial = const [],
  });

  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> pending;
  final List<Map<String, dynamic>> partial;

  @override
  Future<List<Map<String, dynamic>>> loadServices() async => services;

  @override
  Future<List<Map<String, dynamic>>> listPending() async => pending;

  @override
  Future<List<Map<String, dynamic>>> listPartial() async => partial;

  @override
  Future<Map<String, dynamic>> getBusiness() async => {'display_name': 'Test Laundry'};
}

class FakeLicenseService extends LicenseService {
  FakeLicenseService({this.active = true});

  final bool active;

  @override
  Future<Map<String, dynamic>> status() async => {
        'active': active,
        'umac': 'test-umac-hash',
      };
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

  Widget wrapWidget(Widget child) {
    return UncontrolledProviderScope(
      container: peripheralContainer,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: child,
      ),
    );
  }

  testWidgets('POS shows empty cart message and disabled confirm', (tester) async {
    await tester.pumpWidget(
      wrapWidget(PosScreen(salesService: FakeSalesService())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Cart is empty — tap a service to add'), findsOneWidget);
    final confirmBtn = tester.widget<FilledButton>(find.byKey(const Key('pos_confirm_btn')));
    expect(confirmBtn.onPressed, isNull);
    expect(find.byKey(const Key('pos_pay_btn')), findsNothing);
  });

  test('AuthProvider reflects inactive license', () async {
    final provider = AuthProvider(
      AuthService(),
      licenseService: FakeLicenseService(active: false),
    );
    provider.apiHealthy = true;
    await provider.checkLicense();
    expect(provider.licenseActive, isFalse);
    expect(provider.licenseChecked, isTrue);
    expect(provider.licenseBypass, isFalse);
  });

  test('AuthProvider bypasses license when API unhealthy', () async {
    final provider = AuthProvider(
      AuthService(),
      licenseService: FakeLicenseService(active: false),
    );
    provider.apiHealthy = false;
    await provider.checkLicense();
    expect(provider.licenseActive, isTrue);
    expect(provider.licenseBypass, isTrue);
  });
}
