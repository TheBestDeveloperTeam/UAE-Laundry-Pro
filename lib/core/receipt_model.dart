class ReceiptLine {
  ReceiptLine({
    required this.description,
    required this.quantity,
    required this.rate,
    required this.amount,
  });

  final String description;
  final double quantity;
  final double rate;
  final double amount;

  factory ReceiptLine.fromMap(Map<String, dynamic> map) {
    return ReceiptLine(
      description: map['description']?.toString() ?? '',
      quantity: double.tryParse(map['quantity']?.toString() ?? '0') ?? 0,
      rate: double.tryParse(map['rate']?.toString() ?? '0') ?? 0,
      amount: double.tryParse(map['amount']?.toString() ?? '0') ?? 0,
    );
  }
}

class ReceiptModel {
  ReceiptModel({
    required this.orderNo,
    required this.lines,
    required this.subtotal,
    required this.grandTotal,
    required this.amountPaid,
    required this.balanceDue,
  });

  final String orderNo;
  final List<ReceiptLine> lines;
  final double subtotal;
  final double grandTotal;
  final double amountPaid;
  final double balanceDue;

  factory ReceiptModel.fromOrder(Map<String, dynamic> order) {
    final rawLines = order['lines'] as List? ?? [];
    final lines = rawLines
        .map((e) => ReceiptLine.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return ReceiptModel(
      orderNo: order['order_no']?.toString() ?? '',
      lines: lines,
      subtotal: double.tryParse(order['subtotal']?.toString() ?? '0') ?? 0,
      grandTotal: double.tryParse(order['grand_total']?.toString() ?? '0') ?? 0,
      amountPaid: double.tryParse(order['amount_paid']?.toString() ?? '0') ?? 0,
      balanceDue: double.tryParse(order['balance_due']?.toString() ?? '0') ?? 0,
    );
  }
}
