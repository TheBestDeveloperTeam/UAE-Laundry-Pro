import 'order_item_model.dart';
import 'package:laundrypro_uae/core/safe_parser.dart';

class OrderModel {
  const OrderModel({
    required this.id,
    required this.uuid,
    required this.orderNumber,
    this.customerId,
    required this.status,
    required this.totalAmount,
    this.items = const [],
    required this.createdAt,
    this.completedAt,
  });

  final int id;
  final String uuid;
  final String orderNumber;
  final int? customerId;
  final String status; // e.g., 'pending', 'processing', 'ready', 'completed', 'cancelled'
  final double totalAmount;
  final List<OrderItemModel> items;
  final DateTime createdAt;
  final DateTime? completedAt;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: SafeParser.parseInt(json['id']),
      uuid: json['uuid'] as String,
      orderNumber: json['order_number'] as String,
      customerId: SafeParser.parseInt(json['customer_id']) == 0 ? null : SafeParser.parseInt(json['customer_id']),
      status: json['status'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: SafeParser.parseDateTime(json['created_at']),
      completedAt: json['completed_at'] != null 
          ? SafeParser.parseDateTime(json['completed_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'order_number': orderNumber,
      'customer_id': customerId,
      'status': status,
      'total_amount': totalAmount,
      'items': items.map((item) => item.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
    };
  }

  OrderModel copyWith({
    int? id,
    String? uuid,
    String? orderNumber,
    int? customerId,
    String? status,
    double? totalAmount,
    List<OrderItemModel>? items,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
