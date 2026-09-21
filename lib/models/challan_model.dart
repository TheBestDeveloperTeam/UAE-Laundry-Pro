class ChallanLine {
  ChallanLine({
    required this.description,
    required this.quantity,
    this.notes,
  });

  final String description;
  final double quantity;
  final String? notes;

  factory ChallanLine.fromMap(Map<String, dynamic> map) {
    return ChallanLine(
      description: map['description']?.toString() ?? map['item_name']?.toString() ?? '',
      quantity: double.tryParse(map['quantity']?.toString() ?? '0') ?? 0,
      notes: map['notes']?.toString(),
    );
  }
}

class ChallanModel {
  ChallanModel({
    required this.challanNo,
    required this.challanType,
    required this.status,
    required this.lines,
    this.notes,
    this.referenceType,
    this.referenceId,
  });

  final String challanNo;
  final String challanType;
  final String status;
  final List<ChallanLine> lines;
  final String? notes;
  final String? referenceType;
  final int? referenceId;

  factory ChallanModel.fromMap(Map<String, dynamic> map) {
    final rawLines = map['lines'] as List? ?? [];
    return ChallanModel(
      challanNo: map['challan_no']?.toString() ?? '',
      challanType: map['challan_type']?.toString() ?? 'delivery',
      status: map['status']?.toString() ?? 'issued',
      notes: map['notes']?.toString(),
      referenceType: map['reference_type']?.toString(),
      referenceId: int.tryParse(map['reference_id']?.toString() ?? ''),
      lines: rawLines.map((e) => ChallanLine.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}
