import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_user_model.dart';

class AdminUserRepository {
  final _client = Supabase.instance.client;

  Future<List<AdminUserModel>> listUsers() async {
    final response = await _client.rpc('admin_list_users');
    return (response as List)
        .map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _client.rpc(
      'admin_update_user_role',
      params: {'target_user_id': userId, 'new_role': role},
    );
  }

  Future<void> deleteUser(String userId) async {
    await _client.rpc('admin_delete_user', params: {'target_user_id': userId});
  }

  Future<String> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final id = await _client.rpc(
      'admin_create_user',
      params: {
        'p_email': email.trim(),
        'p_password': password,
        'p_full_name': fullName.trim(),
        'p_role': role,
      },
    );
    return id as String;
  }
}
