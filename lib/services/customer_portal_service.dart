import 'package:laundrypro_uae/services/api_client.dart';

class CustomerPortalService {
  CustomerPortalService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  Future<Map<String, dynamic>> createToken(int salesOrderId) async {
    final res = await _api.post('/portal/tokens', body: {'sales_order_id': salesOrderId});
    return Map<String, dynamic>.from(res['data']?['portal'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> orderStatus(String token) async {
    final res = await _api.get('/portal/order?token=$token');
    return Map<String, dynamic>.from(res['data']?['order'] as Map? ?? {});
  }
}
