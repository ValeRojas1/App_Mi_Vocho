import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ruta calculada con OSRM (OpenStreetMap) — gratuito, sin API Key de Google.
class RouteInfo {
  final List<LatLng> points;
  final double distanceMeters;
  final int durationSeconds;

  const RouteInfo({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  String get distanceKm => '${(distanceMeters / 1000).toStringAsFixed(1)} km';

  String get durationText {
    final min = (durationSeconds / 60).ceil();
    return min < 60 ? '$min min' : '${min ~/ 60} h ${min % 60} min';
  }
}

class DirectionsService {
  static const _osrmBase = 'https://router.project-osrm.org';

  /// Ruta en auto optimizada (servidor público OSRM).
  Future<RouteInfo?> fetchDrivingRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final url = Uri.parse(
        '$_osrmBase/route/v1/driving/'
        '$originLng,$originLat;$destLng,$destLat'
        '?overview=full&geometries=polyline',
      );
      final res = await http.get(url);
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final dist = (route['distance'] as num?)?.toDouble() ?? 0;
      final dur = (route['duration'] as num?)?.toDouble() ?? 0;
      final encoded = route['geometry'] as String? ?? '';

      // OSRM calcula el tiempo en condiciones ideales (sin tráfico, semáforos, etc.)
      // Para tráfico más pesado, aplicamos un factor de congestión mayor (+60%)
      // y añadimos un margen de 4 minutos (240 seg) para cruces y aparcamiento.
      final int realisticDuration = (dur * 1.6).round() + 240;

      return RouteInfo(
        points: _decodePolyline(encoded),
        distanceMeters: dist,
        durationSeconds: realisticDuration,
      );
    } catch (_) {
      return null;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  Future<bool> openGoogleMapsNavigation({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$originLat,$originLng'
      '&destination=$destLat,$destLng'
      '&travelmode=driving',
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<bool> openWazeNavigation({
    required double destLat,
    required double destLng,
  }) async {
    final uri = Uri.parse(
      'https://waze.com/ul?ll=$destLat,$destLng&navigate=yes',
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
