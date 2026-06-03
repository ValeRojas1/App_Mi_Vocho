import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persiste el carrito del cliente entre sesiones de la app.
class CartStorageService {
  static const _key = 'client_cart_v1';

  Future<List<Map<String, dynamic>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Map<String, dynamic>> cart) async {
    final prefs = await SharedPreferences.getInstance();
    if (cart.isEmpty) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(_key, jsonEncode(cart));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
