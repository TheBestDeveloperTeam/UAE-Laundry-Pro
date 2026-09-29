import 'package:laundrypro_uae/core/safe_parser.dart';

class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.uuid,
    required this.categoryId,
    required this.name,
    required this.price,
    this.sku,
    required this.isActive,
    required this.createdAt,
  });

  final int id;
  final String uuid;
  final int categoryId;
  final String name;
  final double price;
  final String? sku;
  final bool isActive;
  final DateTime createdAt;

  double get baseRate => price;
  String? get code => sku;

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: SafeParser.parseInt(json['id']),
      uuid: json['uuid'] as String,
      categoryId: SafeParser.parseInt(json['category_id']),
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      sku: json['sku'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: SafeParser.parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'category_id': categoryId,
      'name': name,
      'price': price,
      if (sku != null) 'sku': sku,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ServiceModel copyWith({
    int? id,
    String? uuid,
    int? categoryId,
    String? name,
    double? price,
    String? sku,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      price: price ?? this.price,
      sku: sku ?? this.sku,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
