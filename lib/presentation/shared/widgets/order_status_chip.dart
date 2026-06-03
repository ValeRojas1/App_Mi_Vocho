import 'package:flutter/material.dart';
import '../../../core/constants/order_constants.dart';

class OrderStatusChip extends StatelessWidget {
  final String status;
  final bool ownerView;

  const OrderStatusChip({
    super.key,
    required this.status,
    this.ownerView = false,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = OrderStatus.fromValue(status);
    final color = parsed?.color ?? Colors.grey;
    final label = parsed == null
        ? status
        : (ownerView ? parsed.ownerLabel : parsed.clientLabel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
