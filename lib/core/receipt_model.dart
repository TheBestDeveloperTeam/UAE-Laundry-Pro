import 'package:laundrypro_uae/models/order_model.dart';

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

  factory ReceiptModel.fromMap(Map<String, dynamic> map) {
    final rawLines = map['lines'] as List? ?? map['items'] as List? ?? [];
    final lines = rawLines
        .map((e) => ReceiptLine.fromMap(Map<String, dynamic>.from(e as Map? ?? {})))
        .toList();

    return ReceiptModel(
      orderNo: (map['order_no'] ?? map['order_number'] ?? '') as String,
      lines: lines,
      subtotal: double.tryParse(map['subtotal']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(map['discount']?.toString() ?? '0') ?? 0.0,
      tax: double.tryParse((map['tax'] ?? map['vat_amount'])?.toString() ?? '0') ?? 0.0,
      grandTotal: double.tryParse((map['grand_total'] ?? map['total_amount'])?.toString() ?? '0') ?? 0.0,
      amountPaid: double.tryParse(map['amount_paid']?.toString() ?? '0') ?? 0.0,
      balanceDue: double.tryParse(map['balance_due']?.toString() ?? '0') ?? 0.0,
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      trn: map['trn'] as String?,
      createdAt: map['created_at']?.toString(),
      promisedDate: map['promised_date']?.toString(),
      status: map['status'] as String?,
      paymentStatus: map['payment_status'] as String?,
    );
  }

  factory ReceiptModel.fromOrder(dynamic order) {
    if (order is OrderModel) {
      return ReceiptModel.fromOrderModel(order);
    } else if (order is Map<String, dynamic>) {
      return ReceiptModel.fromMap(order);
    } else if (order is Map) {
      return ReceiptModel.fromMap(Map<String, dynamic>.from(order));
    }
    return ReceiptModel.fromMap({});
  }

  factory ReceiptModel.fromOrderModel(OrderModel order) {
    final lines = order.lines?.map((e) => ReceiptLine(
      description: e.description ?? '',
      quantity: double.tryParse(e.quantity?.toString() ?? '0') ?? 0.0,
      rate: double.tryParse(e.rate?.toString() ?? '0') ?? 0.0,
      amount: double.tryParse(e.amount?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(e.discount?.toString() ?? '0') ?? 0.0,
      modifiers: [], // simplified for now
    )).toList() ?? [];

    return ReceiptModel(
      orderNo: order.orderNo ?? '',
      lines: lines,
      subtotal: double.tryParse(order.subtotal?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(order.discount?.toString() ?? '0') ?? 0.0,
      tax: double.tryParse(order.tax?.toString() ?? '0') ?? 0.0,
      grandTotal: double.tryParse(order.grandTotal?.toString() ?? '0') ?? 0.0,
      amountPaid: double.tryParse(order.amountPaid?.toString() ?? '0') ?? 0.0,
      balanceDue: double.tryParse(order.balanceDue?.toString() ?? '0') ?? 0.0,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      trn: order.trn,
      createdAt: order.createdAt?.toIso8601String(),
      promisedDate: order.promisedDate?.toIso8601String(),
      status: order.status,
      paymentStatus: order.paymentStatus,
    );
  }
}
