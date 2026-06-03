/// Credenciales de Supabase vía `--dart-define` en builds de producción.
/// Sin defines, se usan los valores del proyecto (desarrollo).
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xlggqnrrcndbvxrqqhgs.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhsZ2dxbnJyY25kYnZ4cnFxaGdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MzY1MDAsImV4cCI6MjA5NTQxMjUwMH0.t4dFrP8mR30po-7NxTL8sbITPfGYnQlzgZhG-v2nPqY',
  );
}
