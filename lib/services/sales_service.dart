import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:laundrypro_uae/peripherals/core/storage/app_database.dart';
import 'package:laundrypro_uae/services/api_client.dart';
import 'package:laundrypro_uae/models/order_model.dart';
import 'package:laundrypro_uae/models/service_model.dart';

class SalesService {
  SalesService({ApiClient? apiClient, AppDatabase? database})
      : _api = apiClient ?? ApiClient(),
        _database = database;

  final ApiClient _api;
  final AppDatabase? _database;

  Future<List<ServiceModel>> loadServices() async {
    try {
      final res = await _api.get('/services');
      final list = res['data']?['services'] as List? ?? [];
      return list.map((e) => ServiceModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      if (_isOfflineError(e) && _database != null) {
        // Local cache lookup would go here
        return [];
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBusiness() async {
    final res = await _api.get('/business');
    return Map<String, dynamic>.from(res['data']?['business'] as Map? ?? {});
  }

  Future<OrderModel> createDraft({
    int? customerId,
    required List<Map<String, dynamic>> lines,
  }) async {
    final body = {
      if (customerId != null) 'customer_id': customerId,
      'lines': lines,
    };
    try {
      final res = await _api.post('/sales/draft', body: body);
      return OrderModel.fromJson(Map<String, dynamic>.from(res['data']?['order'] as Map? ?? {}));
    } catch (e) {
      if (_isOfflineError(e) && _database != null) {
        final offlineId = 'offline_${const Uuid().v4()}';
        await _queueSync('order', body, operation: 'create_draft', localId: offlineId);
        return OrderModel(
          id: -1, // Unassigned
          orderNumber: offlineId,
          status: 'draft',
          paymentStatus: 'unpaid',
          subtotal: _calculateTotal(lines),
          discountTotal: 0,
          vatTotal: 0,
          grandTotal: _calculateTotal(lines),
          createdAt: DateTime.now(),
        );
      }
      rethrow;
    }
  }

  Future<OrderModel> confirm(int orderId) async {
    try {
      final res = await _api.post('/sales/$orderId/confirm');
      return OrderModel.fromJson(Map<String, dynamic>.from(res['data']?['order'] as Map? ?? {}));
    } catch (e) {
      if (_isOfflineError(e) && _database != null) {
        await _queueSync('order', {}, operation: 'confirm', localId: orderId.toString());
        throw Exception('Order marked for offline confirmation. Will sync when online.');
      }
      rethrow;
    }
  }

  Future<OrderModel> postPayment(
    int orderId, {
    required double amount,
    String method = 'cash',
    String? referenceNumber,
  }) async {
    final body = {
      'amount': amount,
      'payment_method': method,
      if (referenceNumber != null && referenceNumber.isNotEmpty)
        'reference_number': referenceNumber,
    };
    try {
      final res = await _api.post('/sales/$orderId/payment', body: body);
      return OrderModel.fromJson(Map<String, dynamic>.from(res['data']?['order'] as Map? ?? {}));
    } catch (e) {
      if (_isOfflineError(e) && _database != null) {
        await _queueSync('payment', body, operation: 'post_payment', localId: orderId.toString());
        throw Exception('Payment stored offline. Will sync when online.');
      }
      rethrow;
    }
  }

  Future<List<OrderModel>> list({String? status, String? paymentStatus, int? limit, int? offset}) async {
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (paymentStatus != null) params.add('payment_status=$paymentStatus');
    if (limit != null) params.add('limit=$limit');
    if (offset != null) params.add('offset=$offset');
    final q = params.isEmpty ? '' : '?${params.join('&')}';

    try {
      final res = await _api.get('/sales$q');
      final list = res['data']?['orders'] as List? ?? [];
      return list.map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      if (_isOfflineError(e)) {
        return []; // Return empty if offline and not cached locally
      }
      rethrow;
    }
  }

  Future<List<OrderModel>> listPending() async {
    return list(paymentStatus: 'pending');
  }

  Future<List<OrderModel>> listPartial() async {
    return list(paymentStatus: 'partial');
  }

  Future<OrderModel> updateStatus(int orderId, String status) async {
    try {
      final res = await _api.patch('/sales/$orderId/status', body: {'status': status});
      return OrderModel.fromJson(Map<String, dynamic>.from(res['data']?['order'] as Map? ?? {}));
    } catch (e) {
      if (_isOfflineError(e) && _database != null) {
        await _queueSync('order', {'status': status}, operation: 'update_status', localId: orderId.toString());
        throw Exception('Status update stored offline. Will sync when online.');
      }
      rethrow;
    }
  }

  Future<OrderModel> getOrder(int orderId) async {
    final res = await _api.get('/sales/$orderId');
    return OrderModel.fromJson(Map<String, dynamic>.from(res['data']?['order'] as Map? ?? {}));
  }

  // --- Helper Methods for Offline Resilience ---

  bool _isOfflineError(Object error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
             error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.receiveTimeout;
    }
    return false;
  }

  Future<void> _queueSync(String entityType, Map<String, dynamic> payload, {required String operation, required String localId}) async {
    final database = _database;
    if (database == null) return;
    await database.db.insert('sync_queue', {
      'id': const Uuid().v4(),
      'entity_type': entityType,
      'entity_local_id': localId,
      'operation': operation,
      'payload': jsonEncode(payload),
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  double _calculateTotal(List<Map<String, dynamic>> lines) {
    double total = 0;
    for (var line in lines) {
      final qty = (line['quantity'] as num?)?.toInt() ?? 1;
      final rate = (line['rate'] as num?)?.toDouble() ?? 0.0;
      total += (qty * rate);
    }
    return total;
  }
}
