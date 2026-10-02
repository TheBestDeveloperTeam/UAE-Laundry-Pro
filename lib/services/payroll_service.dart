import 'package:laundrypro_uae/services/api_client.dart';
import '../models/payroll_model.dart';
import '../models/leave_model.dart';
import '../models/salary_advance_model.dart';

class PayrollService {
  PayrollService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<PayrollModel>> listPeriods() async {
    final res = await _api.get('/payroll/periods');
    return (res['data']?['periods'] as List? ?? [])
        .map((e) => PayrollModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PayrollModel> createPeriod(Map<String, dynamic> body) async {
    final res = await _api.post('/payroll/periods', body: body);
    return PayrollModel.fromJson(res['data']?['period'] as Map<String, dynamic>? ?? {});
  }

  Future<PayrollModel> runPayroll(int periodId) async {
    final res = await _api.post('/payroll/periods/$periodId/run');
    return PayrollModel.fromJson(res['data']?['payroll_run'] as Map<String, dynamic>? ?? {});
  }

  Future<List<PayrollRunModel>> listPayrollRuns() async {
    final res = await _api.get('/payroll/runs');
    return (res['data']?['payroll_runs'] as List? ?? [])
        .map((e) => PayrollRunModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<PayrollRunModel?> showPayrollRun(int id) async {
    final res = await _api.get('/payroll/runs/$id');
    final data = res['data']?['payroll_run'];
    if (data == null) return null;
    return PayrollRunModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  String generateWpsSif(PayrollRunModel run, {String employerCode = '123456789', String employerBank = 'AE123456789012345678901'}) {
    final monthStr = '${run.periodStart.year}${run.periodStart.month.toString().padLeft(2, '0')}';
    final lines = <String>[];
    double totalSalary = 0.0;

    for (final line in run.lines) {
      final empId = line.employeeNo != null && line.employeeNo!.isNotEmpty
          ? line.employeeNo!.padLeft(14, '0')
          : line.employeeId.toString().padLeft(14, '0');
      final fixed = line.baseSalary.toStringAsFixed(2);
      final variable = line.overtimePay.toStringAsFixed(2);
      totalSalary += line.netPay;

      // EDR record (Employee Detail Record)
      lines.add('EDR,$empId,000000000,AE000000000000000000000,        ,        ,0000,$fixed,$variable,0');
    }

    final totalStr = totalSalary.toStringAsFixed(2);
    final count = run.lines.length;
    final now = DateTime.now();
    final fileDate = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final fileTime = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    // SCR header record (Salary Control Record)
    final scr = 'SCR,$employerCode,$employerBank,$fileDate,$fileTime,$monthStr,$count,$totalStr,AED,SAL';
    lines.insert(0, scr);

    return lines.join('\r\n');
  }


  Future<List<LeaveModel>> listLeave({String? status}) async {
    final path = status != null ? '/leave-requests?status=$status' : '/leave-requests';
    final res = await _api.get(path);
    return (res['data']?['leave_requests'] as List? ?? [])
        .map((e) => LeaveModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> listLeaveTypes() async {
    final res = await _api.get('/leave-types');
    return (res['data']?['leave_types'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<LeaveModel> createLeave(Map<String, dynamic> body) async {
    final res = await _api.post('/leave-requests', body: body);
    return LeaveModel.fromJson(res['data']?['leave_request'] as Map<String, dynamic>? ?? {});
  }

  Future<LeaveModel> approveLeave(int id) async {
    final res = await _api.post('/leave-requests/$id/approve');
    return LeaveModel.fromJson(res['data']?['leave_request'] as Map<String, dynamic>? ?? {});
  }

  Future<LeaveModel> rejectLeave(int id) async {
    final res = await _api.post('/leave-requests/$id/reject');
    return LeaveModel.fromJson(res['data']?['leave_request'] as Map<String, dynamic>? ?? {});
  }

  Future<List<SalaryAdvanceModel>> listSalaryAdvances({int? employeeId}) async {
    final path = employeeId != null ? '/salary-advances?employee_id=$employeeId' : '/salary-advances';
    final res = await _api.get(path);
    return (res['data']?['salary_advances'] as List? ?? [])
        .map((e) => SalaryAdvanceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SalaryAdvanceModel> createSalaryAdvance(Map<String, dynamic> body) async {
    final res = await _api.post('/salary-advances', body: body);
    return SalaryAdvanceModel.fromJson(res['data']?['salary_advance'] as Map<String, dynamic>? ?? {});
  }
}
