import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_service.dart';

/// Cierra la sesión del cliente solo si la app fue terminada desde segundo plano
/// (p. ej. deslizar en recientes), no al minimizarla y volver a abrirla.
class ClientSessionLifecycleService with WidgetsBindingObserver {
  static const _wasBackgroundedKey = 'client_session_was_backgrounded';

  static final ClientSessionLifecycleService instance =
      ClientSessionLifecycleService._();

  ClientSessionLifecycleService._();

  bool _observerAttached = false;

  bool get _enabled =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Debe llamarse al iniciar [ClientShell]. Si la app se cerró por completo
  /// estando en segundo plano, cierra la sesión antes de continuar.
  Future<bool> handleColdStart() async {
    if (!_enabled) return true;

    final prefs = await SharedPreferences.getInstance();
    final wasBackgrounded = prefs.getBool(_wasBackgroundedKey) ?? false;
    await prefs.setBool(_wasBackgroundedKey, false);

    if (!wasBackgrounded) return true;

    await NotificationService.instance.unsubscribe();
    await Supabase.instance.client.auth.signOut();
    return false;
  }

  void attach() {
    if (!_enabled || _observerAttached) return;
    WidgetsBinding.instance.addObserver(this);
    _observerAttached = true;
  }

  void detach() {
    if (!_observerAttached) return;
    WidgetsBinding.instance.removeObserver(this);
    _observerAttached = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _markBackgrounded(true);
      case AppLifecycleState.resumed:
        _markBackgrounded(false);
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _markBackgrounded(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wasBackgroundedKey, value);
  }
}
