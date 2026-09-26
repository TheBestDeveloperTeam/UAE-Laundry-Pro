import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/services/api_client.dart';
import 'package:laundrypro_uae/services/sync_service.dart';
import 'package:laundrypro_uae/providers/sync_provider.dart';
import 'package:laundrypro_uae/peripherals/core/storage/app_database.dart';
import 'package:flutter/material.dart';

class MockApiClient extends ApiClient {
  bool failWith503 = false;
  int retryCount = 0;
  
  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    if (path == '/api/v1/sync/push' || path == '/sync/push') {
      if (failWith503 && retryCount < 2) {
        retryCount++;
        return {'success': false, 'code': 'SERVICE_UNAVAILABLE'};
      }
      return {'success': true};
    }
    return super.post(path, body: body, auth: auth);
  }

  @override
  Future<Map<String, dynamic>> get(String path, {bool auth = true, Map<String, dynamic>? queryParameters}) async {
    if (path == '/sync/status') {
      return {'success': true, 'data': {'enabled': true, 'pending_count': 1}};
    }
    if (path.contains('/sync/pull')) {
      return {'success': true, 'data': {'records': []}};
    }
    return super.get(path, auth: auth, queryParameters: queryParameters);
  }
}

class MockAppDatabase extends AppDatabase {
  // empty mock
}

void main() {
  testWidgets('QA-001: Verify SyncProvider UI states (isSyncing)', (WidgetTester tester) async {
    final mockApi = MockApiClient();
    final mockDb = MockAppDatabase();
    final syncService = SyncService(mockApi, mockDb);
    final syncProvider = SyncProvider(mockApi, syncService);
    
    expect(syncProvider.isSyncing, false);
    
    // Trigger sync
    final syncFuture = syncProvider.forceSync();
    
    // UI state should flip
    expect(syncProvider.isSyncing, true);
    
    await syncFuture;
    
    // UI state should flip back
    expect(syncProvider.isSyncing, false);
  });
  
  test('QA-004: Verify SyncService exponential backoff on 503', () async {
    final mockApi = MockApiClient();
    mockApi.failWith503 = true;
    final mockDb = MockAppDatabase();
    final syncService = SyncService(mockApi, mockDb);
    
    // This should take a few seconds because of backoff
    final startTime = DateTime.now();
    await syncService.pushUpstream({'test': 1});
    final endTime = DateTime.now();
    
    expect(mockApi.retryCount, 2);
    // Exponential backoff wait times: 2^1 + 2^2 = 2s + 4s = 6s
    // So it should take at least 6 seconds.
    final diff = endTime.difference(startTime).inSeconds;
    expect(diff >= 6, true, reason: 'Expected backoff to take >= 6 seconds');
  });
}
