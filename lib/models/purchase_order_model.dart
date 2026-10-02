import 'package:laundrypro_uae/core/safe_parser.dart';

class PurchaseOrderLineModel {
  const PurchaseOrderLineModel({
    required this.id,
    required this.purchaseOrderId,
    required this.lineNo,
    required this.productId,
    this.productName,
    required this.quantityOrdered,
    required this.quantityReceived,
    required this.unitCost,
  });

  final int id;
  final int purchaseOrderId;
  final int lineNo;
  final int productId;
  final String? productName;
  final double quantityOrdered;
  final double quantityReceived;
  final double unitCost;

  double get quantityRemaining => (quantityOrdered - quantityReceived).clamp(0.0, double.infinity);
  bool get isFullyReceived => quantityReceived >= quantityOrdered;

  factory PurchaseOrderLineModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderLineModel(
      id: SafeParser.parseInt(json['id'], 0),
      purchaseOrderId: SafeParser.parseInt(json['purchase_order_id'], 0),
      lineNo: SafeParser.parseInt(json['line_no'], 1),
      productId: SafeParser.parseInt(json['product_id'], 0),
      productName: json['product_name'] as String?,
      quantityOrdered: (json['quantity_ordered'] as num?)?.toDouble() ?? 0.0,
      quantityReceived: (json['quantity_received'] as num?)?.toDouble() ?? 0.0,
      unitCost: (json['unit_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_order_id': purchaseOrderId,
      'line_no': lineNo,
      'product_id': productId,
      if (productName != null) 'product_name': productName,
      'quantity_ordered': quantityOrdered,
      'quantity_received': quantityReceived,
      'unit_cost': unitCost,
    };
  }
}

class PurchaseOrderModel {
  const PurchaseOrderModel({
    required this.id,
    required this.uuid,
    required this.poNo,
    required this.vendorId,
    required this.totalAmount,
    required this.status,
    this.notes,
    this.receivedAt,
    this.lines = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String uuid;
  final String poNo;
  final int vendorId;
  final double totalAmount;
  final String status;
  final String? notes;
  final DateTime? receivedAt;
  final List<PurchaseOrderLineModel> lines;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List? ?? [];
    return PurchaseOrderModel(
      id: SafeParser.parseInt(json['id'], 0),
      uuid: json['uuid'] as String? ?? '',
      poNo: json['po_no'] as String? ?? '',
      vendorId: SafeParser.parseInt(json['vendor_id'], 0),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      receivedAt: json['received_at'] != null ? DateTime.tryParse(json['received_at'].toString()) : null,
      lines: rawLines
          .map((e) => PurchaseOrderLineModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'po_no': poNo,
      'vendor_id': vendorId,
      'total_amount': totalAmount,
      'status': status,
      if (notes != null) 'notes': notes,
      if (receivedAt != null) 'received_at': receivedAt!.toIso8601String(),
      'lines': lines.map((l) => l.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  dynamic operator [](String key) => toJson()[key];
}
