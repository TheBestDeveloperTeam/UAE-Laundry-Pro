import 'package:laundrypro_uae/core/safe_parser.dart';

class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.uuid,
    required this.name,
    this.phone,
    this.email,
    this.trn,
    this.balance = 0.0,
    required this.createdAt,
  });

  final int id;
  final String uuid;
  final String name;
  final String? phone;
  final String? email;
  final String? trn;
  final double balance;
  final DateTime createdAt;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: SafeParser.parseInt(json['id']),
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      trn: json['trn'] as String?,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: SafeParser.parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'phone': phone,
      'email': email,
      'trn': trn,
      'balance': balance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CustomerModel copyWith({
    int? id,
    String? uuid,
    String? name,
    String? phone,
    String? email,
    String? trn,
    double? balance,
    DateTime? createdAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      trn: trn ?? this.trn,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
