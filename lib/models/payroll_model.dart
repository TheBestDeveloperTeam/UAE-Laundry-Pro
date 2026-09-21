class PayrollModel {
  const PayrollModel({
    required this.id,
    required this.uuid,
    required this.employeeId,
    required this.periodStart,
    required this.periodEnd,
    required this.baseSalary,
    this.overtimePay = 0.0,
    this.deductions = 0.0,
    this.allowances = 0.0,
    required this.netPay,
    required this.status, // 'draft', 'processed', 'paid'
    required this.createdAt,
  });

  final int id;
  final String uuid;
  final int employeeId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double baseSalary;
  final double overtimePay;
  final double deductions;
  final double allowances;
  final double netPay;
  final String status;
  final DateTime createdAt;

  factory PayrollModel.fromJson(Map<String, dynamic> json) {
    return PayrollModel(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      employeeId: json['employee_id'] as int,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      baseSalary: (json['base_salary'] as num).toDouble(),
      overtimePay: (json['overtime_pay'] as num?)?.toDouble() ?? 0.0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0.0,
      allowances: (json['allowances'] as num?)?.toDouble() ?? 0.0,
      netPay: (json['net_pay'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'employee_id': employeeId,
      'period_start': periodStart.toIso8601String().split('T').first,
      'period_end': periodEnd.toIso8601String().split('T').first,
      'base_salary': baseSalary,
      'overtime_pay': overtimePay,
      'deductions': deductions,
      'allowances': allowances,
      'net_pay': netPay,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PayrollModel copyWith({
    int? id,
    String? uuid,
    int? employeeId,
    DateTime? periodStart,
    DateTime? periodEnd,
    double? baseSalary,
    double? overtimePay,
    double? deductions,
    double? allowances,
    double? netPay,
    String? status,
    DateTime? createdAt,
  }) {
    return PayrollModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      employeeId: employeeId ?? this.employeeId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      baseSalary: baseSalary ?? this.baseSalary,
      overtimePay: overtimePay ?? this.overtimePay,
      deductions: deductions ?? this.deductions,
      allowances: allowances ?? this.allowances,
      netPay: netPay ?? this.netPay,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
