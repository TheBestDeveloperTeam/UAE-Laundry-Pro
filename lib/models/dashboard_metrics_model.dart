import 'package:laundrypro_uae/core/safe_parser.dart';

class DashboardMetricsModel {
  const DashboardMetricsModel({
    this.salesTotal = 0.0,
    this.orderCount = 0,
    this.balanceDue = 0.0,
    this.amountPaid = 0.0,
    this.grandTotal = 0.0,
    this.productCount = 0,
  });

  final double salesTotal;
  final int orderCount;
  final double balanceDue;
  final double amountPaid;
  final double grandTotal;
  final int productCount;

  factory DashboardMetricsModel.fromJson(Map<String, dynamic> json) {
    return DashboardMetricsModel(
      salesTotal: (json['sales_total'] as num?)?.toDouble() ?? 0.0,
      orderCount: SafeParser.parseInt(json['order_count'], 0),
      balanceDue: (json['balance_due'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      productCount: SafeParser.parseInt(json['product_count'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sales_total': salesTotal,
      'order_count': orderCount,
      'balance_due': balanceDue,
      'amount_paid': amountPaid,
      'grand_total': grandTotal,
      'product_count': productCount,
    };
  }

  dynamic operator [](String key) {
    if (key == 'summary' || key == 'valuation') return toJson();
    return toJson()[key];
  }
}
