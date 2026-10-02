import 'package:laundrypro_uae/core/safe_parser.dart';

class SalaryAdvanceModel {
  const SalaryAdvanceModel({
    required this.id,
    this.uuid,
    required this.employeeId,
    this.employeeName,
    this.employeeNo,
    required this.amount,
    this.balanceRemaining,
    required this.requestDate,
    required this.status, // 'open', 'recovered', 'pending', 'rejected'
    this.reason,
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  final int id;
  final String? uuid;
  final int employeeId;
  final String? employeeName;
  final String? employeeNo;
  final double amount;
  final double? balanceRemaining;
  final DateTime requestDate;
  final String status;
  final String? reason;
  final String? notes;
  final int? createdBy;
  final DateTime? createdAt;

  double get currentBalance => balanceRemaining ?? amount;

  factory SalaryAdvanceModel.fromJson(Map<String, dynamic> json) {
    return SalaryAdvanceModel(
      id: SafeParser.parseInt(json['id']),
      uuid: json['uuid'] as String?,
      employeeId: SafeParser.parseInt(json['employee_id']),
      employeeName: (json['employee_name'] ?? json['full_name']) as String?,
      employeeNo: (json['employee_no'] ?? json['employee_code']) as String?,
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : 0.0,
      balanceRemaining: json['balance_remaining'] != null
          ? (json['balance_remaining'] as num).toDouble()
          : (json['amount'] != null ? (json['amount'] as num).toDouble() : 0.0),
      requestDate: json['request_date'] != null
          ? SafeParser.parseDateTime(json['request_date'])
          : (json['created_at'] != null ? SafeParser.parseDateTime(json['created_at']) : DateTime.now()),
      status: (json['status'] ?? 'open') as String,
      reason: (json['reason'] ?? json['notes']) as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] != null ? SafeParser.parseInt(json['created_by']) : null,
      createdAt: json['created_at'] != null ? SafeParser.parseDateTime(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (uuid != null) 'uuid': uuid,
      'employee_id': employeeId,
      if (employeeName != null) 'employee_name': employeeName,
      if (employeeNo != null) 'employee_no': employeeNo,
      'amount': amount,
      if (balanceRemaining != null) 'balance_remaining': balanceRemaining,
      'request_date': requestDate.toIso8601String().split('T').first,
      'status': status,
      if (reason != null) 'reason': reason,
      if (notes != null) 'notes': notes,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  dynamic operator [](String key) => toJson()[key];
}
