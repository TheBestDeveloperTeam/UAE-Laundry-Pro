import 'package:laundrypro_uae/core/safe_parser.dart';

class LeaveModel {
  const LeaveModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeNo,
    required this.leaveType,
    this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.reason,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
  });

  final int id;
  final int employeeId;
  final String? employeeName;
  final String? employeeNo;
  final String leaveType;
  final int? leaveTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String? reason;
  final int? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;

  int get durationDays {
    return endDate.difference(startDate).inDays + 1;
  }

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      id: SafeParser.parseInt(json['id']),
      employeeId: SafeParser.parseInt(json['employee_id']),
      employeeName: (json['employee_name'] ?? json['full_name']) as String?,
      employeeNo: (json['employee_no'] ?? json['employee_code']) as String?,
      leaveType: (json['leave_type_name'] ?? json['leave_type'] ?? 'Annual Leave') as String,
      leaveTypeId: json['leave_type_id'] != null ? SafeParser.parseInt(json['leave_type_id']) : null,
      startDate: SafeParser.parseDateTime(json['start_date']),
      endDate: SafeParser.parseDateTime(json['end_date']),
      status: (json['status'] ?? 'pending') as String,
      reason: json['reason'] as String?,
      approvedBy: json['approved_by'] != null ? SafeParser.parseInt(json['approved_by']) : null,
      approvedAt: json['approved_at'] != null ? SafeParser.parseDateTime(json['approved_at']) : null,
      createdAt: SafeParser.parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      if (employeeName != null) 'employee_name': employeeName,
      if (employeeNo != null) 'employee_no': employeeNo,
      'leave_type': leaveType,
      'leave_type_name': leaveType,
      if (leaveTypeId != null) 'leave_type_id': leaveTypeId,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'status': status,
      if (reason != null) 'reason': reason,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (approvedAt != null) 'approved_at': approvedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  dynamic operator [](String key) => toJson()[key];
}
