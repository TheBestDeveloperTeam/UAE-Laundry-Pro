import 'package:laundrypro_uae/core/safe_parser.dart';

class SalaryAdvanceModel {
  const SalaryAdvanceModel({
    required this.id,
    required this.employeeId,
    required this.amount,
    required this.requestDate,
    required this.status,
    this.reason,
    required this.createdAt,
  });

  final int id;
  final int employeeId;
  final double amount;
  final DateTime requestDate;
  final String status;
  final String? reason;
  final DateTime createdAt;

  factory SalaryAdvanceModel.fromJson(Map<String, dynamic> json) {
    return SalaryAdvanceModel(
      id: SafeParser.parseInt(json['id']),
      employeeId: SafeParser.parseInt(json['employee_id']),
      amount: (json['amount'] as num).toDouble(),
      requestDate: DateTime.tryParse(json['request_date']?.toString() ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'pending',
      reason: json['reason'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'amount': amount,
      'request_date': requestDate.toIso8601String().split('T').first,
      'status': status,
      if (reason != null) 'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
