import 'package:laundrypro_uae/core/safe_parser.dart';

class VendorModel {
  const VendorModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.paymentTerms = 'Net 30',
    this.creditLimit = 0.0,
    this.trn,
    this.bankDetails,
  });

  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String paymentTerms;
  final double creditLimit;
  final String? trn;
  final String? bankDetails;

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: SafeParser.parseInt(json['id'], 0),
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      paymentTerms: json['payment_terms'] as String? ?? 'Net 30',
      creditLimit: SafeParser.parseDouble(json['credit_limit'], 0.0),
      trn: json['trn'] as String?,
      bankDetails: json['bank_details'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      'payment_terms': paymentTerms,
      'credit_limit': creditLimit,
      if (trn != null) 'trn': trn,
      if (bankDetails != null) 'bank_details': bankDetails,
    };
  }
}
