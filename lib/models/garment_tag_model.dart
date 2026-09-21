import 'package:laundrypro_uae/core/safe_parser.dart';

class GarmentTagModel {
  const GarmentTagModel({
    required this.id,
    required this.uuid,
    required this.rfidEpc,
    this.barcode,
    required this.orderItemId,
    required this.status, // 'received', 'washing', 'ironing', 'ready', 'delivered'
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String uuid;
  final String rfidEpc;
  final String? barcode;
  final int orderItemId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory GarmentTagModel.fromJson(Map<String, dynamic> json) {
    return GarmentTagModel(
      id: SafeParser.parseInt(json['id']),
      uuid: json['uuid'] as String,
      rfidEpc: json['rfid_epc'] as String,
      barcode: json['barcode'] as String?,
      orderItemId: SafeParser.parseInt(json['order_item_id']),
      status: json['status'] as String,
      createdAt: SafeParser.parseDateTime(json['created_at']),
      updatedAt: SafeParser.parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'rfid_epc': rfidEpc,
      if (barcode != null) 'barcode': barcode,
      'order_item_id': orderItemId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GarmentTagModel copyWith({
    int? id,
    String? uuid,
    String? rfidEpc,
    String? barcode,
    int? orderItemId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GarmentTagModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      rfidEpc: rfidEpc ?? this.rfidEpc,
      barcode: barcode ?? this.barcode,
      orderItemId: orderItemId ?? this.orderItemId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
