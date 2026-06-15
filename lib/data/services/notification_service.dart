import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/order_constants.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();

  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  RealtimeChannel? _channel;

  final Map<String, String> _lastStatusByOrder = {};

  bool _initialized = false;

  String? _subscribedUserId;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (!_isMobile || _initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);

    const channel = AndroidNotificationChannel(
      'order_updates',
      'Actualizaciones de pedidos',
      description: 'Avisos cuando cambia el estado de tu pedido',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<bool> areNotificationsEnabled() async {
    if (!_isMobile) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }

    return true;
  }

  Future<bool> requestPermissionAndSubscribe() async {
    if (!_isMobile) return false;

    await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      if (!status.isGranted) return false;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId != null) {
      await subscribeToMyOrders(userId);
    }

    return true;
  }

  Future<void> subscribeToMyOrders(String userId) async {
    if (!_isMobile) return;

    await initialize();

    if (_subscribedUserId == userId && _channel != null) return;

    await _seedOrderStatuses(userId);

    _channel?.unsubscribe();

    _subscribedUserId = userId;

    _channel = Supabase.instance.client
        .channel('client-orders-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'client_id',
            value: userId,
          ),
          callback: (payload) async {
            final newRow = payload.newRecord;
            final orderId = newRow['id'] as String?;
            final status = newRow['status'] as String?;
            if (orderId == null || status == null) return;

            final previous = _lastStatusByOrder[orderId];
            _lastStatusByOrder[orderId] = status;

            if (previous != null && previous != status) {
              await _showOrderStatusNotification(orderId, status);
            }
          },
        )
        .subscribe();
  }

  Future<void> unsubscribe() async {
    _channel?.unsubscribe();
    _channel = null;
    _subscribedUserId = null;
  }

  Future<void> _seedOrderStatuses(String userId) async {
    final rows = await Supabase.instance.client
        .from('orders')
        .select('id, status')
        .eq('client_id', userId);

    for (final row in rows as List<dynamic>) {
      final id = row['id'] as String?;
      final status = row['status'] as String?;
      if (id != null && status != null) {
        _lastStatusByOrder[id] = status;
      }
    }
  }

  Future<void> _showOrderStatusNotification(
    String orderId,
    String status,
  ) async {
    if (!_isMobile) return;

    final parsed = OrderStatus.fromValue(status);

    final shortId = orderId.length >= 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId;

    final title = 'Pedido #$shortId actualizado';

    final body = parsed?.clientLabel ?? status;

    const android = AndroidNotificationDetails(
      'order_updates',
      'Actualizaciones de pedidos',
      channelDescription: 'Avisos cuando cambia el estado de tu pedido',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _plugin.show(
      orderId.hashCode,
      title,
      body,
      const NotificationDetails(android: android),
    );
  }
}
