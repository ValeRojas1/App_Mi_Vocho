import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'owner_dashboard_screen.dart';
import 'owner_inventory_screen.dart';
import 'owner_orders_screen.dart';

class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});
  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _index = 0;
  final _screens = const [
    OwnerDashboardScreen(),
    OwnerOrdersScreen(),
    OwnerInventoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.ownerTheme,
      child: Scaffold(
        body: _screens[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Pedidos',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Inventario',
            ),
          ],
        ),
      ),
    );
  }
}