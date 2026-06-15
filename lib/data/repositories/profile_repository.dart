import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/order_constants.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  final _client = Supabase.instance.client;

  Future<String> resolveRole() async {
    final user = _client.auth.currentUser;
    if (user == null) return AppRole.client.value;

    try {
      final row = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      if (row != null && row['role'] != null) {
        return row['role'] as String;
      }
    } catch (_) {}

    if (user.email == kLegacyOwnerEmail) {
      return AppRole.owner.value;
    }
    return AppRole.client.value;
  }

  Future<ProfileModel?> getMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final row = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) {
      return ProfileModel(
        id: user.id,
        fullName: user.userMetadata?['full_name'] as String?,
        role: await resolveRole(),
      );
    }
    return ProfileModel.fromJson(row);
  }

  Future<void> updateMyProfile(ProfileModel profile) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No autenticado');

    await _client
        .from('profiles')
        .update(profile.toUpdateJson())
        .eq('id', user.id);

    await _client.auth.updateUser(
      UserAttributes(data: {'full_name': profile.fullName}),
    );
  }
}
