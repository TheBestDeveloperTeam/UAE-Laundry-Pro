import 'dart:convert';
import 'package:laundrypro_uae/core/safe_parser.dart';

class OrderItemModel {
  const OrderItemModel({
    this.id,
    required this.orderId,
    required this.serviceId,
    required this.serviceName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
    this.modifiers,
  });

  final int? id;
  final int orderId;
  final int serviceId;
  final String serviceName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;
  final Map<String, dynamic>? modifiers;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: SafeParser.parseInt(json['id']) == 0 ? null : SafeParser.parseInt(json['id']),
      orderId: SafeParser.parseInt(json['order_id']),
      serviceId: SafeParser.parseInt(json['service_id']),
      serviceName: json['service_name'] as String,
      quantity: SafeParser.parseInt(json['quantity']),
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      notes: json['notes'] as String?,
      modifiers: json['modifiers'] != null 
          ? (json['modifiers'] is String ? jsonDecode(json['modifiers']) as Map<String, dynamic> : json['modifiers'] as Map<String, dynamic>) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'order_id': orderId,
      'service_id': serviceId,
      'service_name': serviceName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      if (notes != null) 'notes': notes,
      if (modifiers != null) 'modifiers': modifiers,
    };
  }

  OrderItemModel copyWith({
    int? id,
    int? orderId,
    int? serviceId,
    String? serviceName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? notes,
    Map<String, dynamic>? modifiers,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      modifiers: modifiers ?? this.modifiers,
    );
  }
}
