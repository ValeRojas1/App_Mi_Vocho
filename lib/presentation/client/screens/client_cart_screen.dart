import 'package:flutter/material.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../data/services/vertical_shake_detector_service.dart';
import '../../shared/widgets/branded_app_bar_title.dart';
import 'checkout_screen.dart';

class ClientCartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final bool isActive;
  final VoidCallback onCartUpdated;
  final VoidCallback onClearAll;
  final VoidCallback onCheckoutSuccess;
  final Future<void> Function() onRefreshStock;

  const ClientCartScreen({
    super.key,
    required this.cart,
    required this.isActive,
    required this.onCartUpdated,
    required this.onClearAll,
    required this.onCheckoutSuccess,
    required this.onRefreshStock,
  });

  @override
  State<ClientCartScreen> createState() => _ClientCartScreenState();
}

class _ClientCartScreenState extends State<ClientCartScreen> {
  final _shakeDetector = VerticalShakeDetectorService();
  bool _confirmingClearAll = false;

  double get _total => widget.cart.fold(
    0.0,
    (sum, item) =>
        sum + (item['unit_price'] as double) * (item['quantity'] as int),
  );

  @override
  void initState() {
    super.initState();
    _syncShakeListener();
  }

  @override
  void didUpdateWidget(ClientCartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncShakeListener();
    }
  }

  @override
  void dispose() {
    _shakeDetector.stop();
    super.dispose();
  }

  void _syncShakeListener() {
    if (widget.isActive) {
      if (!_shakeDetector.isListening) {
        _shakeDetector.start(_onShakeDetected);
      }
    } else {
      _shakeDetector.stop();
    }
  }

  Future<void> _onShakeDetected() async {
    if (!mounted || !widget.isActive || widget.cart.isEmpty || _confirmingClearAll) {
      return;
    }
    await _confirmClearAll();
  }

  void _showStockMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ya alcanzaste el stock disponible de este repuesto.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _confirmRemove(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text(
          '¿Quiere eliminar este producto de su carrito de compras?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC8102E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _confirmClearAll() async {
    if (widget.cart.isEmpty || _confirmingClearAll) return;

    _confirmingClearAll = true;
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Vaciar carrito'),
          content: const Text(
            'Detectamos que agitaste el teléfono. ¿Deseas eliminar todos los '
            'artículos de tu carrito de compras?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8102E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar todo'),
            ),
          ],
        ),
      );

      if (!mounted || accepted != true) return;

      widget.onClearAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se eliminaron todos los artículos del carrito.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _confirmingClearAll = false;
    }
  }

  Future<void> _removeItem(
    BuildContext context,
    String productId, {
    required bool ask,
  }) async {
    if (ask && !await _confirmRemove(context)) return;
    final index = widget.cart.indexWhere((e) => e['product_id'] == productId);
    if (index < 0) return;
    widget.cart.removeAt(index);
    widget.onCartUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(subtitle: 'Mi Carrito de Compras'),
      ),
      body: widget.cart.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 72,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tu carrito está vacío',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explora el catálogo y agrega repuestos para tu Vocho.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: widget.onRefreshStock,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemCount: widget.cart.length,
                      itemBuilder: (_, i) {
                        final item = widget.cart[i];
                        final stock = item['stock'] as int;
                        final qty = item['quantity'] as int;
                        final productId = item['product_id'] as String;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shadowColor: primary.withValues(alpha: 0.03),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade100),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: secondary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.build_outlined,
                                  color: primary,
                                ),
                              ),
                              title: Text(
                                item['name'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${AppFormatters.currency(item['unit_price'] as double)} c/u · máx. $stock',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (qty > 1) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Subtotal: ${AppFormatters.currency((item['unit_price'] as double) * qty)}',
                                        style: TextStyle(
                                          color: primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      if (qty > 1) {
                                        item['quantity'] = qty - 1;
                                        widget.onCartUpdated();
                                      } else {
                                        await _removeItem(
                                          context,
                                          productId,
                                          ask: true,
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        size: 14,
                                        color: primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '$qty',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  InkWell(
                                    onTap: () {
                                      if (qty >= stock) {
                                        _showStockMessage(context);
                                        return;
                                      }
                                      item['quantity'] = qty + 1;
                                      widget.onCartUpdated();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        color: primary.withValues(alpha: 0.05),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: 14,
                                        color: primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 19,
                                    ),
                                    color: const Color(0xFFC8102E),
                                    onPressed: () => _removeItem(
                                      context,
                                      productId,
                                      ask: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total a Pagar:',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            AppFormatters.currency(_total),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.payment_rounded, size: 20),
                          label: const Text(
                            'PROCEDER AL PAGO',
                            style: TextStyle(
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutScreen(
                                cart: List.from(widget.cart),
                                total: _total,
                                onOrderSuccess: widget.onCheckoutSuccess,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
