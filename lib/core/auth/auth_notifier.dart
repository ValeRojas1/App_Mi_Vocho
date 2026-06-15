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

  void clear() {
    _role = null;
    _loading = false;
    notifyListeners();
  }
}
