import 'package:laundrypro_uae/services/api_client.dart';
import 'package:laundrypro_uae/models/order_model.dart';
import 'package:laundrypro_uae/models/service_model.dart';

class SalesService {
  SalesService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<ServiceModel>> loadServices() async {
    final res = await _api.get('/services');
    final list = res['data']?['services'] as List? ?? [];
    return list.map((e) => ServiceModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<Map<String, dynamic>> getBusiness() async {
    final res = await _api.get('/business');
    return Map<String, dynamic>.from(res['data']?['business'] as Map? ?? {});
  }

  Future<OrderModel> createDraft({
    int? customerId,
    required List<Map<String, dynamic>> lines,
  }) async {
    final res = await _api.post('/sales/draft', body: {
      if (customerId != null) 'customer_id': customerId,
      'lines': lines,
    });
    return OrderModel.fromJson(Map<String, dynamic>.from(res['data']?['order'] as Map? ?? {}));
  }

  Future<OrderModel> confirm(int orderId) async {
    final res = await _api.post('/sales/$orderId/confirm');
    return OrderModel.fromJson(Map<String, dynamic>.from(res['data']?['order'] as Map? ?? {}));
  }

  Future<OrderModel> postPayment(
    int orderId, {
    required double amount,
    String method = 'cash',
    String? referenceNumber,
  }) async {
    final res = await _api.post('/sales/$orderId/payment', body: {
      'amount': amount,
      'payment_method': method,
      if (referenceNumber != null && referenceNumber.isNotEmpty)
        'reference_number': referenceNumber,
    });
    return OrderModel.fromJson(Map<String, dynamic>.from(res['data']?['order'] as Map? ?? {}));
  }

  Future<List<OrderModel>> list({String? status, String? paymentStatus, int? limit, int? offset}) async {
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (paymentStatus != null) params.add('payment_status=$paymentStatus');
    if (limit != null) params.add('limit=$limit');
    if (offset != null) params.add('offset=$offset');
    final q = params.isEmpty ? '' : '?${params.join('&')}';
    final res = await _api.get('/sales$q');
    final list = res['data']?['orders'] as List? ?? [];
    return list.map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<OrderModel>> listPending() async {
    final res = await _api.get('/sales?payment_status=pending');
    final list = res['data']?['orders'] as List? ?? [];
    return list.map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<OrderModel>> listPartial() async {
    final res = await _api.get('/sales?payment_status=partial');
    final list = res['data']?['orders'] as List? ?? [];
    return list.map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<OrderModel> updateStatus(int orderId, String status) async {
    final res = await _api.patch('/sales/$orderId/status', body: {'status': status});
    return OrderModel.fromJson(Map<String, dynamic>.from(res['data']?['order'] as Map? ?? {}));
  }

  Future<OrderModel> getOrder(int orderId) async {
    final res = await _api.get('/sales/$orderId');
    return OrderModel.fromJson(Map<String, dynamic>.from(res['data']?['order'] as Map? ?? {}));
  }
}
