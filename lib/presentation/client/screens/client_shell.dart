import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
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
  // Carrito simple en memoria para el prototipo
  final List<Map<String, dynamic>> _cart = [];

  void _addToCart(Map<String, dynamic> item) {
    final idx = _cart.indexWhere((e) => e['product_id'] == item['product_id']);
    setState(() {
      if (idx >= 0) {
        _cart[idx]['quantity'] = (_cart[idx]['quantity'] as int) + 1;
      } else {
        _cart.add({...item, 'quantity': 1});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.clientTheme,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            ClientCatalogScreen(onAddToCart: _addToCart),
            ClientCartScreen(cart: _cart, onCartUpdated: () => setState(() {})),
            const ClientOrdersScreen(),
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
                label: Text(_cart.length.toString()),
                isLabelVisible: _cart.isNotEmpty,
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