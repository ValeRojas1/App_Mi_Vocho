import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/app_errors.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../data/models/sales_report_model.dart';
import '../../../data/repositories/reports_repository.dart';
import '../../shared/widgets/branded_app_bar_title.dart';
import '../../shared/widgets/list_shimmer.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  final _repo = ReportsRepository();
  SalesReportModel? _report;
  List<DailySalesPoint> _daily = [];
  bool _loading = true;
  String? _error;
  int _rangeDays = 30;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.getSalesReport(),
        _repo.getDailyRevenue(days: _rangeDays),
      ]);
      if (!mounted) return;
      setState(() {
        _report = results[0] as SalesReportModel;
        _daily = results[1] as List<DailySalesPoint>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = AppErrors.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeRange(int days) async {
    setState(() => _rangeDays = days);
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(subtitle: 'Estadísticas de ventas'),
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Rango de días',
            onSelected: _changeRange,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 7, child: Text('Últimos 7 días')),
              PopupMenuItem(value: 30, child: Text('Últimos 30 días')),
              PopupMenuItem(value: 90, child: Text('Últimos 90 días')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$_rangeDays días'),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : refresh,
          ),
        ],
      ),
      body: _loading
          ? const ListShimmer(itemCount: 4, itemHeight: 120)
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: refresh,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _SummaryCards(report: _report!, primary: primary),
                  const SizedBox(height: 24),
                  Text(
                    'Ingresos diarios',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RevenueLineChart(points: _daily, color: primary),
                  const SizedBox(height: 24),
                  Text(
                    'Top repuestos vendidos (mes)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TopProductsBarChart(
                    products: _report!.topProducts,
                    color: primary,
                  ),
                ],
              ),
            ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final SalesReportModel report;
  final Color primary;

  const _SummaryCards({required this.report, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatTile(
          icon: Icons.payments_outlined,
          label: 'Ingresos del mes',
          value: AppFormatters.currency(report.monthRevenue),
          color: primary,
          width: 220,
        ),
        _StatTile(
          icon: Icons.receipt_long,
          label: 'Pedidos del mes',
          value: '${report.monthOrders}',
          color: Colors.teal,
          width: 180,
        ),
        _StatTile(
          icon: Icons.pending_actions,
          label: 'Pendientes',
          value: '${report.pendingOrders}',
          color: Colors.orange,
          width: 180,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double width;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueLineChart extends StatelessWidget {
  final List<DailySalesPoint> points;
  final Color color;

  const _RevenueLineChart({required this.points, required this.color});

  @override
  Widget build(BuildContext context) {
    if (points.every((p) => p.revenue == 0)) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Sin ventas registradas en el periodo seleccionado.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    final maxY = points
        .map((p) => p.revenue)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 24, 16, 8),
        child: SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY <= 0 ? 1 : maxY * 1.15,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0 ? maxY / 4 : 1,
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (value, meta) => Text(
                      value >= 1000
                          ? '${(value / 1000).toStringAsFixed(0)}k'
                          : value.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: points.length > 14 ? 7 : 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= points.length) {
                        return const SizedBox.shrink();
                      }
                      final date = points[index].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${date.day}/${date.month}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < points.length; i++)
                      FlSpot(i.toDouble(), points[i].revenue),
                  ],
                  isCurved: true,
                  color: color,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopProductsBarChart extends StatelessWidget {
  final List<TopProductRow> products;
  final Color color;

  const _TopProductsBarChart({required this.products, required this.color});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Aún no hay productos vendidos este mes.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    final maxQty = products
        .map((p) => p.quantitySold.toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 24, 16, 16),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maxQty <= 0 ? 1 : maxQty * 1.2,
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= products.length) {
                        return const SizedBox.shrink();
                      }
                      final name = products[index].name;
                      final short = name.length > 10
                          ? '${name.substring(0, 10)}…'
                          : name;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          short,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (var i = 0; i < products.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: products[i].quantitySold.toDouble(),
                        color: color,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
