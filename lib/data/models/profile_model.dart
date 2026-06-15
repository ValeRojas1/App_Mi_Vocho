class ProfileModel {
  final String id;
  final String? fullName;
  final String? phone;
  final String? region;
  final String? deliveryAddress;
  final String role;

  const ProfileModel({
    required this.id,
    this.fullName,
    this.phone,
    this.region,
    this.deliveryAddress,
    required this.role,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json['id'] as String,
    fullName: json['full_name'] as String?,
    phone: json['phone'] as String?,
    region: json['region'] as String?,
    deliveryAddress: json['delivery_address'] as String?,
    role: json['role'] as String? ?? 'client',
  );

  Map<String, dynamic> toUpdateJson() => {
    'full_name': fullName,
    'phone': phone,
    'region': region,
    'delivery_address': deliveryAddress,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };
}
