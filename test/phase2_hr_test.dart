import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/services/employee_service.dart';
import 'package:laundrypro_uae/services/attendance_service.dart';
import 'package:laundrypro_uae/services/payroll_service.dart';

class FakeEmployeeService extends EmployeeService {
  final List<Map<String, dynamic>> _data = [
    {'id': 1, 'full_name': 'Ali Khan', 'employee_code': 'EMP-001', 'phone': '0501234567'}
  ];

  @override
  Future<List<Map<String, dynamic>>> list({String? query}) async {
    return _data;
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final newItem = {'id': 2, ...body};
    _data.add(newItem);
    return newItem;
  }
}

class FakeAttendanceService extends AttendanceService {
  final List<Map<String, dynamic>> _data = [
    {'id': 1, 'employee_id': 1, 'attendance_date': '2026-09-09', 'status': 'present'}
  ];

  @override
  Future<List<Map<String, dynamic>>> list({int? employeeId, String? from, String? to}) async {
    return _data;
  }

  @override
  Future<Map<String, dynamic>> record(Map<String, dynamic> body) async {
    final newItem = {'id': 2, ...body};
    _data.add(newItem);
    return newItem;
  }
}

class FakePayrollService extends PayrollService {
  final List<Map<String, dynamic>> _leaves = [
    {'id': 1, 'employee_id': 1, 'start_date': '2026-10-01', 'end_date': '2026-10-15', 'status': 'pending'}
  ];

  @override
  Future<List<Map<String, dynamic>>> listLeave({String? status}) async {
    return _leaves;
  }
  
  @override
  Future<Map<String, dynamic>> createLeave(Map<String, dynamic> body) async {
    final newItem = {'id': 2, 'status': 'pending', ...body};
    _leaves.add(newItem);
    return newItem;
  }

  @override
  Future<Map<String, dynamic>> approveLeave(int id) async {
    final l = _leaves.firstWhere((element) => element['id'] == id);
    l['status'] = 'approved';
    return l;
  }
}

void main() {
  group('HR Module Tests', () {
    test('EmployeeService lists and creates employees', () async {
      final s = FakeEmployeeService();
      expect((await s.list()).length, 1);
      await s.create({'full_name': 'Omar'});
      expect((await s.list()).length, 2);
    });

    test('AttendanceService records attendance', () async {
      final s = FakeAttendanceService();
      expect((await s.list()).length, 1);
      await s.record({'employee_id': 2, 'status': 'absent'});
      expect((await s.list()).length, 2);
    });

    test('PayrollService handles leave requests', () async {
      final s = FakePayrollService();
      expect((await s.listLeave()).length, 1);
      await s.approveLeave(1);
      final list = await s.listLeave();
      expect(list.first['status'], 'approved');
    });
  });
}
