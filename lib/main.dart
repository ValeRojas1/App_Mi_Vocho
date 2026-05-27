import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xlggqnrrcndbvxrqqhgs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhsZ2dxbnJyY25kYnZ4cnFxaGdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MzY1MDAsImV4cCI6MjA5NTQxMjUwMH0.t4dFrP8mR30po-7NxTL8sbITPfGYnQlzgZhG-v2nPqY',
  );

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
      themeMode: ThemeMode.light, // Forzar tema claro para evitar el fondo negro del modo oscuro del dispositivo
      routerConfig: AppRouter.router,
    );
  }
}