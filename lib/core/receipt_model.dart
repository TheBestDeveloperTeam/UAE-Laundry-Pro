class ReceiptLine {
  ReceiptLine({
    required this.description,
    required this.quantity,
    required this.rate,
    required this.amount,
    this.discount = 0.0,
    this.modifiers = const [],
  });

  final String description;
  final double quantity;
  final double rate;
  final double amount;
  final double discount;
  final List<String> modifiers;

  factory ReceiptLine.fromMap(Map<String, dynamic> map) {
    final rawMods = map['modifiers'];
    List<String> parsedMods = [];
    if (rawMods is List) {
      parsedMods = rawMods.map((m) => m is Map ? (m['name']?.toString() ?? '') : m.toString()).toList();
    }
    return ReceiptLine(
      description: map['description']?.toString() ?? '',
      quantity: double.tryParse(map['quantity']?.toString() ?? '0') ?? 0,
      rate: double.tryParse(map['rate']?.toString() ?? '0') ?? 0,
      amount: double.tryParse(map['amount']?.toString() ?? '0') ?? 0,
      discount: double.tryParse(map['discount']?.toString() ?? '0') ?? 0,
      modifiers: parsedMods,
    );
  }
}

class ReceiptModel {
  ReceiptModel({
    required this.orderNo,
    required this.lines,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.grandTotal,
    required this.amountPaid,
    required this.balanceDue,
    this.customerName,
    this.customerPhone,
    this.trn,
    this.createdAt,
    this.promisedDate,
    this.status,
    this.paymentStatus,
  });

  final String orderNo;
  final List<ReceiptLine> lines;
  final double subtotal;
  final double discount;
  final double tax;
  final double grandTotal;
  final double amountPaid;
  final double balanceDue;
  final String? customerName;
  final String? customerPhone;
  final String? trn;
  final String? createdAt;
  final String? promisedDate;
  final String? status;
  final String? paymentStatus;

  factory ReceiptModel.fromOrder(Map<String, dynamic> order) {
    final rawLines = order['lines'] as List? ?? [];
    final lines = rawLines
        .map((e) => ReceiptLine.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return ReceiptModel(
      orderNo: order['order_no']?.toString() ?? '',
      lines: lines,
      subtotal: double.tryParse(order['subtotal']?.toString() ?? '0') ?? 0,
      discount: double.tryParse(order['discount']?.toString() ?? '0') ?? 0,
      tax: double.tryParse(order['tax']?.toString() ?? '0') ?? 0,
      grandTotal: double.tryParse(order['grand_total']?.toString() ?? '0') ?? 0,
      amountPaid: double.tryParse(order['amount_paid']?.toString() ?? '0') ?? 0,
      balanceDue: double.tryParse(order['balance_due']?.toString() ?? '0') ?? 0,
      customerName: order['customer_name']?.toString() ?? order['customer']?['name']?.toString(),
      customerPhone: order['customer_phone']?.toString() ?? order['customer']?['phone']?.toString(),
      trn: order['trn']?.toString(),
      createdAt: order['created_at']?.toString(),
      promisedDate: order['promised_date']?.toString(),
      status: order['status']?.toString(),
      paymentStatus: order['payment_status']?.toString(),
    );
  }
}
