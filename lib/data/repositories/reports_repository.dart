import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sales_report_model.dart';

class ReportsRepository {
  final _client = Supabase.instance.client;

  Future<SalesReportModel> getSalesReport() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startIso = startOfMonth.toUtc().toIso8601String();

    final ordersRes = await _client
        .from('orders')
        .select('id, total, status, created_at')
        .gte('created_at', startIso);

    final orders = ordersRes as List<dynamic>;
    final monthOrderIds = <String>{};
    double revenue = 0;
    var monthOrders = 0;

    for (final o in orders) {
      final id = o['id'] as String;
      final status = o['status'] as String?;
      monthOrderIds.add(id);
      if (status == 'completed' ||
          status == 'ready' ||
          status == 'shipped' ||
          status == 'confirmed') {
        monthOrders++;
        revenue += (o['total'] as num?)?.toDouble() ?? 0;
      }
    }

    final pendingRes = await _client
        .from('orders')
        .select('id')
        .eq('status', 'pending')
        .count(CountOption.exact);

    final itemsRes = await _client
        .from('order_items')
        .select('product_id, quantity, unit_price, order_id, products(name)');

    final Map<String, TopProductRow> topMap = {};
    for (final row in itemsRes as List<dynamic>) {
      final orderId = row['order_id'] as String?;
      if (orderId == null || !monthOrderIds.contains(orderId)) continue;

      final pid = row['product_id'] as String;
      final qty = row['quantity'] as int? ?? 0;
      final unit = (row['unit_price'] as num?)?.toDouble() ?? 0;
      final product = row['products'] as Map<String, dynamic>?;
      final name = product?['name'] as String? ?? 'Repuesto';
      final existing = topMap[pid];
      if (existing == null) {
        topMap[pid] = TopProductRow(
          productId: pid,
          name: name,
          quantitySold: qty,
          revenue: unit * qty,
        );
      } else {
        topMap[pid] = TopProductRow(
          productId: pid,
          name: name,
          quantitySold: existing.quantitySold + qty,
          revenue: existing.revenue + unit * qty,
        );
      }
    }

    final topList = topMap.values.toList()
      ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

    return SalesReportModel(
      monthRevenue: revenue,
      monthOrders: monthOrders,
      pendingOrders: pendingRes.count,
      topProducts: topList.take(5).toList(),
    );
  }

  static const _countableStatuses = {
    'completed',
    'ready',
    'shipped',
    'confirmed',
  };

  Future<List<DailySalesPoint>> getDailyRevenue({int days = 30}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(
      Duration(days: days - 1),
    );
    final startIso = start.toUtc().toIso8601String();

    final ordersRes = await _client
        .from('orders')
        .select('total, status, created_at')
        .gte('created_at', startIso);

    final byDay = <String, ({double revenue, int orders})>{};
    for (var i = 0; i < days; i++) {
      final day = start.add(Duration(days: i));
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      byDay[key] = (revenue: 0, orders: 0);
    }

    for (final o in ordersRes as List<dynamic>) {
      final status = o['status'] as String?;
      if (!_countableStatuses.contains(status)) continue;

      final createdAt = DateTime.parse(o['created_at'] as String).toLocal();
      final key =
          '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
      final current = byDay[key];
      if (current == null) continue;

      byDay[key] = (
        revenue: current.revenue + ((o['total'] as num?)?.toDouble() ?? 0),
        orders: current.orders + 1,
      );
    }

    return byDay.entries.map((entry) {
      final parts = entry.key.split('-');
      return DailySalesPoint(
        date: DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        ),
        revenue: entry.value.revenue,
        orders: entry.value.orders,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}
