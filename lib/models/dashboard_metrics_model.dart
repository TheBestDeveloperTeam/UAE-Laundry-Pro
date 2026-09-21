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
      orderCount: json['order_count'] as int? ?? 0,
      balanceDue: (json['balance_due'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      productCount: json['product_count'] as int? ?? 0,
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
}
