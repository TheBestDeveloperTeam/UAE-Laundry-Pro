import 'package:laundrypro_uae/core/safe_parser.dart';

class EmployeeModel {
  const EmployeeModel({
    required this.id,
    required this.uuid,
    required this.userId,
    required this.employeeId,
    required this.department,
    required this.position,
    required this.baseSalary,
    required this.joinDate,
    required this.status, // 'active', 'on_leave', 'terminated'
    required this.createdAt,
  });

  final int id;
  final String uuid;
  final int userId;
  final String employeeId;
  final String department;
  final String position;
  final double baseSalary;
  final DateTime joinDate;
  final String status;
  final DateTime createdAt;

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: SafeParser.parseInt(json['id']),
      uuid: json['uuid'] as String,
      userId: SafeParser.parseInt(json['user_id']),
      employeeId: json['employee_id'] as String,
      department: json['department'] as String,
      position: json['position'] as String,
      baseSalary: (json['base_salary'] as num).toDouble(),
      joinDate: SafeParser.parseDateTime(json['join_date']),
      status: json['status'] as String,
      createdAt: SafeParser.parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'user_id': userId,
      'employee_id': employeeId,
      'department': department,
      'position': position,
      'base_salary': baseSalary,
      'join_date': joinDate.toIso8601String().split('T').first,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  dynamic operator [](String key) => toJson()[key];

  EmployeeModel copyWith({
    int? id,
    String? uuid,
    int? userId,
    String? employeeId,
    String? department,
    String? position,
    double? baseSalary,
    DateTime? joinDate,
    String? status,
    DateTime? createdAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      userId: userId ?? this.userId,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      position: position ?? this.position,
      baseSalary: baseSalary ?? this.baseSalary,
      joinDate: joinDate ?? this.joinDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
