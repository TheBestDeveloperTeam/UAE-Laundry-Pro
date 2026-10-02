import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/models/attendance_model.dart';
import 'package:laundrypro_uae/models/employee_model.dart';
import 'package:laundrypro_uae/models/leave_model.dart';
import 'package:laundrypro_uae/models/payroll_model.dart';
import 'package:laundrypro_uae/models/salary_advance_model.dart';
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

    test('EmployeeModel handles UAE compliance fields and deactivation', () {
      final emp = EmployeeModel.fromJson({
        'id': 10,
        'uuid': 'EMP-UUID-10',
        'employee_no': 'EMP-00010',
        'full_name': 'Rashid Al Nuaimi',
        'civil_id': '784-1990-1234567-1',
        'civil_id_expiry': '2026-12-31',
        'passport_no': 'A1234567',
        'visa_expiry': '2027-05-15',
        'pin': '1234',
        'department': 'Logistics',
        'job_title': 'Driver',
        'base_salary': 4500.0,
        'is_active': 1,
      });

      expect(emp.employeeNo, 'EMP-00010');
      expect(emp.civilId, '784-1990-1234567-1');
      expect(emp.passportNo, 'A1234567');
      expect(emp.pin, '1234');
      expect(emp.isActive, isTrue);
      expect(emp.civilIdExpiry?.year, 2026);
      expect(emp.visaExpiry?.year, 2027);

      final json = emp.toJson();
      expect(json['civil_id'], '784-1990-1234567-1');
      expect(json['passport_no'], 'A1234567');
      expect(json['pin'], '1234');
      expect(json['is_active'], 1);
    });

    test('LeaveModel computes duration correctly', () {
      final leave = LeaveModel.fromJson({
        'id': 5,
        'employee_id': 1,
        'leave_type_name': 'Annual Leave',
        'start_date': '2026-11-01',
        'end_date': '2026-11-05',
        'status': 'pending',
      });

      expect(leave.leaveType, 'Annual Leave');
      expect(leave.durationDays, 5);
      expect(leave.status, 'pending');
    });

    test('PayrollRunModel parses lines and generates valid UAE WPS SIF structure', () {
      final run = PayrollRunModel.fromJson({
        'id': 1,
        'payroll_period_id': 1,
        'run_no': 'PR-000001',
        'period_start': '2026-10-01',
        'period_end': '2026-10-31',
        'total_amount': 5500.0,
        'status': 'posted',
        'lines': [
          {
            'id': 101,
            'payroll_run_id': 1,
            'employee_id': 10,
            'employee_no': 'EMP-00010',
            'employee_name': 'Rashid Al Nuaimi',
            'base_salary': 4500.0,
            'overtime_pay': 500.0,
            'advance_deduction': 500.0,
            'net_pay': 4500.0,
          },
          {
            'id': 102,
            'payroll_run_id': 1,
            'employee_id': 11,
            'employee_no': 'EMP-00011',
            'employee_name': 'Saeed Khan',
            'base_salary': 1000.0,
            'overtime_pay': 0.0,
            'advance_deduction': 0.0,
            'net_pay': 1000.0,
          }
        ]
      });

      expect(run.lines.length, 2);
      expect(run.lines.first.grossPay, 5000.0);
      expect(run.lines.first.totalDeductions, 500.0);

      final service = PayrollService();
      final sif = service.generateWpsSif(run, employerCode: '987654321', employerBank: 'AE998877665544332211001');

      expect(sif.contains('SCR,987654321,AE998877665544332211001'), isTrue);
      expect(sif.contains('AED,SAL'), isTrue);
      expect(sif.contains('EDR,'), isTrue);
      expect(sif.contains('4500.00'), isTrue);
    });

    test('SalaryAdvanceModel calculates current balance correctly', () {
      final adv = SalaryAdvanceModel.fromJson({
        'id': 1,
        'employee_id': 10,
        'employee_name': 'Rashid Al Nuaimi',
        'amount': 2000.0,
        'balance_remaining': 1500.0,
        'status': 'open',
        'request_date': '2026-10-01',
      });

      expect(adv.currentBalance, 1500.0);
      expect(adv.amount, 2000.0);
      expect(adv.status, 'open');
    });
  });
}


