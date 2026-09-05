import 'package:laundrypro_uae/services/api_client.dart';

class SalesService {
  SalesService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> loadServices() async {
    final res = await _api.get('/services');
    final list = res['data']?['services'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getBusiness() async {
    final res = await _api.get('/business');
    return Map<String, dynamic>.from(res['data']?['business'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> createDraft({
    int? customerId,
    required List<Map<String, dynamic>> lines,
  }) async {
    final res = await _api.post('/sales/draft', body: {
      if (customerId != null) 'customer_id': customerId,
      'lines': lines,
    });
    return Map<String, dynamic>.from(res['data']?['order'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> confirm(int orderId) async {
    final res = await _api.post('/sales/$orderId/confirm');
    return Map<String, dynamic>.from(res['data']?['order'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> postPayment(
    int orderId, {
    required double amount,
    String method = 'cash',
  }) async {
    final res = await _api.post('/sales/$orderId/payment', body: {
      'amount': amount,
      'payment_method': method,
    });
    return Map<String, dynamic>.from(res['data']?['order'] as Map? ?? {});
  }

  Future<List<Map<String, dynamic>>> list({String? status, String? paymentStatus}) async {
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (paymentStatus != null) params.add('payment_status=$paymentStatus');
    final q = params.isEmpty ? '' : '?${params.join('&')}';
    final res = await _api.get('/sales$q');
    final list = res['data']?['orders'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> listPending() async {
    final res = await _api.get('/sales?payment_status=pending');
    final list = res['data']?['orders'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> listPartial() async {
    final res = await _api.get('/sales?payment_status=partial');
    final list = res['data']?['orders'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> updateStatus(int orderId, String status) async {
    final res = await _api.patch('/sales/$orderId/status', body: {'status': status});
    return Map<String, dynamic>.from(res['data']?['order'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> getOrder(int orderId) async {
    final res = await _api.get('/sales/$orderId');
    return Map<String, dynamic>.from(res['data']?['order'] as Map? ?? {});
  }
}
