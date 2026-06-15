class AdminUserModel {
  final String id;
  final String email;
  final String? fullName;
  final String role;
  final DateTime? createdAt;

  const AdminUserModel({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    this.createdAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) => AdminUserModel(
    id: json['id'] as String,
    email: json['email'] as String? ?? '',
    fullName: json['full_name'] as String?,
    role: json['role'] as String? ?? 'client',
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
  );
}
