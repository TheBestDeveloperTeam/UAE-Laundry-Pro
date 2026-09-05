import 'package:laundrypro_uae/services/api_client.dart';

class AttendanceService {
  AttendanceService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list({int? employeeId, String? from, String? to}) async {
    final params = <String>[];
    if (employeeId != null) params.add('employee_id=$employeeId');
    if (from != null) params.add('from=$from');
    if (to != null) params.add('to=$to');
    final q = params.isEmpty ? '' : '?${params.join('&')}';
    final res = await _api.get('/attendance$q');
    return (res['data']?['attendance'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> record(Map<String, dynamic> body) async {
    final res = await _api.post('/attendance', body: body);
    return Map<String, dynamic>.from(res['data']?['attendance'] as Map? ?? {});
  }
}
