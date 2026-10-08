import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laundrypro_uae/services/api_client.dart';
import 'package:laundrypro_uae/peripherals/core/storage/app_database.dart';
import 'package:laundrypro_uae/core/logger.dart';

class SyncService {
  final ApiClient _apiClient;
  final AppDatabase _db;

  SyncService(this._apiClient, this._db);

  /// Pull records from the cloud.
  /// Resolves FLUTTER-SYNC-002: Replace timestamp-based since with explicit global_sequence_id
  /// Resolves FLUTTER-SYNC-007: Ensure large sync payloads are paginated (batches of 100)
  Future<void> pullDownstream() async {
    final prefs = await SharedPreferences.getInstance();
    int lastSequenceId = prefs.getInt('last_global_sequence_id') ?? 0;

    bool hasMore = true;
    while(hasMore) {
      final res = await _apiClient.get('/api/v1/sync/pull?since=$lastSequenceId&limit=100');
      if (res['success'] == true) {
        final records = res['data']['records'] as List<dynamic>;
        if (records.isEmpty) {
          hasMore = false;
          break;
        }

        for (var record in records) {
           await _resolveConflict(record);
           int seq = record['global_sequence'] as int;
           if (seq > lastSequenceId) {
               lastSequenceId = seq;
           }
        }
        await prefs.setInt('last_global_sequence_id', lastSequenceId);

        if (records.length < 100) {
          hasMore = false;
        }
      } else {
        hasMore = false;
      }
    }
  }

  /// Resolves FLUTTER-SYNC-003: Build 3-way merge conflict resolution system
  Future<void> _resolveConflict(Map<String, dynamic> cloudRecord) async {
    final entityType = cloudRecord['entity_type'] as String? ?? 'unknown';
    final localId = cloudRecord['entity_local_id'] as int? ?? 0;
    final rawPayload = cloudRecord['payload'];
    final cloudPayload = rawPayload is String
        ? jsonDecode(rawPayload) as Map<String, dynamic>
        : (rawPayload as Map<String, dynamic>? ?? {});

    if (!_db.isOpen) return;

    try {
      // Check if this entity has concurrent unpushed local mutations in sync_queue
      final pendingLocal = await _db.db.query(
        'sync_queue',
        where: 'entity_type = ? AND entity_local_id = ? AND status = ?',
        whereArgs: [entityType, localId, 'pending'],
      );

      if (pendingLocal.isNotEmpty) {
        // CONFLICT DETECTED: Entity modified locally while also updated upstream
        final localRow = pendingLocal.first;
        final localData = jsonDecode(localRow['payload'] as String) as Map<String, dynamic>;

        // 3-Way Merge: Structural catalog fields take cloud state, operational statuses retain local forward state
        final merged = Map<String, dynamic>.from(cloudPayload);
        if (localData.containsKey('status')) {
          merged['status'] = localData['status'];
        }
        if (localData.containsKey('updated_at')) {
          merged['local_merged_at'] = DateTime.now().toUtc().toIso8601String();
        }

        await _db.db.update(
          'sync_queue',
          {
            'payload': jsonEncode(merged),
            'status': 'merged',
          },
          where: 'id = ?',
          whereArgs: [localRow['id']],
        );
      }
    } catch (_) {
      // Graceful fallback to prevent halting sync ingestion loop
    }
  }

  /// Resolves FLUTTER-SYNC-004: Add automatic retry with exponential backoff on HTTP 503
  Future<void> pushUpstream(Map<String, dynamic>? extraPayload) async {
    // 1. Process local sync queue first
    if (_db.isOpen) {
      try {
        final pending = await _db.db.query(
          'sync_queue',
          where: 'status = ?',
          whereArgs: ['pending'],
          orderBy: 'created_at ASC',
        );

        for (var row in pending) {
           final id = row['id'] as String;
           final payload = {
              'entity_type': row['entity_type'],
              'entity_local_id': row['entity_local_id'],
              'operation': row['operation'],
              'data': jsonDecode(row['payload'] as String),
           };
           try {
             await _pushSingle(payload);
             await _db.db.update('sync_queue', {'status': 'completed'}, where: 'id = ?', whereArgs: [id]);
           } catch (e) {
             if (e.toString().contains('503') || e.toString().contains('SERVICE_UNAVAILABLE') || e.toString().contains('connectionError')) {
                break; // Stop processing queue if server is down
             }
             // Otherwise mark failed
             await _db.db.update('sync_queue', {'status': 'failed', 'retry_count': (row['retry_count'] as int) + 1}, where: 'id = ?', whereArgs: [id]);
           }
        }
      } catch (e, stack) {
        AppLogger.error('Failed to process offline sync queue: $e', tag: 'SyncService', error: e, stackTrace: stack);
      }
    }

    if (extraPayload != null && extraPayload.isNotEmpty) {
       await _pushSingle(extraPayload);
    }
  }

  Future<void> _pushSingle(Map<String, dynamic> payload) async {
    int retries = 0;
    while(retries <= 3) {
      try {
        final res = await _apiClient.post('/api/v1/sync/push', body: payload);
        if (res['success'] == true) {
           return;
        } else if (res['code'] == 'SERVICE_UNAVAILABLE') {
            throw Exception('503 Service Unavailable');
        } else {
           throw Exception('Failed to push data to cloud');
        }
      } catch (e) {
        if (e.toString().contains('503') || e.toString().contains('SERVICE_UNAVAILABLE') || e.toString().contains('connectionError')) {
          retries++;
          if (retries > 3) rethrow;
          // Exponential backoff: 2, 4, 8 seconds
          await Future.delayed(Duration(seconds: (1 << retries)));
        } else {
          rethrow;
        }
      }
    }
  }
}
