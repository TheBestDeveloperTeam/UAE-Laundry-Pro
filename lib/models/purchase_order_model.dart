import 'package:laundrypro_uae/core/safe_parser.dart';

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
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderModel(
      id: SafeParser.parseInt(json['id'], 0),
      uuid: json['uuid'] as String? ?? '',
      poNo: json['po_no'] as String? ?? '',
      vendorId: SafeParser.parseInt(json['vendor_id'], 0),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      receivedAt: json['received_at'] != null ? DateTime.tryParse(json['received_at'].toString()) : null,
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  dynamic operator [](String key) => toJson()[key];
}
