import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundrypro_uae/core/localization.dart';
import 'package:laundrypro_uae/models/customer_model.dart';
import 'package:laundrypro_uae/models/service_model.dart';
import 'package:laundrypro_uae/models/user_model.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/providers/locale_provider.dart';
import 'package:laundrypro_uae/providers/sync_provider.dart';
import 'package:laundrypro_uae/services/api_client.dart';
import 'package:laundrypro_uae/services/auth_service.dart';
import 'package:laundrypro_uae/services/catalog_service.dart';
import 'package:laundrypro_uae/services/customer_service.dart';
import 'package:laundrypro_uae/services/expense_service.dart';
import 'package:laundrypro_uae/services/sales_service.dart';
import 'package:laundrypro_uae/services/settings_service.dart';
import 'package:laundrypro_uae/services/backup_service.dart';
import 'package:provider/provider.dart' as legacy_provider;

class MockInteractiveApiClient extends ApiClient {
  @override
  Future<Map<String, dynamic>> get(String path, {bool auth = true, Map<String, dynamic>? queryParameters, Map<String, String>? customHeaders}) async {
    if (path == '/roles') {
      return {
        'success': true,
        'data': {
          'roles': [
            {'id': 1, 'name': 'Cashier', 'permissions': ['sales.create', 'sales.reprint']},
            {'id': 2, 'name': 'Admin', 'permissions': ['*']},
          ]
        }
      };
    }
    return {'success': true, 'data': []};
  }

  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body, dynamic data, bool auth = true, Map<String, String>? customHeaders}) async {
    return {'success': true, 'data': {}};
  }
}

class MockInteractiveCustomerService extends CustomerService {
  @override
  Future<List<CustomerModel>> list({String? query}) async {
    return [
      CustomerModel(
        id: 1,
        uuid: 'CUST-001',
        phone: '0501234567',
        name: 'Mohammed Al Nuaimi',
        loyaltyPoints: 120,
        loyaltyTier: 'Silver',
        balance: 0.0,
        createdAt: DateTime(2026, 1, 1),
      ),
      CustomerModel(
        id: 2,
        uuid: 'CUST-002',
        phone: '0559876543',
        name: 'Fatima Al Zarooni',
        loyaltyPoints: 340,
        loyaltyTier: 'Gold',
        balance: 50.0,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];
  }
}

class MockInteractiveExpenseService extends ExpenseService {
  @override
  Future<List<Map<String, dynamic>>> list({String? status, String? from, String? to}) async {
    return [
      {'id': 1, 'amount': 150.0, 'category_id': 1, 'description': 'Detergent Restock', 'status': 'pending'},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> listCategories() async {
    return [
      {'id': 1, 'name': 'Supplies & Chemicals'},
      {'id': 2, 'name': 'Utilities'},
    ];
  }
}

class MockInteractiveSalesService extends SalesService {
  @override
  Future<List<ServiceModel>> loadServices() async {
    return [
      ServiceModel(
        id: 1,
        uuid: 'SRV-001',
        name: 'Wash & Fold - Kandora',
        categoryId: 1,
        price: 15.0,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      ),
      ServiceModel(
        id: 2,
        uuid: 'SRV-002',
        name: 'Dry Clean - Suit 2pc',
        categoryId: 2,
        price: 45.0,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> getBusiness() async {
    return {'display_name': 'UAE Laundry Pro Marina'};
  }
}

class MockInteractiveCatalogService extends CatalogService {
  @override
  Future<List<Map<String, dynamic>>> listProducts({String? barcode, int? parentId}) async {
    return [
      {'id': 1, 'name': 'Garment Hanger Pack', 'price': 12.0, 'category_name': 'Accessories'},
    ];
  }
}

class MockInteractiveSettingsService extends SettingsService {
  @override
  Future<Map<String, dynamic>> getSettings() async {
    return {
      'settings': {'business.name': 'UAE Laundry Pro Flagship'},
    };
  }
}

class MockInteractiveBackupService extends BackupService {
  @override
  Future<List<Map<String, dynamic>>> history() async => [];
}

class MockAuthService extends AuthService {
  @override
  Future<Map<String, dynamic>> health() async => {'status': 'healthy'};
}

Widget buildTestHarness(
  Widget child, {
  required ProviderContainer container,
  bool isRtl = false,
}) {
  final apiClient = MockInteractiveApiClient();
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
    container: container,
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
        key: UniqueKey(),
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
