import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_notifier.dart';
import '../constants/order_constants.dart';
import '../../presentation/owner/screens/owner_shell.dart';
import '../../presentation/client/screens/client_shell.dart';
import '../../presentation/shared/screens/login_screen.dart';

class AppRouter {
  static GoRouter create(AuthNotifier authNotifier) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authNotifier,
      redirect: (context, state) {
        final session = Supabase.instance.client.auth.currentSession;
        final loc = state.matchedLocation;
        final isLogin = loc == '/login';

        if (session == null) {
          return isLogin ? null : '/login';
        }

        if (authNotifier.loading && authNotifier.role == null) {
          return isLogin ? null : null;
        }

        final role = authNotifier.role ??
            (session.user.email == kLegacyOwnerEmail
                ? AppRole.owner.value
                : AppRole.client.value);

        if (isLogin) {
          return role == AppRole.owner.value ? '/owner' : '/client';
        }

        if (loc.startsWith('/owner') && role != AppRole.owner.value) {
          return '/client';
        }
        if (loc.startsWith('/client') && role == AppRole.owner.value) {
          return '/owner';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => LoginScreen(authNotifier: authNotifier),
        ),
        GoRoute(
          path: '/owner',
          builder: (_, __) => const OwnerShell(),
        ),
        GoRoute(
          path: '/client',
          builder: (_, __) => const ClientShell(),
        ),
      ],
    );
  }
}
