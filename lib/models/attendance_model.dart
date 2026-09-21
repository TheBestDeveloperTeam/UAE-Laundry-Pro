class AttendanceModel {
  const AttendanceModel({
    required this.id,
    required this.uuid,
    required this.employeeId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status, // 'present', 'absent', 'late', 'half_day'
    required this.createdAt,
  });

  final int id;
  final String uuid;
  final int employeeId;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String status;
  final DateTime createdAt;

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      employeeId: json['employee_id'] as int,
      date: DateTime.parse(json['date'] as String),
      checkInTime: json['check_in_time'] != null 
          ? DateTime.parse(json['check_in_time'] as String) 
          : null,
      checkOutTime: json['check_out_time'] != null 
          ? DateTime.parse(json['check_out_time'] as String) 
          : null,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'employee_id': employeeId,
      'date': date.toIso8601String().split('T').first,
      if (checkInTime != null) 'check_in_time': checkInTime!.toIso8601String(),
      if (checkOutTime != null) 'check_out_time': checkOutTime!.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AttendanceModel copyWith({
    int? id,
    String? uuid,
    int? employeeId,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? status,
    DateTime? createdAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
