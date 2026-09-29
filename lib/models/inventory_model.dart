import 'package:laundrypro_uae/core/safe_parser.dart';

class InventoryModel {
  const InventoryModel({
    required this.id,
    this.localId,
    required this.uuid,
    required this.itemName,
    required this.sku,
    required this.quantity,
    this.unitPrice,
    required this.reorderLevel,
    this.outOfService = false,
    this.assetTag,
    this.machineType,
    this.nextCalibrationDue,
    required this.createdAt,
    required this.updatedAt,
    this.consumedQuantity = 0,
    this.syncStatus = 'pending',
  });

  final int id;
  final int? localId;
  final String uuid;
  final String itemName;
  final String sku;
  final int quantity;
  final double? unitPrice;
  final int reorderLevel;
  final bool outOfService;
  final String? assetTag;
  final String? machineType;
  final DateTime? nextCalibrationDue;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int consumedQuantity;
  final String? syncStatus;

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: SafeParser.parseInt(json['id']),
      uuid: json['uuid'] as String,
      itemName: json['item_name'] as String,
      sku: json['sku'] as String,
      quantity: SafeParser.parseInt(json['quantity']),
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      reorderLevel: SafeParser.parseInt(json['reorder_level'], 0),
      outOfService: json['out_of_service'] == 1 || json['out_of_service'] == true,
      assetTag: json['asset_tag'] as String?,
      machineType: json['machine_type'] as String?,
      nextCalibrationDue: json['next_calibration_due'] != null ? DateTime.tryParse(json['next_calibration_due'].toString()) : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      consumedQuantity: SafeParser.parseInt(json['consumed_quantity'], 0),
      localId: json['local_id'] != null ? SafeParser.parseInt(json['local_id']) : null,
      syncStatus: json['sync_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'item_name': itemName,
      'sku': sku,
      'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      'reorder_level': reorderLevel,
      'out_of_service': outOfService,
      if (assetTag != null) 'asset_tag': assetTag,
      if (machineType != null) 'machine_type': machineType,
      if (nextCalibrationDue != null) 'next_calibration_due': nextCalibrationDue!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'consumed_quantity': consumedQuantity,
      if (localId != null) 'local_id': localId,
      if (syncStatus != null) 'sync_status': syncStatus,
    };
  }

  InventoryModel copyWith({
    int? id,
    String? uuid,
    String? itemName,
    String? sku,
    int? quantity,
    double? unitPrice,
    int? reorderLevel,
    bool? outOfService,
    String? assetTag,
    String? machineType,
    DateTime? nextCalibrationDue,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? consumedQuantity,
    int? localId,
    String? syncStatus,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      itemName: itemName ?? this.itemName,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      outOfService: outOfService ?? this.outOfService,
      assetTag: assetTag ?? this.assetTag,
      machineType: machineType ?? this.machineType,
      nextCalibrationDue: nextCalibrationDue ?? this.nextCalibrationDue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      consumedQuantity: consumedQuantity ?? this.consumedQuantity,
      localId: localId ?? this.localId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
