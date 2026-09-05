import 'package:laundrypro_uae/services/api_client.dart';

class DeliveryService {
  DeliveryService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list({String? status, int? salesOrderId}) async {
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (salesOrderId != null) params.add('sales_order_id=$salesOrderId');
    final q = params.isEmpty ? '' : '?${params.join('&')}';
    final res = await _api.get('/delivery-tasks$q');
    return (res['data']?['delivery_tasks'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) async {
    final res = await _api.patch('/delivery-tasks/$id', body: body);
    return Map<String, dynamic>.from(res['data']?['delivery_task'] as Map? ?? {});
  }
}
