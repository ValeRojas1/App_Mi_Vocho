import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/auth/auth_notifier.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/utils/app_formatters.dart';
import 'data/services/notification_service.dart';

final authNotifier = AuthNotifier();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.session != null) {
      authNotifier.loadRole();
    } else {
      authNotifier.clear();
    }
  });

  if (Supabase.instance.client.auth.currentSession != null) {
    await authNotifier.loadRole();
  }

  await AppFormatters.ensureInitialized();
  if (!kIsWeb) {
    await NotificationService.instance.initialize();
  }

  runApp(const MiVochoApp());
}

class MiVochoApp extends StatelessWidget {
  const MiVochoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'La Casa del Volkswagen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.create(authNotifier),
    );
  }
}
