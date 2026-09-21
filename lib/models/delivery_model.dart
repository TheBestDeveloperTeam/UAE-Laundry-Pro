import 'package:laundrypro_uae/core/safe_parser.dart';

class DeliveryModel {
  const DeliveryModel({
    required this.id,
    required this.uuid,
    required this.orderId,
    required this.driverId,
    required this.status, // 'pending', 'in_transit', 'delivered', 'failed'
    this.address,
    this.deliveryDate,
    required this.createdAt,
  });

  final int id;
  final String uuid;
  final int orderId;
  final int driverId;
  final String status;
  final String? address;
  final DateTime? deliveryDate;
  final DateTime createdAt;

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: SafeParser.parseInt(json['id']),
      uuid: json['uuid'] as String,
      orderId: SafeParser.parseInt(json['order_id']),
      driverId: SafeParser.parseInt(json['driver_id']),
      status: json['status'] as String,
      address: json['address'] as String?,
      deliveryDate: json['delivery_date'] != null 
          ? SafeParser.parseDateTime(json['delivery_date']) 
          : null,
      createdAt: SafeParser.parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'order_id': orderId,
      'driver_id': driverId,
      'status': status,
      if (address != null) 'address': address,
      if (deliveryDate != null) 'delivery_date': deliveryDate!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  DeliveryModel copyWith({
    int? id,
    String? uuid,
    int? orderId,
    int? driverId,
    String? status,
    String? address,
    DateTime? deliveryDate,
    DateTime? createdAt,
  }) {
    return DeliveryModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      orderId: orderId ?? this.orderId,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      address: address ?? this.address,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
