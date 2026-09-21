class InvoiceModel {
  const InvoiceModel({
    required this.id,
    required this.uuid,
    required this.invoiceNumber,
    required this.orderId,
    this.customerId,
    required this.subtotal,
    required this.vatAmount,
    required this.totalAmount,
    required this.status, // e.g., 'draft', 'posted', 'paid', 'cancelled'
    required this.createdAt,
    required this.isPosted,
  });

  final int id;
  final String uuid;
  final String invoiceNumber;
  final int orderId;
  final int? customerId;
  final double subtotal;
  final double vatAmount;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final bool isPosted;

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      invoiceNumber: json['invoice_number'] as String,
      orderId: json['order_id'] as int,
      customerId: json['customer_id'] as int?,
      subtotal: (json['subtotal'] as num).toDouble(),
      vatAmount: (json['vat_amount'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isPosted: json['is_posted'] == 1 || json['is_posted'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'invoice_number': invoiceNumber,
      'order_id': orderId,
      'customer_id': customerId,
      'subtotal': subtotal,
      'vat_amount': vatAmount,
      'total_amount': totalAmount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'is_posted': isPosted ? 1 : 0,
    };
  }

  InvoiceModel copyWith({
    int? id,
    String? uuid,
    String? invoiceNumber,
    int? orderId,
    int? customerId,
    double? subtotal,
    double? vatAmount,
    double? totalAmount,
    String? status,
    DateTime? createdAt,
    bool? isPosted,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      subtotal: subtotal ?? this.subtotal,
      vatAmount: vatAmount ?? this.vatAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isPosted: isPosted ?? this.isPosted,
    );
  }
}
