import 'package:flutter/material.dart';
import '../../../core/constants/order_constants.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/utils/app_errors.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../shared/screens/order_detail_screen.dart';
import '../../shared/widgets/list_shimmer.dart';
import '../../shared/widgets/order_status_chip.dart';
import '../../shared/widgets/branded_app_bar_title.dart';
import '../widgets/owner_side_drawer.dart';

enum _OrderFilter { all, pending, today }

class OwnerOrdersScreen extends StatefulWidget {
  const OwnerOrdersScreen({super.key});
  @override
  State<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends State<OwnerOrdersScreen> {
  final _repo = OrderRepository();
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _error;
  _OrderFilter _filter = _OrderFilter.all;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await _repo.getOrders(
        status: _filter == _OrderFilter.pending ? 'pending' : null,
        todayOnly: _filter == _OrderFilter.today,
      );
      if (!mounted) return;
      setState(() => _orders = orders);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = AppErrors.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setFilter(_OrderFilter f) {
    if (_filter == f) return;
    setState(() => _filter = f);
    _loadOrders();
  }

  Future<void> _changeStatus(String orderId, String status) async {
    try {
      await _repo.updateOrderStatus(orderId, status);
      if (!mounted) return;
      await _loadOrders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado actualizado'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppErrors.message(e)),
          backgroundColor: const Color(0xFFC8102E),
        ),
      );
    }
  }

  void _openDetail(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          order: order,
          ownerView: true,
          onStatusChange: (id, status) async {
            await _changeStatus(id, status);
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
    );
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
        title: const BrandedAppBarTitle(subtitle: 'Gestión de Pedidos'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primary),
            onPressed: _loading ? null : _loadOrders,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todos',
                    selected: _filter == _OrderFilter.all,
                    onTap: () => _setFilter(_OrderFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Pendientes',
                    selected: _filter == _OrderFilter.pending,
                    onTap: () => _setFilter(_OrderFilter.pending),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Hoy',
                    selected: _filter == _OrderFilter.today,
                    onTap: () => _setFilter(_OrderFilter.today),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const ListShimmer()
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadOrders,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : _orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sin pedidos en este filtro',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadOrders,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemCount: _orders.length,
                      itemBuilder: (_, i) => _OrderCard(
                        order: _orders[i],
                        onTap: () => _openDetail(_orders[i]),
                        onStatusChange: _changeStatus,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: primary.withValues(alpha: 0.15),
      checkmarkColor: primary,
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  final Future<void> Function(String, String) onStatusChange;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pickup = PickupType.fromValue(order.pickupType);
    final nextStatuses = OrderStatus.values
        .map((s) => s.value)
        .where((s) => s != order.status)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pedido #${AppFormatters.orderShortId(order.id)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  OrderStatusChip(status: order.status, ownerView: true),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppFormatters.dateTime(order.createdAt),
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        pickup.icon,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(pickup.label, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  if (order.total != null)
                    Text(
                      AppFormatters.currency(order.total!),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
              if (order.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${order.items.length} repuesto(s) · Toca para ver detalle',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              if (order.shippingAgency != null &&
                  order.shippingAgency!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Agencia: ${order.shippingAgency}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Cambiar a:',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        isDense: true,
                        hint: const Text(
                          'Estado',
                          style: TextStyle(fontSize: 12),
                        ),
                        items: nextStatuses.map((s) {
                          final st = OrderStatus.fromValue(s)!;
                          return DropdownMenuItem(
                            value: s,
                            child: Text(
                              st.ownerLabel,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) onStatusChange(order.id, val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
