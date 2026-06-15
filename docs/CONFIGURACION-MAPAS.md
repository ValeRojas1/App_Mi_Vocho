# Mapas y rutas en Mi Vocho

## Sin API Key de Google (configuración actual)

La app usa tecnología **gratuita y de código abierto**:

| Componente | Servicio | ¿Pago? |
|------------|----------|--------|
| Mapa dentro de la app | [OpenStreetMap](https://www.openstreetmap.org/) vía `flutter_map` | No |
| Ruta optimizada en el mapa | [OSRM](https://project-osrm.org/) (servidor público) | No |
| Tu ubicación en tiempo real | GPS del teléfono (`geolocator`) | No |
| Navegación turn-by-turn externa | Google Maps o Waze (apps del teléfono) | No |

Solo necesitas las **coordenadas** de la tienda en Supabase → tabla `store_settings` (`latitude`, `longitude`).

## Editar ubicación de la tienda

En el panel de Supabase, tabla `store_settings`, actualiza:

- `address` — dirección legible
- `latitude` / `longitude` — coordenadas exactas (puedes copiarlas desde Google Maps → clic derecho en el lugar)

## Botones opcionales

- **Maps** — abre Google Maps en el teléfono con ruta desde tu posición (no requiere API Key en la app).
- **Waze** — abre Waze hacia la tienda.

## Nota sobre Google Cloud

**No hace falta** crear cuenta en Google Cloud ni pagar para usar el mapa integrado de Mi Vocho.

Google Maps API solo sería necesaria si en el futuro quisieras el mapa *oficial* de Google embebido; por ahora no está configurado.

## Requisitos en el teléfono

- Permiso de **ubicación** (para ver tu posición y calcular la ruta).
- Conexión a **internet** (para cargar los tiles del mapa y la ruta OSRM).
