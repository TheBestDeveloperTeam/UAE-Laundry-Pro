import 'package:laundrypro_uae/core/safe_parser.dart';

class LeaveModel {
  const LeaveModel({
    required this.id,
    required this.employeeId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.reason,
    required this.createdAt,
  });

  final int id;
  final int employeeId;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String? reason;
  final DateTime createdAt;

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      id: SafeParser.parseInt(json['id']),
      employeeId: SafeParser.parseInt(json['employee_id']),
      leaveType: json['leave_type'] as String? ?? 'Annual',
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_date']?.toString() ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'pending',
      reason: json['reason'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'leave_type': leaveType,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'status': status,
      if (reason != null) 'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  dynamic operator [](String key) => toJson()[key];
}
