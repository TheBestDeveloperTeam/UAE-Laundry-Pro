import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:laundrypro_uae/services/api_client.dart';
import 'package:laundrypro_uae/services/sync_service.dart';

class SyncProvider extends ChangeNotifier {
  final ApiClient _api;
  final SyncService? _syncService;
  Timer? _timer;
  bool _isSyncing = false;
  int _pendingCount = 0;
  bool _enabled = false;
  
  SyncProvider(this._api, [this._syncService]) {
    _startPolling();
  }

  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;
  bool get enabled => _enabled;

  void _startPolling() {
    _poll();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final res = await _api.get('/sync/status');
      final data = res['data'] as Map<String, dynamic>?;
      if (data != null) {
        _enabled = data['enabled'] == true;
        _pendingCount = data['pending_count'] ?? 0;
        
        // If there are pending changes, we can trigger a silent push
        if (_enabled && _pendingCount > 0 && !_isSyncing) {
          _silentPush();
        } else {
          notifyListeners();
        }
      }
    } catch (_) {
      // Fail silently to avoid interrupting the user
    }
  }

  Future<void> _silentPush() async {
    _isSyncing = true;
    notifyListeners();
    try {
      if (_syncService != null) {
         await _syncService!.pushUpstream({});
         await _syncService!.pullDownstream();
      } else {
         await _api.post('/sync/push', body: {});
      }
      
      // Refresh status after push
      final res = await _api.get('/sync/status');
      final data = res['data'] as Map<String, dynamic>?;
      if (data != null) {
        _pendingCount = data['pending_count'] ?? 0;
      }
    } catch (_) {
      // Fail silently
    } finally {
      _isSyncing = false;
      notifyListeners(); // FLUTTER-SYNC-006: Trigger foreground UI sync indicators
    }
  }

  Future<void> forceSync() async {
    await _silentPush();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
