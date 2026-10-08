import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/services/sync_service.dart';
import 'package:laundrypro_uae/providers/sync_provider.dart';
import 'package:laundrypro_uae/services/api_client.dart';
import 'package:laundrypro_uae/peripherals/core/storage/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisconnectingApiClient extends ApiClient {
  bool isOnline = true;

  @override
  Future<Map<String, dynamic>> get(String path, {bool auth = true, Map<String, dynamic>? queryParameters, Map<String, String>? customHeaders}) async {
    if (!isOnline) {
      throw Exception('SocketException: Network connection lost (Offline Mode)');
    }
    return {'success': true, 'data': {'enabled': true, 'pending_count': 0}};
  }

  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body, dynamic data, bool auth = true, Map<String, String>? customHeaders}) async {
    if (!isOnline) {
      throw Exception('SocketException: Network unreachable (Offline Mode)');
    }
    return {'success': true, 'data': {'accepted_count': 1}};
  }
}

class TestMockDatabase extends AppDatabase {}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('E2E Offline Mode: UI gracefully handles socket disconnect and preserves state', (WidgetTester tester) async {
    final client = DisconnectingApiClient();
    final db = TestMockDatabase();
    final syncService = SyncService(client, db);
    final provider = SyncProvider(client, syncService);

    // Initial state: Online
    expect(provider.isSyncing, false);

    // Simulate Network Disconnect (Offline Mode)
    client.isOnline = false;

    // Trigger sync while network is disconnected
    final syncCall = provider.forceSync();
    expect(provider.isSyncing, true);

    await syncCall;

    // UI state must recover to not syncing without crashing the application
    expect(provider.isSyncing, false);

    // Reconnect Network
    client.isOnline = true;
    final onlineSync = provider.forceSync();
    expect(provider.isSyncing, true);

    await onlineSync;
    expect(provider.isSyncing, false);

    provider.dispose();
  });
}
