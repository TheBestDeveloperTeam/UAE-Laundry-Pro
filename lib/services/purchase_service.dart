import 'package:laundrypro_uae/services/api_client.dart';

class PurchaseService {
  PurchaseService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list({String? status}) async {
    final path = status != null ? '/purchase-orders?status=$status' : '/purchase-orders';
    final res = await _api.get(path);
    return (res['data']?['purchase_orders'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final res = await _api.post('/purchase-orders', body: body);
    return Map<String, dynamic>.from(res['data']?['purchase_order'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> receive(int id, Map<String, dynamic> body) async {
    final res = await _api.post('/purchase-orders/$id/receive', body: body);
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }
}
