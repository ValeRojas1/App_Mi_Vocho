import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../presentation/owner/screens/owner_shell.dart';
import '../../presentation/client/screens/client_shell.dart';
import '../../presentation/shared/screens/login_screen.dart';

const _ownerEmail = 'duena@lavolkswagen.com';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLogin = state.matchedLocation == '/login';

      // Si no hay sesión y no está en login → manda al login
      if (session == null) return isLogin ? null : '/login';

      // Si ya hay sesión y está en login → redirige según rol
      if (isLogin) {
        final email = session.user.email ?? '';
        return email == _ownerEmail ? '/owner' : '/client';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
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