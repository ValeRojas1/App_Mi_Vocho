import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/order_constants.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../data/models/order_model.dart';
import '../../client/screens/store_map_screen.dart';
import '../widgets/order_status_chip.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;
  final bool ownerView;
  final void Function(String orderId, String status)? onStatusChange;

  const OrderDetailScreen({
    super.key,
    required this.order,
    this.ownerView = false,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final status = OrderStatus.fromValue(order.status);
    final pickup = PickupType.fromValue(order.pickupType);
    final nextStatuses = OrderStatus.values
        .map((s) => s.value)
        .where((s) => s != order.status)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${AppFormatters.orderShortId(order.id)}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OrderStatusChip(
                        status: order.status,
                        ownerView: ownerView,
                      ),
                      Text(
                        AppFormatters.dateTime(order.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(pickup.icon, color: primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        pickup.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (order.paymentMethod != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Pago: ${PaymentMethod.fromValue(order.paymentMethod).label}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (order.shippingAgency != null &&
                      order.shippingAgency!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Agencia: ${order.shippingAgency}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (order.total != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Total: ${AppFormatters.currency(order.total!)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!ownerView && pickup == PickupType.local) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StoreMapScreen(emphasizePickup: true),
                  ),
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Cómo llegar a la tienda'),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Repuestos',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 12),
          if (order.items.isEmpty)
            Text(
              'Sin detalle de ítems.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ...order.items.map((item) {
              final name = item.product?.name ?? 'Repuesto';
              final imageUrl = item.product?.imageUrl;
              final lineTotal = item.unitPrice * item.quantity;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.build_outlined, color: primary),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${item.quantity} × ${AppFormatters.currency(item.unitPrice)}',
                  ),
                  trailing: Text(
                    AppFormatters.currency(lineTotal),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ),
              );
            }),
          if (ownerView && onStatusChange != null) ...[
            const SizedBox(height: 24),
            Text(
              'Cambiar estado',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Nuevo estado',
                border: OutlineInputBorder(),
              ),
              items: nextStatuses.map((s) {
                final st = OrderStatus.fromValue(s)!;
                return DropdownMenuItem(value: s, child: Text(st.ownerLabel));
              }).toList(),
              onChanged: (val) {
                if (val != null) onStatusChange!(order.id, val);
              },
            ),
            if (order.pickupType == PickupType.interprovincial.value &&
                status == OrderStatus.ready) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pedido interprovincial listo: coordina el envío por encomienda.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
