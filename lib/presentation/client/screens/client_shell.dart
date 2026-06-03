import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/cart_storage_service.dart';
import 'client_catalog_screen.dart';
import 'client_orders_screen.dart';
import 'client_cart_screen.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});
  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;
  final _cartStorage = CartStorageService();
  final List<Map<String, dynamic>> _cart = [];
  bool _cartReady = false;

  final GlobalKey<ClientOrdersScreenState> _ordersKey =
      GlobalKey<ClientOrdersScreenState>();

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final saved = await _cartStorage.load();
    if (!mounted) return;
    setState(() {
      _cart
        ..clear()
        ..addAll(saved);
      _cartReady = true;
    });
  }

  Future<void> _persistCart() async {
    await _cartStorage.save(_cart);
  }

  int get _cartUnits =>
      _cart.fold<int>(0, (sum, e) => sum + (e['quantity'] as int));

  bool addToCart(Map<String, dynamic> item) {
    final stock = item['stock'] as int;
    final productId = item['product_id'] as String;
    final idx = _cart.indexWhere((e) => e['product_id'] == productId);
    final currentQty =
        idx >= 0 ? _cart[idx]['quantity'] as int : 0;

    if (currentQty >= stock) {
      return false;
    }

    setState(() {
      if (idx >= 0) {
        _cart[idx]['quantity'] = currentQty + 1;
      } else {
        _cart.add({...item, 'quantity': 1});
      }
    });
    _persistCart();
    return true;
  }

  void _onCartUpdated() {
    setState(() {});
    _persistCart();
  }

  void clearCart() {
    setState(() => _cart.clear());
    _cartStorage.clear();
  }

  void _onCheckoutSuccess() {
    clearCart();
    _ordersKey.currentState?.refresh();
    setState(() => _index = 2);
  }

  @override
  Widget build(BuildContext context) {
    if (!_cartReady) {
      return Theme(
        data: AppTheme.clientTheme,
        child: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Theme(
      data: AppTheme.clientTheme,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            ClientCatalogScreen(onAddToCart: addToCart),
            ClientCartScreen(
              cart: _cart,
              onCartUpdated: _onCartUpdated,
              onCheckoutSuccess: _onCheckoutSuccess,
            ),
            ClientOrdersScreen(key: _ordersKey),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.store_outlined),
              selectedIcon: Icon(Icons.store),
              label: 'Catálogo',
            ),
            NavigationDestination(
              icon: Badge(
                label: Text('$_cartUnits'),
                isLabelVisible: _cartUnits > 0,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              selectedIcon: const Icon(Icons.shopping_cart),
              label: 'Carrito',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_outlined),
              selectedIcon: Icon(Icons.receipt),
              label: 'Mis Pedidos',
            ),
          ],
        ),
      ),
    );
  }
}
