import 'package:laundrypro_uae/core/safe_parser.dart';

class PayrollLineModel {
  const PayrollLineModel({
    required this.id,
    required this.payrollRunId,
    required this.employeeId,
    this.employeeName,
    this.employeeNo,
    required this.baseSalary,
    this.overtimePay = 0.0,
    this.allowances = 0.0,
    this.advanceDeduction = 0.0,
    this.otherDeductions = 0.0,
    required this.netPay,
  });

  final int id;
  final int payrollRunId;
  final int employeeId;
  final String? employeeName;
  final String? employeeNo;
  final double baseSalary;
  final double overtimePay;
  final double allowances;
  final double advanceDeduction;
  final double otherDeductions;
  final double netPay;

  double get totalDeductions => advanceDeduction + otherDeductions;
  double get grossPay => baseSalary + overtimePay + allowances;

  factory PayrollLineModel.fromJson(Map<String, dynamic> json) {
    return PayrollLineModel(
      id: SafeParser.parseInt(json['id']),
      payrollRunId: SafeParser.parseInt(json['payroll_run_id']),
      employeeId: SafeParser.parseInt(json['employee_id']),
      employeeName: json['employee_name'] as String?,
      employeeNo: json['employee_no'] as String?,
      baseSalary: json['base_salary'] != null ? (json['base_salary'] as num).toDouble() : 0.0,
      overtimePay: json['overtime_pay'] != null ? (json['overtime_pay'] as num).toDouble() : 0.0,
      allowances: json['allowances'] != null ? (json['allowances'] as num).toDouble() : 0.0,
      advanceDeduction: json['advance_deduction'] != null ? (json['advance_deduction'] as num).toDouble() : (json['deductions'] != null ? (json['deductions'] as num).toDouble() : 0.0),
      otherDeductions: json['other_deductions'] != null ? (json['other_deductions'] as num).toDouble() : 0.0,
      netPay: json['net_pay'] != null ? (json['net_pay'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payroll_run_id': payrollRunId,
      'employee_id': employeeId,
      if (employeeName != null) 'employee_name': employeeName,
      if (employeeNo != null) 'employee_no': employeeNo,
      'base_salary': baseSalary,
      'overtime_pay': overtimePay,
      'allowances': allowances,
      'advance_deduction': advanceDeduction,
      'other_deductions': otherDeductions,
      'net_pay': netPay,
    };
  }

  dynamic operator [](String key) => toJson()[key];
}

class PayrollRunModel {
  const PayrollRunModel({
    required this.id,
    required this.uuid,
    required this.payrollPeriodId,
    required this.runNo,
    required this.periodStart,
    required this.periodEnd,
    required this.totalAmount,
    required this.status, // 'draft', 'posted', 'closed'
    this.lines = const [],
    this.createdAt,
  });

  final int id;
  final String uuid;
  final int payrollPeriodId;
  final String runNo;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalAmount;
  final String status;
  final List<PayrollLineModel> lines;
  final DateTime? createdAt;

  factory PayrollRunModel.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List? ?? [];
    return PayrollRunModel(
      id: SafeParser.parseInt(json['id']),
      uuid: (json['uuid'] ?? '') as String,
      payrollPeriodId: SafeParser.parseInt(json['payroll_period_id']),
      runNo: (json['run_no'] ?? 'PR-${json['id']}') as String,
      periodStart: json['period_start'] != null ? SafeParser.parseDateTime(json['period_start']) : DateTime.now(),
      periodEnd: json['period_end'] != null ? SafeParser.parseDateTime(json['period_end']) : DateTime.now(),
      totalAmount: json['total_amount'] != null ? (json['total_amount'] as num).toDouble() : 0.0,
      status: (json['status'] ?? 'draft') as String,
      lines: rawLines.map((e) => PayrollLineModel.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      createdAt: json['created_at'] != null ? SafeParser.parseDateTime(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'payroll_period_id': payrollPeriodId,
      'run_no': runNo,
      'period_start': periodStart.toIso8601String().split('T').first,
      'period_end': periodEnd.toIso8601String().split('T').first,
      'total_amount': totalAmount,
      'status': status,
      'lines': lines.map((l) => l.toJson()).toList(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  dynamic operator [](String key) => toJson()[key];
}

class PayrollModel {
  const PayrollModel({
    required this.id,
    required this.uuid,
    this.employeeId = 0,
    required this.periodStart,
    required this.periodEnd,
    this.baseSalary = 0.0,
    this.overtimePay = 0.0,
    this.deductions = 0.0,
    this.allowances = 0.0,
    this.netPay = 0.0,
    required this.status, // 'open', 'processing', 'closed', 'draft'
    this.createdAt,
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
  final DateTime? createdAt;

  factory PayrollModel.fromJson(Map<String, dynamic> json) {
    return PayrollModel(
      id: SafeParser.parseInt(json['id']),
      uuid: (json['uuid'] ?? '') as String,
      employeeId: json['employee_id'] != null ? SafeParser.parseInt(json['employee_id']) : 0,
      periodStart: SafeParser.parseDateTime(json['period_start']),
      periodEnd: SafeParser.parseDateTime(json['period_end']),
      baseSalary: json['base_salary'] != null ? (json['base_salary'] as num).toDouble() : 0.0,
      overtimePay: json['overtime_pay'] != null ? (json['overtime_pay'] as num).toDouble() : 0.0,
      deductions: json['deductions'] != null ? (json['deductions'] as num).toDouble() : 0.0,
      allowances: json['allowances'] != null ? (json['allowances'] as num).toDouble() : 0.0,
      netPay: json['net_pay'] != null ? (json['net_pay'] as num).toDouble() : 0.0,
      status: (json['status'] ?? 'open') as String,
      createdAt: json['created_at'] != null ? SafeParser.parseDateTime(json['created_at']) : null,
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
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  dynamic operator [](String key) => toJson()[key];

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
