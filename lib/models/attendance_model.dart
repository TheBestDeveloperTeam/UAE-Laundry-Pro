import 'package:laundrypro_uae/core/safe_parser.dart';

class AttendanceModel {
  const AttendanceModel({
    required this.id,
    required this.uuid,
    required this.employeeId,
    this.employeeName,
    this.employeeNo,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status, // 'present', 'absent', 'late', 'half_day', 'leave'
    this.notes,
    this.shiftType,
    this.createdAt,
  });

  final int id;
  final String uuid;
  final int employeeId;
  final String? employeeName;
  final String? employeeNo;
  final DateTime date;
  final String? checkIn;
  final String? checkOut;
  final String status;
  final String? notes;
  final String? shiftType;
  final DateTime? createdAt;

  // Compatibility getters
  DateTime? get checkInTime => checkIn != null && checkIn!.isNotEmpty
      ? DateTime.tryParse('${date.toIso8601String().split('T').first}T$checkIn')
      : null;

  DateTime? get checkOutTime => checkOut != null && checkOut!.isNotEmpty
      ? DateTime.tryParse('${date.toIso8601String().split('T').first}T$checkOut')
      : null;

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: SafeParser.parseInt(json['id']),
      uuid: (json['uuid'] ?? '') as String,
      employeeId: SafeParser.parseInt(json['employee_id']),
      employeeName: (json['employee_name'] ?? json['full_name']) as String?,
      employeeNo: (json['employee_no'] ?? json['employee_code']) as String?,
      date: json['attendance_date'] != null
          ? SafeParser.parseDateTime(json['attendance_date'])
          : (json['date'] != null ? SafeParser.parseDateTime(json['date']) : DateTime.now()),
      checkIn: json['check_in'] as String? ?? json['check_in_time']?.toString().split('T').last.split('.').first,
      checkOut: json['check_out'] as String? ?? json['check_out_time']?.toString().split('T').last.split('.').first,
      status: (json['status'] ?? 'present') as String,
      notes: json['notes'] as String?,
      shiftType: json['shift_type'] as String?,
      createdAt: json['created_at'] != null ? SafeParser.parseDateTime(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'employee_id': employeeId,
      if (employeeName != null) 'employee_name': employeeName,
      if (employeeNo != null) 'employee_no': employeeNo,
      'attendance_date': date.toIso8601String().split('T').first,
      'date': date.toIso8601String().split('T').first,
      if (checkIn != null) 'check_in': checkIn,
      if (checkOut != null) 'check_out': checkOut,
      'status': status,
      if (notes != null) 'notes': notes,
      if (shiftType != null) 'shift_type': shiftType,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  dynamic operator [](String key) => toJson()[key];

  AttendanceModel copyWith({
    int? id,
    String? uuid,
    int? employeeId,
    String? employeeName,
    String? employeeNo,
    DateTime? date,
    String? checkIn,
    String? checkOut,
    String? status,
    String? notes,
    String? shiftType,
    DateTime? createdAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeNo: employeeNo ?? this.employeeNo,
      date: date ?? this.date,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      shiftType: shiftType ?? this.shiftType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
