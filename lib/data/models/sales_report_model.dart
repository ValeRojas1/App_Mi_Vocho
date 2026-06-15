class SalesReportModel {
  final double monthRevenue;
  final int monthOrders;
  final int pendingOrders;
  final List<TopProductRow> topProducts;

  const SalesReportModel({
    required this.monthRevenue,
    required this.monthOrders,
    required this.pendingOrders,
    required this.topProducts,
  });
}

class TopProductRow {
  final String productId;
  final String name;
  final int quantitySold;
  final double revenue;

  const TopProductRow({
    required this.productId,
    required this.name,
    required this.quantitySold,
    required this.revenue,
  });
}

class DailySalesPoint {
  final DateTime date;
  final double revenue;
  final int orders;

  const DailySalesPoint({
    required this.date,
    required this.revenue,
    required this.orders,
  });
}
