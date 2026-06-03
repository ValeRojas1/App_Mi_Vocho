import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';

class OrderRepository {
  final _client = Supabase.instance.client;

  Future<List<OrderModel>> getOrders({
    String? clientId,
    String? status,
    bool todayOnly = false,
  }) async {
    var query = _client
        .from('orders')
        .select('*, order_items(*, products(*))');

    if (clientId != null) {
      query = query.eq('client_id', clientId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (todayOnly) {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      query = query.gte('created_at', startOfDay.toUtc().toIso8601String());
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((e) => OrderModel.fromJson(e)).toList();
  }

  Future<List<OrderModel>> getOrdersForClient(String clientId) =>
      getOrders(clientId: clientId);

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _client.from('orders').update({'status': status}).eq('id', orderId);
  }

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

  /// Crea pedido e ítems y descuenta stock (RPC atómico en Supabase).
  Future<String> createOrder({
    required String clientId,
    required String pickupType,
    required double total,
    required List<Map<String, dynamic>> items,
  }) async {
    final payload = items
        .map((item) => {
              'product_id': item['product_id'],
              'quantity': item['quantity'],
              'unit_price': item['unit_price'],
            })
        .toList();

    try {
      final orderId = await _client.rpc(
        'create_order_with_stock',
        params: {
          'p_client_id': clientId,
          'p_pickup_type': pickupType,
          'p_total': total,
          'p_items': payload,
        },
      );
      return orderId as String;
    } on PostgrestException catch (e) {
      if (e.code == '42883' ||
          e.message.contains('create_order_with_stock') ||
          e.message.contains('Could not find the function')) {
        return _createOrderFallback(
          clientId: clientId,
          pickupType: pickupType,
          total: total,
          items: items,
        );
      }
      rethrow;
    }
  }

  /// Respaldo si la migración RPC aún no está aplicada en Supabase.
  Future<String> _createOrderFallback({
    required String clientId,
    required String pickupType,
    required double total,
    required List<Map<String, dynamic>> items,
  }) async {
    for (final item in items) {
      final productId = item['product_id'] as String;
      final qty = item['quantity'] as int;
      final row = await _client
          .from('products')
          .select('stock, is_active')
          .eq('id', productId)
          .single();
      if (row['is_active'] != true) {
        throw Exception('product_not_found');
      }
      final stock = row['stock'] as int;
      if (stock < qty) throw Exception('insufficient_stock');
    }

    final order = await _client.from('orders').insert({
      'client_id': clientId,
      'pickup_type': pickupType,
      'total': total,
      'status': 'pending',
    }).select().single();

    final orderId = order['id'] as String;
    final orderItems = items
        .map((item) => {...item, 'order_id': orderId})
        .toList();
    await _client.from('order_items').insert(orderItems);

    for (final item in items) {
      final productId = item['product_id'] as String;
      final qty = item['quantity'] as int;
      final row = await _client
          .from('products')
          .select('stock')
          .eq('id', productId)
          .single();
      final newStock = (row['stock'] as int) - qty;
      await _client
          .from('products')
          .update({'stock': newStock})
          .eq('id', productId);
    }

    return orderId;
  }
}
