import 'package:laundrypro_uae/services/api_client.dart';

class AccountingService {
  AccountingService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listBatches() async {
    final res = await _api.get('/accounting/batches');
    return List<Map<String, dynamic>>.from(res['data']?['batches'] as List? ?? []);
  }

  Future<Map<String, dynamic>> export({
    required String periodStart,
    required String periodEnd,
    String adapter = 'csv',
  }) async {
    final res = await _api.post('/accounting/export', body: {
      'period_start': periodStart,
      'period_end': periodEnd,
      'adapter': adapter,
    });
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }
}
