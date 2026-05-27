import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';

class OrderRepository {
  final _client = Supabase.instance.client;

  Future<List<OrderModel>> getOrders() async {
    final response = await _client
        .from('orders')
        .select('*, order_items(*, products(*))')
        .order('created_at', ascending: false);
    return (response as List).map((e) => OrderModel.fromJson(e)).toList();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _client
        .from('orders')
        .update({'status': status})
        .eq('id', orderId);
  }

  /// Devuelve estadísticas para el dashboard de la dueña:
  /// - todayCount: pedidos creados hoy (zona local del dispositivo).
  /// - pendingCount: pedidos con status = 'pending'.
  Future<({int todayCount, int pendingCount})> getDashboardStats() async {
    final now = DateTime.now();
    final startOfDayLocal = DateTime(now.year, now.month, now.day);
    final startOfDayIso = startOfDayLocal.toUtc().toIso8601String();

    final todayRes = await _client
        .from('orders')
        .select('id')
        .gte('created_at', startOfDayIso)
        .count(CountOption.exact);

    final pendingRes = await _client
        .from('orders')
        .select('id')
        .eq('status', 'pending')
        .count(CountOption.exact);

    return (
      todayCount: todayRes.count,
      pendingCount: pendingRes.count,
    );
  }

  Future<String> createOrder({
    required String clientId,
    required String pickupType,
    required double total,
    required List<Map<String, dynamic>> items,
  }) async {
    final order = await _client.from('orders').insert({
      'client_id': clientId,
      'pickup_type': pickupType,
      'total': total,
      'status': 'pending',
    }).select().single();

    final orderItems = items.map((item) => {
      ...item,
      'order_id': order['id'],
    }).toList();

    await _client.from('order_items').insert(orderItems);
    return order['id'];
  }
}