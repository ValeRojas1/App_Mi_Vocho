import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/services/cart_storage_service.dart';
import '../../../data/services/client_session_lifecycle_service.dart';
import '../../../data/services/notification_service.dart';
import '../../shared/widgets/elevator_loading_gate.dart';
import 'client_catalog_screen.dart';
import 'client_orders_screen.dart';
import 'client_cart_screen.dart';
import 'client_store_screen.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});
  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;
  final _cartStorage = CartStorageService();
  final _productRepo = ProductRepository();
  final List<Map<String, dynamic>> _cart = [];
  bool _cartReady = false;
  bool _catalogReady = false;
  bool _syncingCartStock = false;

  final GlobalKey<ClientCatalogScreenState> _catalogKey =
      GlobalKey<ClientCatalogScreenState>();
  final GlobalKey<ClientOrdersScreenState> _ordersKey =
      GlobalKey<ClientOrdersScreenState>();

  @override
  void initState() {
    super.initState();
    _initClientSession();
  }

  @override
  void dispose() {
    ClientSessionLifecycleService.instance.detach();
    NotificationService.instance.unsubscribe();
    super.dispose();
  }

  Future<void> _initClientSession() async {
    final sessionActive =
        await ClientSessionLifecycleService.instance.handleColdStart();
    if (!mounted) return;

    if (!sessionActive ||
        Supabase.instance.client.auth.currentSession == null) {
      setState(() {
        _cartReady = true;
        _catalogReady = true;
      });
      return;
    }

    ClientSessionLifecycleService.instance.attach();
    _loadCart();
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    await NotificationService.instance.initialize();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    if (await NotificationService.instance.areNotificationsEnabled()) {
      await NotificationService.instance.subscribeToMyOrders(userId);
    }
  }

  Future<void> _loadCart() async {
    final saved = await _cartStorage.load();
    if (!mounted) return;
    setState(() {
      _cart
        ..clear()
        ..addAll(saved);
    });
    await syncCartStock();
    if (!mounted) return;
    setState(() => _cartReady = true);
  }

  Future<void> _persistCart() async {
    await _cartStorage.save(_cart);
  }

  int get _cartUnits =>
      _cart.fold<int>(0, (sum, e) => sum + (e['quantity'] as int));

  /// Actualiza stock, precio y cantidades del carrito desde el servidor.
  Future<void> syncCartStock({bool notifyChanges = false}) async {
    if (_cart.isEmpty || _syncingCartStock) return;
    _syncingCartStock = true;
    try {
      final ids = _cart.map((e) => e['product_id'] as String).toSet().toList();
      final products = await _productRepo.getProductsByIds(ids);
      final byId = {for (final p in products) p.id: p};

      final removedNames = <String>[];
      final adjustedNames = <String>[];

      if (!mounted) return;
      setState(() {
        _cart.removeWhere((item) {
          final id = item['product_id'] as String;
          final product = byId[id];
          final name = item['name'] as String;
          if (product == null || !product.isActive || product.stock <= 0) {
            removedNames.add(name);
            return true;
          }
          item['stock'] = product.stock;
          item['unit_price'] = product.price;
          item['name'] = product.name;
          final qty = item['quantity'] as int;
          if (qty > product.stock) {
            item['quantity'] = product.stock;
            adjustedNames.add(product.name);
          }
          return false;
        });
      });
      await _persistCart();

      if (!notifyChanges || !mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (removedNames.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              removedNames.length == 1
                  ? '${removedNames.first} ya no está disponible y se quitó del carrito.'
                  : 'Algunos repuestos ya no están disponibles y se quitaron del carrito.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (adjustedNames.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              adjustedNames.length == 1
                  ? 'La cantidad de ${adjustedNames.first} se ajustó al stock disponible.'
                  : 'Algunas cantidades se ajustaron al stock disponible.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      // Sin conexión: se mantiene el carrito local hasta el próximo intento.
    } finally {
      _syncingCartStock = false;
    }
  }

  bool addToCart(Map<String, dynamic> item) {
    final stock = item['stock'] as int;
    final productId = item['product_id'] as String;
    final idx = _cart.indexWhere((e) => e['product_id'] == productId);
    final currentQty = idx >= 0 ? _cart[idx]['quantity'] as int : 0;

    if (currentQty >= stock) {
      return false;
    }

    setState(() {
      if (idx >= 0) {
        _cart[idx]['quantity'] = currentQty + 1;
        _cart[idx]['stock'] = stock;
        _cart[idx]['unit_price'] = item['unit_price'];
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
    setState(() => _index = 2);
    _ordersKey.currentState?.refresh();
  }

  void _onTabSelected(int i) {
    if (i == _index) return;
    final previous = _index;
    setState(() => _index = i);

    if (i == 0 || previous == 0) {
      _catalogKey.currentState?.refresh();
    }
    if (i == 0) {
      syncCartStock();
    }
    if (i == 1) {
      syncCartStock(notifyChanges: true);
    }
    if (i == 2 || previous == 2) {
      _ordersKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.clientTheme,
      child: ElevatorLoadingGate(
        loading: !(_cartReady && _catalogReady),
        child: Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              ClientCatalogScreen(
                key: _catalogKey,
                onAddToCart: addToCart,
                onInitialLoadComplete: () {
                  if (!mounted) return;
                  setState(() => _catalogReady = true);
                },
              ),
              ClientCartScreen(
                cart: _cart,
                isActive: _index == 1,
                onCartUpdated: _onCartUpdated,
                onClearAll: clearCart,
                onCheckoutSuccess: _onCheckoutSuccess,
                onRefreshStock: () => syncCartStock(notifyChanges: true),
              ),
              ClientOrdersScreen(key: _ordersKey),
              const ClientStoreScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _onTabSelected,
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
                label: 'Pedidos',
              ),
              const NavigationDestination(
                icon: Icon(Icons.location_on_outlined),
                selectedIcon: Icon(Icons.location_on),
                label: 'Tienda',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
