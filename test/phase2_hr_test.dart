import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/models/attendance_model.dart';
import 'package:laundrypro_uae/models/employee_model.dart';
import 'package:laundrypro_uae/models/leave_model.dart';
import 'package:laundrypro_uae/services/attendance_service.dart';
import 'package:laundrypro_uae/services/employee_service.dart';
import 'package:laundrypro_uae/services/payroll_service.dart';

class FakeEmployeeService extends EmployeeService {
  final List<EmployeeModel> _data = [
    EmployeeModel.fromJson({
      'id': 1,
      'uuid': 'EMP-1',
      'user_id': 1,
      'employee_id': 'EMP-001',
      'department': 'Operations',
      'position': 'Washer',
      'base_salary': 3000.0,
      'join_date': '2026-01-01',
      'status': 'active',
      'created_at': '2026-01-01',
    })
  ];

  @override
  Future<List<EmployeeModel>> list({String? query}) async {
    return _data;
  }

  @override
  Future<EmployeeModel> create(Map<String, dynamic> body) async {
    final newItem = EmployeeModel.fromJson({
      'id': 2,
      'uuid': 'EMP-2',
      'user_id': 2,
      'employee_id': 'EMP-002',
      'department': 'Operations',
      'position': 'Staff',
      'base_salary': 3000.0,
      'join_date': '2026-01-01',
      'status': 'active',
      'created_at': '2026-01-01',
      ...body,
    });
    _data.add(newItem);
    return newItem;
  }
}

class FakeAttendanceService extends AttendanceService {
  final List<AttendanceModel> _data = [
    AttendanceModel.fromJson({
      'id': 1,
      'uuid': 'ATT-1',
      'employee_id': 1,
      'date': '2026-09-09',
      'status': 'present',
      'created_at': '2026-09-09',
    })
  ];

  @override
  Future<List<AttendanceModel>> list({int? employeeId, String? from, String? to}) async {
    return _data;
  }

  @override
  Future<AttendanceModel> record(Map<String, dynamic> body) async {
    final newItem = AttendanceModel.fromJson({
      'id': 2,
      'uuid': 'ATT-2',
      'employee_id': body['employee_id'] ?? 2,
      'date': '2026-09-09',
      'status': body['status'] ?? 'present',
      'created_at': '2026-09-09',
      ...body,
    });
    _data.add(newItem);
    return newItem;
  }
}

class FakePayrollService extends PayrollService {
  final List<LeaveModel> _leaves = [
    LeaveModel.fromJson({
      'id': 1,
      'employee_id': 1,
      'leave_type': 'Annual',
      'start_date': '2026-10-01',
      'end_date': '2026-10-15',
      'status': 'pending',
      'created_at': '2026-09-01',
    })
  ];

  @override
  Future<List<LeaveModel>> listLeave({String? status}) async {
    return _leaves;
  }
  
  @override
  Future<LeaveModel> createLeave(Map<String, dynamic> body) async {
    final newItem = LeaveModel.fromJson({
      'id': 2,
      'employee_id': body['employee_id'] ?? 1,
      'leave_type': 'Annual',
      'start_date': '2026-10-01',
      'end_date': '2026-10-15',
      'status': 'pending',
      'created_at': '2026-09-01',
      ...body,
    });
    _leaves.add(newItem);
    return newItem;
  }

  @override
  Future<LeaveModel> approveLeave(int id) async {
    final index = _leaves.indexWhere((element) => element.id == id);
    if (index >= 0) {
      final updated = LeaveModel.fromJson({
        ..._leaves[index].toJson(),
        'status': 'approved',
      });
      _leaves[index] = updated;
      return updated;
    }
    return _leaves.first;
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
