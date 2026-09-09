import 'package:laundrypro_uae/services/api_client.dart';

class LeaveService {
  LeaveService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _api.get('/leave-requests');
    return (res['data']?['leaves'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> listTypes() async {
    final res = await _api.get('/leave-types');
    return (res['data']?['types'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final res = await _api.post('/leave-requests', body: body);
    return Map<String, dynamic>.from(res['data']?['leave'] as Map? ?? {});
  }

  Future<void> approve(int id) async {
    await _api.post('/leave-requests/$id/approve');
  }

  Future<void> reject(int id) async {
    await _api.post('/leave-requests/$id/reject');
  }
}
