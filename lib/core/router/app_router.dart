import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_notifier.dart';
import '../constants/order_constants.dart';
import '../../presentation/admin/screens/admin_shell.dart';
import '../../presentation/owner/screens/owner_shell.dart';
import '../../presentation/client/screens/client_shell.dart';
import '../../presentation/shared/screens/login_screen.dart';

class AppRouter {
  static String _homeForRole(String role) {
    if (kIsWeb) {
      return role == AppRole.admin.value ? '/admin' : '/login';
    }
    return switch (AppRole.fromValue(role)) {
      AppRole.admin => '/admin',
      AppRole.owner => '/owner',
      AppRole.client => '/client',
    };
  }

  static GoRouter create(AuthNotifier authNotifier) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authNotifier,
      redirect: (context, state) async {
        final session = Supabase.instance.client.auth.currentSession;
        final loc = state.matchedLocation;
        final isLogin = loc == '/login';

        if (session == null) {
          return isLogin ? null : '/login';
        }

        if (authNotifier.role == null && !authNotifier.loading) {
          await authNotifier.ensureRoleLoaded();
        } else if (authNotifier.loading) {
          return null;
        }

        final role =
            authNotifier.role ??
            (session.user.email == kLegacyOwnerEmail
                ? AppRole.owner.value
                : AppRole.client.value);

        if (kIsWeb && !isLogin && loc != '/admin') {
          return role == AppRole.admin.value ? '/admin' : '/login';
        }

        if (isLogin) {
          return _homeForRole(role);
        }

        if (loc.startsWith('/admin') && role != AppRole.admin.value) {
          return _homeForRole(role);
        }
        if (loc.startsWith('/owner') && role != AppRole.owner.value) {
          return _homeForRole(role);
        }
        if (loc.startsWith('/client') &&
            (role == AppRole.owner.value || role == AppRole.admin.value)) {
          return _homeForRole(role);
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => LoginScreen(authNotifier: authNotifier),
        ),
        GoRoute(path: '/admin', builder: (_, __) => const AdminShell()),
        GoRoute(path: '/owner', builder: (_, __) => const OwnerShell()),
        GoRoute(path: '/client', builder: (_, __) => const ClientShell()),
      ],
    );
  }
}
