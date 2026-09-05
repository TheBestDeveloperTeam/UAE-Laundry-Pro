import 'package:laundrypro_uae/services/api_client.dart';

class PayrollService {
  PayrollService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listPeriods() async {
    final res = await _api.get('/payroll/periods');
    return (res['data']?['periods'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createPeriod(Map<String, dynamic> body) async {
    final res = await _api.post('/payroll/periods', body: body);
    return Map<String, dynamic>.from(res['data']?['period'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> runPayroll(int periodId) async {
    final res = await _api.post('/payroll/periods/$periodId/run');
    return Map<String, dynamic>.from(res['data']?['payroll_run'] as Map? ?? {});
  }

  Future<List<Map<String, dynamic>>> listLeave({String? status}) async {
    final path = status != null ? '/leave-requests?status=$status' : '/leave-requests';
    final res = await _api.get(path);
    return (res['data']?['leave_requests'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> listLeaveTypes() async {
    final res = await _api.get('/leave-types');
    return (res['data']?['leave_types'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createLeave(Map<String, dynamic> body) async {
    final res = await _api.post('/leave-requests', body: body);
    return Map<String, dynamic>.from(res['data']?['leave_request'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> approveLeave(int id) async {
    final res = await _api.post('/leave-requests/$id/approve');
    return Map<String, dynamic>.from(res['data']?['leave_request'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> rejectLeave(int id) async {
    final res = await _api.post('/leave-requests/$id/reject');
    return Map<String, dynamic>.from(res['data']?['leave_request'] as Map? ?? {});
  }
}
