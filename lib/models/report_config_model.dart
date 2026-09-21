import 'package:laundrypro_uae/core/safe_parser.dart';

class ReportConfigModel {
  const ReportConfigModel({
    this.fromDate,
    this.toDate,
    this.branchId,
    this.userId,
    this.customerId,
    this.metric,
  });

  final String? fromDate;
  final String? toDate;
  final int? branchId;
  final int? userId;
  final int? customerId;
  final String? metric;

  factory ReportConfigModel.fromJson(Map<String, dynamic> json) {
    return ReportConfigModel(
      fromDate: json['from_date'] as String?,
      toDate: json['to_date'] as String?,
      branchId: SafeParser.parseInt(json['branch_id']) == 0 ? null : SafeParser.parseInt(json['branch_id']),
      userId: SafeParser.parseInt(json['user_id']) == 0 ? null : SafeParser.parseInt(json['user_id']),
      customerId: SafeParser.parseInt(json['customer_id']) == 0 ? null : SafeParser.parseInt(json['customer_id']),
      metric: json['metric'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (fromDate != null) 'from_date': fromDate,
      if (toDate != null) 'to_date': toDate,
      if (branchId != null) 'branch_id': branchId,
      if (userId != null) 'user_id': userId,
      if (customerId != null) 'customer_id': customerId,
      if (metric != null) 'metric': metric,
    };
  }
}
