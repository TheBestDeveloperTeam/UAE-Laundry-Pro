import 'package:laundrypro_uae/services/api_client.dart';

class InventoryService {
  InventoryService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listMovements({int? productId}) async {
    final path = productId != null ? '/inventory/movements?product_id=$productId' : '/inventory/movements';
    final res = await _api.get(path);
    return (res['data']?['movements'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> receipt(Map<String, dynamic> body) async {
    final res = await _api.post('/inventory/receipt', body: body);
    return Map<String, dynamic>.from(res['data']?['movement'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> adjustment(Map<String, dynamic> body) async {
    final res = await _api.post('/inventory/adjustment', body: body);
    return Map<String, dynamic>.from(res['data']?['product'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> transfer(Map<String, dynamic> body) async {
    final res = await _api.post('/inventory/transfer', body: body);
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }
}
