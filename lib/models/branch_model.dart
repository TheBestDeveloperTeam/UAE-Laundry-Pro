class BranchModel {
  const BranchModel({
    required this.id,
    required this.uuid,
    required this.name,
    required this.location,
    this.contactNumber,
    required this.isActive,
    required this.createdAt,
  });

  final int id;
  final String uuid;
  final String name;
  final String location;
  final String? contactNumber;
  final bool isActive;
  final DateTime createdAt;

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      contactNumber: json['contact_number'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'location': location,
      if (contactNumber != null) 'contact_number': contactNumber,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  BranchModel copyWith({
    int? id,
    String? uuid,
    String? name,
    String? location,
    String? contactNumber,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return BranchModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      location: location ?? this.location,
      contactNumber: contactNumber ?? this.contactNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
