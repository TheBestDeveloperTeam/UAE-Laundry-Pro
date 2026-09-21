class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.uuid,
    this.invoiceId,
    this.orderId,
    required this.amount,
    required this.method, // 'cash', 'card', 'bank_transfer'
    required this.status, // 'completed', 'failed', 'refunded'
    this.transactionReference,
    required this.createdAt,
  });

  final int id;
  final String uuid;
  final int? invoiceId;
  final int? orderId;
  final double amount;
  final String method;
  final String status;
  final String? transactionReference;
  final DateTime createdAt;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      invoiceId: json['invoice_id'] as int?,
      orderId: json['order_id'] as int?,
      amount: (json['amount'] as num).toDouble(),
      method: json['method'] as String,
      status: json['status'] as String,
      transactionReference: json['transaction_reference'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'invoice_id': invoiceId,
      'order_id': orderId,
      'amount': amount,
      'method': method,
      'status': status,
      if (transactionReference != null) 'transaction_reference': transactionReference,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PaymentModel copyWith({
    int? id,
    String? uuid,
    int? invoiceId,
    int? orderId,
    double? amount,
    String? method,
    String? status,
    String? transactionReference,
    DateTime? createdAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      invoiceId: invoiceId ?? this.invoiceId,
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      transactionReference: transactionReference ?? this.transactionReference,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
