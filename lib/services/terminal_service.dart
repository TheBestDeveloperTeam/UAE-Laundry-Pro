import 'package:laundrypro_uae/services/api_client.dart';

class TerminalService {
  TerminalService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list({int? branchId}) async {
    final path = branchId != null ? '/terminals?branch_id=$branchId' : '/terminals';
    final res = await _api.get(path);
    return List<Map<String, dynamic>>.from(res['data']?['terminals'] as List? ?? []);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final res = await _api.post('/terminals', body: body);
    return Map<String, dynamic>.from(res['data']?['terminal'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> register(int id, Map<String, dynamic> body) async {
    final res = await _api.post('/terminals/$id/register', body: body);
    return Map<String, dynamic>.from(res['data']?['session'] as Map? ?? {});
  }
}
