import 'package:laundrypro_uae/services/api_client.dart';

class CustomerService {
  CustomerService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list({String? query}) async {
    final path = query != null && query.isNotEmpty ? '/customers?q=$query' : '/customers';
    final res = await _api.get(path);
    return (res['data']?['customers'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final res = await _api.post('/customers', body: body);
    return Map<String, dynamic>.from(res['data']?['customer'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) async {
    final res = await _api.put('/customers/$id', body: body);
    return Map<String, dynamic>.from(res['data']?['customer'] as Map? ?? {});
  }
}
