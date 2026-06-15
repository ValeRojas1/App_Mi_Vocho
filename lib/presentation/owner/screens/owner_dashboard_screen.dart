import 'package:flutter/material.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../shared/widgets/branded_app_bar_title.dart';
import '../widgets/owner_side_drawer.dart';

class OwnerDashboardScreen extends StatefulWidget {
  final VoidCallback? onInitialLoadComplete;

  const OwnerDashboardScreen({super.key, this.onInitialLoadComplete});

  @override
  State<OwnerDashboardScreen> createState() => OwnerDashboardScreenState();
}

class OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final _productRepo = ProductRepository();
  final _orderRepo = OrderRepository();

  bool _loading = true;
  String? _error;

  int _todayOrders = 0;
  int _pendingOrders = 0;
  int _activeProducts = 0;
  int _lowStock = 0;
  bool _notifiedInitialLoad = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  /// Método público para que el shell pueda refrescar al volver a esta pestaña.
  Future<void> refresh() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _orderRepo.getDashboardStats(),
        _productRepo.getInventoryStats(),
      ]);
      final orderStats = results[0] as ({int todayCount, int pendingCount});
      final productStats = results[1] as ({int activeCount, int lowStockCount});

      if (!mounted) return;
      setState(() {
        _todayOrders = orderStats.todayCount;
        _pendingOrders = orderStats.pendingCount;
        _activeProducts = productStats.activeCount;
        _lowStock = productStats.lowStockCount;
        _loading = false;
      });
      _notifyInitialLoadComplete();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      _notifyInitialLoadComplete();
    }
  }

  void _notifyInitialLoadComplete() {
    if (_notifiedInitialLoad) return;
    _notifiedInitialLoad = true;
    widget.onInitialLoadComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      drawer: const OwnerSideDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const BrandedAppBarTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            color: primary,
            onPressed: _loading ? null : refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        color: primary,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.admin_panel_settings,
                            color: primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Bienvenida, Dueña!',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Panel de control de Mi Vocho',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Resumen del Negocio',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primary.withValues(alpha: 0.8),
                          ),
                        ),
                        if (_loading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No se pudieron cargar las estadísticas: $_error',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.15,
                ),
                delegate: SliverChildListDelegate([
                  _StatCard(
                    label: 'Pedidos Hoy',
                    value: _loading ? '--' : _todayOrders.toString(),
                    icon: Icons.shopping_bag_outlined,
                    color: primary,
                  ),
                  _StatCard(
                    label: 'Por Confirmar',
                    value: _loading ? '--' : _pendingOrders.toString(),
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    label: 'Repuestos Activos',
                    value: _loading ? '--' : _activeProducts.toString(),
                    icon: Icons.inventory_2_outlined,
                    color: Colors.teal,
                  ),
                  _StatCard(
                    label: 'Stock Bajo',
                    value: _loading ? '--' : _lowStock.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFC8102E),
                    highlight: !_loading && _lowStock > 0,
                  ),
                ]),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 36),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tips_and_updates,
                          color: theme.colorScheme.secondary,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tip de Gestión',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _lowStock > 0
                                    ? 'Tienes $_lowStock repuesto${_lowStock == 1 ? '' : 's'} con stock bajo (≤ ${ProductRepository.lowStockThreshold}). Revisa la pestaña de Inventario para reabastecer.'
                                    : 'Revisa la pestaña de inventario periódicamente para asegurar stock óptimo de piezas de alta rotación.',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool highlight;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: highlight
            ? BorderSide(color: color.withValues(alpha: 0.5), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Actualizado ahora',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
