import 'package:flutter/foundation.dart';
import '../../data/repositories/profile_repository.dart';
import '../constants/order_constants.dart';

/// Rol en caché para redirección de [GoRouter] y protección de rutas.
class AuthNotifier extends ChangeNotifier {
  final _profileRepo = ProfileRepository();

  String? _role;
  bool _loading = false;

  String? get role => _role;
  bool get isOwner => _role == AppRole.owner.value;
  bool get isClient => _role == AppRole.client.value;
  bool get isAdmin => _role == AppRole.admin.value;
  bool get loading => _loading;

  Future<void> loadRole() async {
    _loading = true;
    notifyListeners();
    _role = await _profileRepo.resolveRole();
    _loading = false;
    notifyListeners();
  }

  /// Espera a que el rol esté disponible (evita redirecciones prematuras en web).
  Future<void> ensureRoleLoaded() async {
    if (_role != null) return;
    if (_loading) {
      while (_loading) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
      return;
    }
    await loadRole();
  }

  void clear() {
    _role = null;
    _loading = false;
    notifyListeners();
  }
}
