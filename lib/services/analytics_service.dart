import 'package:laundrypro_uae/services/api_client.dart';
import '../models/dashboard_metrics_model.dart';
import '../models/report_config_model.dart';

class AnalyticsService {
  AnalyticsService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  Future<DashboardMetricsModel> summary({int? branchId}) async {
    final path = branchId != null ? '/analytics/summary?branch_id=$branchId' : '/analytics/summary';
    final res = await _api.get(path);
    return DashboardMetricsModel.fromJson(Map<String, dynamic>.from(res['data']?['summary'] as Map? ?? {}));
  }

  Future<List<Map<String, dynamic>>> trends(ReportConfigModel config) async {
    final metric = config.metric ?? 'sales_total';
    final from = config.fromDate ?? '';
    final to = config.toDate ?? '';
    var path = '/analytics/trends?metric=$metric&from=$from&to=$to';
    if (config.branchId != null) path += '&branch_id=${config.branchId}';
    final res = await _api.get(path);
    return List<Map<String, dynamic>>.from(res['data']?['series'] as List? ?? []);
  }

  Future<void> refresh() async {
    await _api.post('/analytics/refresh');
  }
}
