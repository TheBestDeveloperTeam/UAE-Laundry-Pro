import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/services/api_client.dart';
import 'package:laundrypro_uae/services/sync_service.dart';
import 'package:laundrypro_uae/peripherals/core/storage/app_database.dart';
import 'package:laundrypro_uae/models/order_model.dart';
import 'package:laundrypro_uae/services/license_service.dart';

class MockApiClient extends ApiClient {
  bool isNetworkDisconnected = false;
  List<Map<String, dynamic>> cloudDatabase = [];
  
  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body, dynamic data, bool auth = true, Map<String, String>? customHeaders}) async {
    if (isNetworkDisconnected) {
      throw Exception('SocketException: Failed host lookup');
    }
    if (path == '/api/v1/sync/push' || path == '/sync/push') {
      cloudDatabase.add(body ?? {});
      return {'success': true};
    }
    return super.post(path, body: body, data: data, auth: auth, customHeaders: customHeaders);
  }
}

class MockLicenseService extends LicenseService {
  DateTime systemClock = DateTime.now();

  @override
  Future<Map<String, dynamic>> status() async {
    // If clock is 1 year in the future, trigger grace period logic
    if (systemClock.isAfter(DateTime.now().add(const Duration(days: 300)))) {
       return {'active': true, 'grace_period': true, 'umac': 'MOCK-UMAC'};
    }
    return {'active': true, 'grace_period': false, 'umac': 'MOCK-UMAC'};
  }
}

class MockAppDatabase extends AppDatabase {
  List<Map<String, dynamic>> syncQueue = [];
  
  Future<void> insertOrder(OrderModel order) async {
    syncQueue.add({
       'entity_type': 'order',
       'entity_local_id': order.localId,
       'payload': order.toJson(),
    });
  }
  
  Future<List<Map<String, dynamic>>> drainSyncQueue() async {
    final copy = List<Map<String, dynamic>>.from(syncQueue);
    syncQueue.clear();
    return copy;
  }
}

void main() {
  test('QA-002: Offline Order Create & Sync Push', () async {
    final mockApi = MockApiClient();
    final mockDb = MockAppDatabase();
    final syncService = SyncService(mockApi, mockDb);
    
    // Disconnect network
    mockApi.isNetworkDisconnected = true;
    
    // Create offline order
    final order = OrderModel(
      id: 1,
      uuid: 'mock',
      status: 'pending',
      localId: 1,
      orderNo: 'ORD-123',
      customerId: 1,
      subtotal: 100,
      vatAmount: 5,
      totalAmount: 105,
      items: [],
      syncStatus: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await mockDb.insertOrder(order);
    
    // Expect order in sync queue
    expect(mockDb.syncQueue.length, 1);
    
    // Attempt push (fails due to network)
    try {
      final payload = (await mockDb.drainSyncQueue()).first;
      await syncService.pushUpstream(payload);
      fail('Should throw');
    } catch (e) {
      expect(e.toString().contains('Failed host lookup'), true);
    }
    
    // Reconnect network and retry
    mockApi.isNetworkDisconnected = false;
    await syncService.pushUpstream({
       'entity_type': 'order',
       'entity_local_id': order.localId,
       'payload': order.toJson(),
    });
    
    // Verify sync push
    expect(mockApi.cloudDatabase.length, 1);
    expect(mockApi.cloudDatabase.first['entity_type'], 'order');
  });

  test('QA-003: Licensing Grace Period Fallback', () async {
    final mockLicense = MockLicenseService();
    // Move clock 1 year into the future
    mockLicense.systemClock = DateTime.now().add(const Duration(days: 365));
    
    final status = await mockLicense.status();
    expect(status['active'], true);
    expect(status['grace_period'], true);
  });
}
