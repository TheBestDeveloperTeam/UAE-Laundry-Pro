import 'package:laundrypro_uae/services/api_client.dart';

class ReportsService {
  ReportsService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Map<String, dynamic> _unwrap(Map<String, dynamic> res, {String? nestedKey}) {
    final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
    if (nestedKey != null && data[nestedKey] is Map) {
      return Map<String, dynamic>.from(data[nestedKey] as Map);
    }
    if (data['summary'] is Map) {
      return Map<String, dynamic>.from(data['summary'] as Map);
    }
    return data;
  }

  Future<Map<String, dynamic>> salesSummary({String? from, String? to}) async {
    final now = DateTime.now().toUtc();
    final fromDate = from ?? now.subtract(const Duration(days: 30)).toIso8601String().split('T').first;
    final toDate = to ?? now.toIso8601String().split('T').first;
    final res = await _api.get('/reports/sales/summary?from=$fromDate&to=$toDate');
    final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
    final summary = Map<String, dynamic>.from(data['summary'] as Map? ?? {});
    return {...summary, 'from': data['from'], 'to': data['to']};
  }

  Future<Map<String, dynamic>> todaySalesSummary() async {
    final today = DateTime.now().toUtc().toIso8601String().split('T').first;
    return salesSummary(from: today, to: today);
  }

  Future<Map<String, dynamic>> expensesSummary({String? from, String? to}) async {
    final now = DateTime.now().toUtc();
    final fromDate = from ?? DateTime(now.year, now.month, 1).toIso8601String().split('T').first;
    final toDate = to ?? now.toIso8601String().split('T').first;
    final res = await _api.get('/reports/expenses/summary?from=$fromDate&to=$toDate');
    return _unwrap(res);
  }

  Future<Map<String, dynamic>> payrollSummary({String? from, String? to}) async {
    final now = DateTime.now().toUtc();
    final fromDate = from ?? DateTime(now.year, now.month, 1).toIso8601String().split('T').first;
    final toDate = to ?? now.toIso8601String().split('T').first;
    final res = await _api.get('/reports/payroll/summary?from=$fromDate&to=$toDate');
    return _unwrap(res);
  }

  Future<Map<String, dynamic>> inventoryValuation() async {
    final res = await _api.get('/reports/inventory/valuation');
    return _unwrap(res, nestedKey: 'valuation');
  }

  Future<Map<String, dynamic>> productionThroughput({String? from, String? to}) async {
    final now = DateTime.now().toUtc();
    final fromDate = from ?? DateTime(now.year, now.month, 1).toIso8601String().split('T').first;
    final toDate = to ?? now.toIso8601String().split('T').first;
    final res = await _api.get('/reports/production/throughput?from=$fromDate&to=$toDate');
    return _unwrap(res, nestedKey: 'throughput');
  }

  Future<Map<String, dynamic>> purchasingReport({String? from, String? to}) async {
    final fromDate = from ?? '';
    final toDate = to ?? '';
    final q = fromDate.isNotEmpty ? '?from=$fromDate&to=$toDate' : '';
    final res = await _api.get('/reports/purchasing$q');
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> deliveryReport({String? from, String? to}) async {
    final fromDate = from ?? '';
    final toDate = to ?? '';
    final q = fromDate.isNotEmpty ? '?from=$fromDate&to=$toDate' : '';
    final res = await _api.get('/reports/delivery$q');
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }
}
