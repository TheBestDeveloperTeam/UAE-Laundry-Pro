import 'package:laundrypro_uae/core/safe_parser.dart';

class BranchModel {
  const BranchModel({
    required this.id,
    required this.uuid,
    required this.name,
    required this.location,
    this.contactNumber,
    this.operatingHours = '08:00 - 22:00',
    this.managerName,
    this.emirate = 'Dubai',
    required this.isActive,
    required this.createdAt,
  });

  final int id;
  final String uuid;
  final String name;
  final String location;
  final String? contactNumber;
  final String operatingHours;
  final String? managerName;
  final String emirate;
  final bool isActive;
  final DateTime createdAt;

  String get code => uuid;

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: SafeParser.parseInt(json['id']),
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      contactNumber: json['contact_number'] as String?,
      operatingHours: json['operating_hours'] as String? ?? '08:00 - 22:00',
      managerName: json['manager_name'] as String?,
      emirate: json['emirate'] as String? ?? 'Dubai',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: SafeParser.parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'location': location,
      if (contactNumber != null) 'contact_number': contactNumber,
      'operating_hours': operatingHours,
      if (managerName != null) 'manager_name': managerName,
      'emirate': emirate,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  dynamic operator [](String key) => key == 'code' ? uuid : toJson()[key];

  BranchModel copyWith({
    int? id,
    String? uuid,
    String? name,
    String? location,
    String? contactNumber,
    String? operatingHours,
    String? managerName,
    String? emirate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return BranchModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      location: location ?? this.location,
      contactNumber: contactNumber ?? this.contactNumber,
      operatingHours: operatingHours ?? this.operatingHours,
      managerName: managerName ?? this.managerName,
      emirate: emirate ?? this.emirate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
