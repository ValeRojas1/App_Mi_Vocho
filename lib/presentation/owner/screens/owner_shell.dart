import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/elevator_loading_gate.dart';
import 'owner_dashboard_screen.dart';
import 'owner_inventory_screen.dart';
import 'owner_orders_screen.dart';
import 'owner_reports_screen.dart';

class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});
  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _index = 0;
  bool _ownerReady = false;

  final GlobalKey<OwnerDashboardScreenState> _dashboardKey =
      GlobalKey<OwnerDashboardScreenState>();

  late final List<Widget> _screens = [
    OwnerDashboardScreen(
      key: _dashboardKey,
      onInitialLoadComplete: () {
        if (!mounted) return;
        setState(() => _ownerReady = true);
      },
    ),
    const OwnerOrdersScreen(),
    const OwnerInventoryScreen(),
    const OwnerReportsScreen(),
  ];

  void _onDestinationSelected(int i) {
    final wasOnDashboard = _index == 0;
    setState(() => _index = i);
    if (i == 0 && !wasOnDashboard) {
      _dashboardKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.ownerTheme,
      child: ElevatorLoadingGate(
        loading: !_ownerReady,
        child: Scaffold(
          body: IndexedStack(index: _index, children: _screens),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _onDestinationSelected,
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
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Reportes',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
