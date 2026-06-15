import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/store_settings_model.dart';

class StoreRepository {
  final _client = Supabase.instance.client;

  Future<StoreSettingsModel> getStoreSettings() async {
    try {
      final row = await _client
          .from('store_settings')
          .select()
          .limit(1)
          .maybeSingle();
      if (row != null) {
        return StoreSettingsModel.fromJson(row);
      }
    } catch (_) {}
    return StoreSettingsModel.fallback;
  }
}
