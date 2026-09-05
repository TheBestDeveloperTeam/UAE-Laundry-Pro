import 'package:laundrypro_uae/services/api_client.dart';

class ExpenseService {
  ExpenseService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listCategories() async {
    final res = await _api.get('/expense-categories');
    return (res['data']?['categories'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> list({String? status, String? from, String? to}) async {
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (from != null) params.add('from=$from');
    if (to != null) params.add('to=$to');
    final q = params.isEmpty ? '' : '?${params.join('&')}';
    final res = await _api.get('/expenses$q');
    return (res['data']?['expenses'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final res = await _api.post('/expenses', body: body);
    return Map<String, dynamic>.from(res['data']?['expense'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> approve(int id) async {
    final res = await _api.post('/expenses/$id/approve');
    return Map<String, dynamic>.from(res['data']?['expense'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> reject(int id) async {
    final res = await _api.post('/expenses/$id/reject');
    return Map<String, dynamic>.from(res['data']?['expense'] as Map? ?? {});
  }
}
