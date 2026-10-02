import 'package:laundrypro_uae/core/safe_parser.dart';

class EmployeeModel {
  const EmployeeModel({
    required this.id,
    required this.uuid,
    this.adminId,
    this.userId,
    required this.employeeNo,
    required this.fullName,
    this.phone,
    this.email,
    this.jobTitle,
    this.department,
    this.civilId,
    this.civilIdExpiry,
    this.passportNo,
    this.visaExpiry,
    this.pin,
    required this.baseSalary,
    this.joinDate,
    required this.isActive,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String uuid;
  final int? adminId;
  final int? userId;
  final String employeeNo;
  final String fullName;
  final String? phone;
  final String? email;
  final String? jobTitle;
  final String? department;
  final String? civilId;
  final DateTime? civilIdExpiry;
  final String? passportNo;
  final DateTime? visaExpiry;
  final String? pin;
  final double baseSalary;
  final DateTime? joinDate;
  final bool isActive;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Compatibility getter aliases
  String get employeeId => employeeNo;
  String get position => jobTitle ?? '';

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    final activeVal = json['is_active'];
    final bool active = activeVal == null
        ? (json['status'] == 'active' || json['status'] == null)
        : (activeVal == 1 || activeVal == true || activeVal.toString() == '1');

    return EmployeeModel(
      id: SafeParser.parseInt(json['id']),
      uuid: (json['uuid'] ?? '') as String,
      adminId: json['admin_id'] != null ? SafeParser.parseInt(json['admin_id']) : null,
      userId: json['user_id'] != null ? SafeParser.parseInt(json['user_id']) : null,
      employeeNo: (json['employee_no'] ?? json['employee_id'] ?? '') as String,
      fullName: (json['full_name'] ?? json['name'] ?? '') as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      jobTitle: (json['job_title'] ?? json['position']) as String?,
      department: json['department'] as String?,
      civilId: (json['civil_id'] ?? json['id_passport_number']) as String?,
      civilIdExpiry: json['civil_id_expiry'] != null
          ? SafeParser.parseDateTime(json['civil_id_expiry'])
          : null,
      passportNo: json['passport_no'] as String?,
      visaExpiry: json['visa_expiry'] != null
          ? SafeParser.parseDateTime(json['visa_expiry'])
          : null,
      pin: json['pin'] as String?,
      baseSalary: json['base_salary'] != null
          ? (json['base_salary'] as num).toDouble()
          : 0.0,
      joinDate: json['join_date'] != null
          ? SafeParser.parseDateTime(json['join_date'])
          : null,
      isActive: active,
      status: (json['status'] ?? (active ? 'active' : 'inactive')) as String,
      createdAt: json['created_at'] != null
          ? SafeParser.parseDateTime(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? SafeParser.parseDateTime(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      if (adminId != null) 'admin_id': adminId,
      if (userId != null) 'user_id': userId,
      'employee_no': employeeNo,
      'employee_id': employeeNo, // legacy alias
      'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (jobTitle != null) 'job_title': jobTitle,
      if (jobTitle != null) 'position': jobTitle, // legacy alias
      if (department != null) 'department': department,
      if (civilId != null) 'civil_id': civilId,
      if (civilIdExpiry != null)
        'civil_id_expiry': civilIdExpiry!.toIso8601String().split('T').first,
      if (passportNo != null) 'passport_no': passportNo,
      if (visaExpiry != null)
        'visa_expiry': visaExpiry!.toIso8601String().split('T').first,
      if (pin != null) 'pin': pin,
      'base_salary': baseSalary,
      if (joinDate != null)
        'join_date': joinDate!.toIso8601String().split('T').first,
      'is_active': isActive ? 1 : 0,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  dynamic operator [](String key) => toJson()[key];

  EmployeeModel copyWith({
    int? id,
    String? uuid,
    int? adminId,
    int? userId,
    String? employeeNo,
    String? fullName,
    String? phone,
    String? email,
    String? jobTitle,
    String? department,
    String? civilId,
    DateTime? civilIdExpiry,
    String? passportNo,
    DateTime? visaExpiry,
    String? pin,
    double? baseSalary,
    DateTime? joinDate,
    bool? isActive,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      adminId: adminId ?? this.adminId,
      userId: userId ?? this.userId,
      employeeNo: employeeNo ?? this.employeeNo,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      jobTitle: jobTitle ?? this.jobTitle,
      department: department ?? this.department,
      civilId: civilId ?? this.civilId,
      civilIdExpiry: civilIdExpiry ?? this.civilIdExpiry,
      passportNo: passportNo ?? this.passportNo,
      visaExpiry: visaExpiry ?? this.visaExpiry,
      pin: pin ?? this.pin,
      baseSalary: baseSalary ?? this.baseSalary,
      joinDate: joinDate ?? this.joinDate,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
