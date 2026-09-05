import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/services/attendance_service.dart';
import 'package:laundrypro_uae/services/employee_service.dart';
import 'package:laundrypro_uae/services/payroll_service.dart';

class FakeEmployeeService extends EmployeeService {
  @override
  Future<List<Map<String, dynamic>>> list({String? query}) async => [
        {'id': 1, 'full_name': 'Ahmed Ali', 'phone': '0501234567'},
        {'id': 2, 'full_name': 'Sara Khan', 'employee_code': 'EMP-002'},
      ];
}

class FakeAttendanceService extends AttendanceService {
  @override
  Future<List<Map<String, dynamic>>> list({int? employeeId, String? from, String? to}) async => [
        {'employee_id': 1, 'attendance_date': '2026-09-01', 'status': 'present'},
      ];
}

class FakePayrollService extends PayrollService {
  @override
  Future<List<Map<String, dynamic>>> listPeriods() async => [
        {'id': 1, 'period_start': '2026-09-01', 'period_end': '2026-09-30', 'status': 'open'},
      ];

  @override
  Future<List<Map<String, dynamic>>> listLeave({String? status}) async => [
        {'id': 1, 'employee_id': 1, 'start_date': '2026-09-10', 'end_date': '2026-09-12', 'status': 'pending'},
      ];
}

void main() {
  group('FakeEmployeeService', () {
    test('returns two employees', () async {
      final items = await FakeEmployeeService().list();
      expect(items.length, 2);
      expect(items.first['full_name'], 'Ahmed Ali');
    });

    test('supports search query parameter', () async {
      final items = await FakeEmployeeService().list(query: 'Sara');
      expect(items.length, 2);
    });
  });

  group('FakeAttendanceService', () {
    test('returns attendance row', () async {
      final items = await FakeAttendanceService().list();
      expect(items.first['attendance_date'], '2026-09-01');
      expect(items.first['status'], 'present');
    });
  });

  group('FakePayrollService', () {
    test('returns open payroll period', () async {
      final periods = await FakePayrollService().listPeriods();
      expect(periods.first['status'], 'open');
    });

    test('returns pending leave request', () async {
      final leaves = await FakePayrollService().listLeave(status: 'pending');
      expect(leaves.first['status'], 'pending');
    });
  });
}
