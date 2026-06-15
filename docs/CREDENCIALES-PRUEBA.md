# Credenciales de prueba — Mi Vocho

Entorno Supabase: **Mi_Vocho** (`xlggqnrrcndbvxrqqhgs`)

## Conexión (ya configurada en la app)

| Parámetro | Valor |
|-----------|-------|
| URL | `https://xlggqnrrcndbvxrqqhgs.supabase.co` |
| Anon key | Ver `lib/core/config/supabase_config.dart` |

## Usuarios de prueba

Contraseña común para todos: **`MiVocho2026!`**

| Rol | Correo | Uso |
|-----|--------|-----|
| **Administrador** | `admin@mi-vocho.test` | Panel web `/admin` — usuarios y estadísticas |
| **Dueña** | `duena@mi-vocho.test` | Vista dueña `/owner` |
| **Cliente** | `cliente@mi-vocho.test` | Vista cliente `/client` |
| **Cliente (legacy)** | `cliente1@test.com` | Cliente alternativo (misma contraseña) |

> También existe `duena@lavolkswagen.com` (dueña legada en producción). Usa las cuentas `@mi-vocho.test` para pruebas controladas.

## Ejecutar versión web

```bash
cd D:/Flutter/mi_vocho
flutter run -d chrome
```

O compilar para despliegue:

```bash
flutter build web
```

Los archivos quedan en `build/web/`.

## Migraciones aplicadas en Supabase

- `phase0_profiles_rls_create_order`
- `phase0_security_hardening`
- `phase2_phase3_store_payment`
- `admin_role_and_user_management` ← rol admin + funciones de gestión
- `add_shipping_agency` ← encomienda, promociones, storage

## Verificación rápida

1. Abrir la app web en Chrome.
2. Iniciar sesión con `admin@mi-vocho.test` / `MiVocho2026!`.
3. Debe redirigir a `/admin` con pestañas **Usuarios** y **Estadísticas**.
4. Probar `cliente@mi-vocho.test` → vista catálogo cliente.
5. Probar `duena@mi-vocho.test` → dashboard dueña.
