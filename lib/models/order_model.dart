import 'order_item_model.dart';
import 'package:laundrypro_uae/core/safe_parser.dart';

class OrderModel {
  const OrderModel({
    required this.id,
    this.localId,
    String? uuid,
    String? orderNumber,
    String? orderNo,
    this.customerId,
    this.customerName,
    required this.status,
    this.paymentStatus = 'pending',
    this.syncStatus = 'pending',
    double? totalAmount,
    double? grandTotal,
    this.subtotal,
    double? vatAmount,
    double? vatTotal,
    double? discountTotal,
    this.balanceDue,
    this.customerPhone,
    this.items = const [],
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.promisedDate,
  })  : uuid = uuid ?? orderNumber ?? orderNo ?? '',
        orderNumber = orderNumber ?? orderNo ?? '',
        totalAmount = totalAmount ?? grandTotal ?? 0.0,
        vatAmount = vatAmount ?? vatTotal;

  final int id;
  final int? localId;
  final String uuid;
  final String orderNumber;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final String status; // e.g., 'pending', 'processing', 'ready', 'completed', 'cancelled'
  final String paymentStatus; // 'pending', 'partial', 'paid'
  final String? syncStatus; // 'pending', 'synced', 'failed'
  final double totalAmount;
  final double? subtotal;
  final double? vatAmount;
  final double? balanceDue;
  final List<OrderItemModel> items;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final DateTime? promisedDate;

  // Compatibility getters
  String get orderNo => orderNumber;
  double get grandTotal => totalAmount;
  List<OrderItemModel> get lines => items;
  double get discount => 0.0;
  double get tax => vatAmount ?? 0.0;
  double? get amountPaid => null;
  String? get trn => null;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: SafeParser.parseInt(json['id']),
      localId: json['local_id'] != null ? SafeParser.parseInt(json['local_id']) : null,
      uuid: json['uuid'] as String? ?? '',
      orderNumber: (json['order_number'] ?? json['order_no'] ?? '') as String,
      customerId: SafeParser.parseInt(json['customer_id']) == 0 ? null : SafeParser.parseInt(json['customer_id']),
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      balanceDue: json['balance_due'] != null ? (json['balance_due'] as num).toDouble() : null,
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      syncStatus: json['sync_status'] as String?,
      totalAmount: (json['total_amount'] ?? json['grand_total'] ?? 0.0 as num).toDouble(),
      subtotal: json['subtotal'] != null ? (json['subtotal'] as num).toDouble() : null,
      vatAmount: json['vat_amount'] != null ? (json['vat_amount'] as num).toDouble() : null,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: SafeParser.parseDateTime(json['created_at']),
      updatedAt: json['updated_at'] != null ? SafeParser.parseDateTime(json['updated_at']) : null,
      completedAt: json['completed_at'] != null ? SafeParser.parseDateTime(json['completed_at']) : null,
      promisedDate: json['promised_date'] != null ? SafeParser.parseDateTime(json['promised_date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (localId != null) 'local_id': localId,
      'uuid': uuid,
      'order_number': orderNumber,
      'order_no': orderNumber,
      'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      'status': status,
      'payment_status': paymentStatus,
      if (syncStatus != null) 'sync_status': syncStatus,
      'total_amount': totalAmount,
      'grand_total': totalAmount,
      if (balanceDue != null) 'balance_due': balanceDue,
      if (subtotal != null) 'subtotal': subtotal,
      if (vatAmount != null) 'vat_amount': vatAmount,
      'items': items.map((item) => item.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (promisedDate != null) 'promised_date': promisedDate!.toIso8601String(),
    };
  }

  dynamic operator [](String key) => toJson()[key];

  OrderModel copyWith({
    int? id,
    int? localId,
    String? uuid,
    String? orderNumber,
    int? customerId,
    String? customerName,
    String? customerPhone,
    String? status,
    String? paymentStatus,
    String? syncStatus,
    double? totalAmount,
    double? subtotal,
    double? vatAmount,
    double? balanceDue,
    List<OrderItemModel>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? promisedDate,
  }) {
    return OrderModel(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      uuid: uuid ?? this.uuid,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      balanceDue: balanceDue ?? this.balanceDue,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      syncStatus: syncStatus ?? this.syncStatus,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      vatAmount: vatAmount ?? this.vatAmount,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      promisedDate: promisedDate ?? this.promisedDate,
    );
  }
}
