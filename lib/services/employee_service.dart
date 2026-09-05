import 'package:laundrypro_uae/services/api_client.dart';

class EmployeeService {
  EmployeeService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list({String? query}) async {
    final path = query != null && query.isNotEmpty ? '/employees?q=$query' : '/employees';
    final res = await _api.get(path);
    return (res['data']?['employees'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final res = await _api.post('/employees', body: body);
    return Map<String, dynamic>.from(res['data']?['employee'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) async {
    final res = await _api.put('/employees/$id', body: body);
    return Map<String, dynamic>.from(res['data']?['employee'] as Map? ?? {});
  }
}
