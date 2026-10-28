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
import 'package:provider/provider.dart' as legacy_provider;
import 'support/peripherals_test_support.dart';

// Screens
import 'package:laundrypro_uae/views/login_screen.dart';
import 'package:laundrypro_uae/views/license_screen.dart';
import 'package:laundrypro_uae/views/setup_wizard_screen.dart';
import 'package:laundrypro_uae/views/dashboard_screen.dart';
import 'package:laundrypro_uae/views/pos_screen.dart';
import 'package:laundrypro_uae/views/customers_screen.dart';
import 'package:laundrypro_uae/views/vendors_screen.dart';
import 'package:laundrypro_uae/views/catalog_screen.dart';
import 'package:laundrypro_uae/views/inventory_screen.dart';
import 'package:laundrypro_uae/views/pending_invoices_screen.dart';
import 'package:laundrypro_uae/views/production_screen.dart';
import 'package:laundrypro_uae/views/equipment_screen.dart';
import 'package:laundrypro_uae/views/operator_screen.dart';
import 'package:laundrypro_uae/views/rfid_tracking_screen.dart';
import 'package:laundrypro_uae/views/sterilization_screen.dart';
import 'package:laundrypro_uae/views/advanced_cycle_screen.dart';
import 'package:laundrypro_uae/views/delivery_screen.dart';
import 'package:laundrypro_uae/views/challans_screen.dart';
import 'package:laundrypro_uae/views/purchasing_screen.dart';
import 'package:laundrypro_uae/views/expenses_screen.dart';
import 'package:laundrypro_uae/views/reports_screen.dart';
import 'package:laundrypro_uae/views/analytics_screen.dart';
import 'package:laundrypro_uae/views/notifications_screen.dart';
import 'package:laundrypro_uae/views/branches_screen.dart';
import 'package:laundrypro_uae/views/terminals_screen.dart';
import 'package:laundrypro_uae/views/employees_screen.dart';
import 'package:laundrypro_uae/views/attendance_screen.dart';
import 'package:laundrypro_uae/views/leave_screen.dart';
import 'package:laundrypro_uae/views/payroll_screen.dart';
import 'package:laundrypro_uae/views/salary_advances_screen.dart';
import 'package:laundrypro_uae/views/storefront_screen.dart';
import 'package:laundrypro_uae/views/customer_portal_screen.dart';
import 'package:laundrypro_uae/views/business_screen.dart';
import 'package:laundrypro_uae/views/sync_settings_screen.dart';
import 'package:laundrypro_uae/views/settings_screen.dart';
import 'package:laundrypro_uae/views/peripherals_screen.dart';
import 'package:laundrypro_uae/views/channels_screen.dart';
import 'package:laundrypro_uae/views/accounting_screen.dart';
import 'package:laundrypro_uae/views/localization_screen.dart';
import 'package:laundrypro_uae/views/role_editor_screen.dart';
import 'package:laundrypro_uae/views/global_config_screen.dart';
import 'package:laundrypro_uae/views/app_shell.dart';
import 'package:laundrypro_uae/features/wizard/wizard_screen.dart';

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

  Widget buildScreenHarness(Widget child, {bool isRtl = false, bool wrapInScaffold = true}) {
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
          home: wrapInScaffold ? Scaffold(body: child) : child,
        ),
      ),
    );
  }

  group('Screen Audit - All Screens Mount and Render', () {
    testWidgets('LoginScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const LoginScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('LicenseScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const LicenseScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('SetupWizardScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const SetupWizardScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('DashboardScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const DashboardScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('PosScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const PosScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('CustomersScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const CustomersScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('VendorsScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const VendorsScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('CatalogScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const CatalogScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('InventoryScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const InventoryScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('PendingInvoicesScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const PendingInvoicesScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProductionScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const ProductionScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('EquipmentScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const EquipmentScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('OperatorScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const OperatorScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('RfidTrackingScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const RfidTrackingScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('SterilizationScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const SterilizationScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('AdvancedCycleScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const AdvancedCycleScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('DeliveryScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const DeliveryScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('ChallansScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const ChallansScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('PurchasingScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const PurchasingScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('ExpensesScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const ExpensesScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('ReportsScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const ReportsScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('AnalyticsScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const AnalyticsScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('NotificationsScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const NotificationsScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('BranchesScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const BranchesScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('TerminalsScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const TerminalsScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('EmployeesScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const EmployeesScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('AttendanceScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const AttendanceScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('LeaveScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const LeaveScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('PayrollScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const PayrollScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('SalaryAdvancesScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const SalaryAdvancesScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('StorefrontScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const StorefrontScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('CustomerPortalScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const CustomerPortalScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('BusinessScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const BusinessScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('SyncSettingsScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const SyncSettingsScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('SettingsScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const SettingsScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('PeripheralsScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const PeripheralsScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('ChannelsScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const ChannelsScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('AccountingScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const AccountingScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('LocalizationScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const LocalizationScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('RoleEditorScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const RoleEditorScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('GlobalConfigScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const GlobalConfigScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('WizardScreen renders without crash', (tester) async {
      await tester.pumpWidget(buildScreenHarness(const WizardScreen()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('AppShell renders with nested child without crash', (tester) async {
      await tester.pumpWidget(
        buildScreenHarness(
          const AppShell(
            child: SizedBox(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });
}
