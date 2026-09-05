import 'package:laundrypro_uae/services/api_client.dart';

class BranchService {
  BranchService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _api.get('/branches');
    return List<Map<String, dynamic>>.from(res['data']?['branches'] as List? ?? []);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final res = await _api.post('/branches', body: body);
    return Map<String, dynamic>.from(res['data']?['branch'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) async {
    final res = await _api.put('/branches/$id', body: body);
    return Map<String, dynamic>.from(res['data']?['branch'] as Map? ?? {});
  }
}
