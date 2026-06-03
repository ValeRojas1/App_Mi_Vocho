import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/order_constants.dart';

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
    } catch (_) {
      // Tabla profiles o RLS aún no aplicados: fallback legado.
    }

    if (user.email == kLegacyOwnerEmail) {
      return AppRole.owner.value;
    }
    return AppRole.client.value;
  }
}
