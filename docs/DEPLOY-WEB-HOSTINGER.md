# Despliegue web en Hostinger (panel administrador)

## 1. Compilar la app

Desde la raíz del proyecto:

```bash
flutter build web --release
```

Los archivos a subir están en **`build/web/`** (no subas la carpeta `build` completa, solo su contenido).

## 2. Subir a Hostinger

1. Entra al **Administrador de archivos** o usa **FTP**.
2. Abre la carpeta pública del dominio (normalmente `public_html`).
3. Sube **todo el contenido** de `build/web/`:
   - `index.html`
   - `flutter_bootstrap.js`, `main.dart.js`, `flutter.js`, etc.
   - carpetas `assets/`, `icons/`, `canvaskit/` (si existen)
   - **`.htaccess`** (incluido en `web/.htaccess` del repo; Flutter lo copia al build si está en `web/`)

> Si el sitio va en un subdirectorio (ej. `tudominio.com/admin/`), compila con:
> `flutter build web --release --base-href /admin/`

## 3. Supabase (obligatorio)

En [Supabase Dashboard](https://supabase.com/dashboard) → tu proyecto **Mi_Vocho** → **Authentication** → **URL Configuration**:

| Campo | Valor |
|-------|--------|
| **Site URL** | `https://tu-dominio.com` (URL real del host) |
| **Redirect URLs** | Añadir `https://tu-dominio.com/**` y `https://www.tu-dominio.com/**` |

Sin esto, la sesión puede cerrarse al iniciar sesión en producción.

## 4. Usuario administrador

Usar cuenta con rol `admin`, por ejemplo:

- Correo: `admin@mi-vocho.test`
- Contraseña: `MiVocho2026!`

(Ver `docs/CREDENCIALES-PRUEBA.md`.)

## 5. Comportamiento en web

- La versión web **solo permite acceso a administradores**.
- Clientes y dueña deben usar la **app móvil**.
- Rutas válidas: `/login`, `/admin`.

## 6. Problemas frecuentes

| Síntoma | Solución |
|---------|----------|
| Pantalla en blanco al recargar `/admin` | Verificar que `.htaccess` esté en el host |
| Vuelve al login al entrar | Configurar Site URL y Redirect URLs en Supabase |
| "No autorizado" en usuarios | Aplicar migración `admin_role_and_user_management` en Supabase |
| Pestaña se cierra / error al entrar | Actualizar a la última versión del repo (fix layout admin web) |

## 7. Plan Hostinger Plus

Es suficiente para el panel admin (HTML/JS estático). No requiere Node ni PHP para la app Flutter web; solo servir archivos estáticos con Apache.
