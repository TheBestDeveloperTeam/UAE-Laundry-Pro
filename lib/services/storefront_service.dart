import 'package:laundrypro_uae/services/api_client.dart';

class StorefrontService {
  StorefrontService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  Future<Map<String, dynamic>> catalog() async {
    final res = await _api.get('/storefront/catalog');
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }

  Future<List<Map<String, dynamic>>> listOrders({String? status}) async {
    final path = status != null ? '/storefront/orders?status=$status' : '/storefront/orders';
    final res = await _api.get(path);
    return List<Map<String, dynamic>>.from(res['data']?['orders'] as List? ?? []);
  }

  Future<Map<String, dynamic>> convert(int orderId) async {
    final res = await _api.post('/storefront/orders/$orderId/convert');
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }
}
