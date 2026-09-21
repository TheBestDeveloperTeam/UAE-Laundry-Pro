class VendorModel {
  const VendorModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
  });

  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
    };
  }
}
