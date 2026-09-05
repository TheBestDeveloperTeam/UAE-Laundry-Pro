import 'package:laundrypro_uae/services/api_client.dart';

class AnalyticsService {
  AnalyticsService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  Future<Map<String, dynamic>> summary({int? branchId}) async {
    final path = branchId != null ? '/analytics/summary?branch_id=$branchId' : '/analytics/summary';
    final res = await _api.get(path);
    return Map<String, dynamic>.from(res['data']?['summary'] as Map? ?? {});
  }

  Future<List<Map<String, dynamic>>> trends({
    required String metric,
    required String from,
    required String to,
    int? branchId,
  }) async {
    var path = '/analytics/trends?metric=$metric&from=$from&to=$to';
    if (branchId != null) path += '&branch_id=$branchId';
    final res = await _api.get(path);
    return List<Map<String, dynamic>>.from(res['data']?['series'] as List? ?? []);
  }

  Future<void> refresh() async {
    await _api.post('/analytics/refresh');
  }
}
