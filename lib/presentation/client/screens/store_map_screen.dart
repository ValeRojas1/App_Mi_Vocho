import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/store_info.dart';
import '../../../data/models/store_settings_model.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../data/services/directions_service.dart';
import '../../../data/services/location_service.dart';

/// Mapa integrado con OpenStreetMap + ruta OSRM (sin API Key de Google).
class StoreMapScreen extends StatefulWidget {
  final bool emphasizePickup;

  const StoreMapScreen({super.key, this.emphasizePickup = false});

  @override
  State<StoreMapScreen> createState() => _StoreMapScreenState();
}

class _StoreMapScreenState extends State<StoreMapScreen> {
  final _storeRepo = StoreRepository();
  final _location = LocationService();
  final _directions = DirectionsService();
  final _mapController = MapController();

  StoreSettingsModel? _store;
  Position? _userPosition;
  RouteInfo? _route;
  Timer? _refreshTimer;
  bool _loading = true;
  String? _error;
  bool _loadingRoute = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final store = await _storeRepo.getStoreSettings();
      final pos = await _location.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _store = store;
        _userPosition = pos;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds();
        if (pos != null) _loadRoute();
      });
      _startPeriodicRefresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _loadingRoute = true);
    
    final pos = await _location.getCurrentPosition();
    if (!mounted) return;
    
    if (pos != null) {
      setState(() => _userPosition = pos);
      await _loadRoute();
    } else {
      setState(() => _loadingRoute = false);
    }
  }

  Future<void> _loadRoute() async {
    final store = _store;
    final user = _userPosition;
    if (store == null || user == null) return;

    setState(() => _loadingRoute = true);
    final route = await _directions.fetchDrivingRoute(
      originLat: user.latitude,
      originLng: user.longitude,
      destLat: store.latitude,
      destLng: store.longitude,
    );

    if (!mounted) return;
    setState(() {
      _route = route;
      _loadingRoute = false;
    });
    _fitBounds();
  }

  void _fitBounds() {
    final store = _store;
    if (store == null) return;

    final points = <LatLng>[LatLng(store.latitude, store.longitude)];
    final user = _userPosition;
    if (user != null) {
      points.add(LatLng(user.latitude, user.longitude));
    }
    if (_route != null && _route!.points.isNotEmpty) {
      points.addAll(_route!.points);
    }

    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  List<Marker> _buildMarkers() {
    final store = _store;
    if (store == null) return [];

    final markers = <Marker>[
      Marker(
        point: LatLng(store.latitude, store.longitude),
        width: 48,
        height: 48,
        child: const Icon(Icons.storefront, color: Color(0xFF003087), size: 40),
      ),
    ];

    final user = _userPosition;
    if (user != null) {
      markers.add(
        Marker(
          point: LatLng(user.latitude, user.longitude),
          width: 40,
          height: 40,
          child: Icon(
            Icons.person_pin_circle,
            color: Colors.green.shade700,
            size: 36,
          ),
        ),
      );
    }
    return markers;
  }

  Future<void> _openGoogleMaps() async {
    final store = _store;
    final user = _userPosition;
    if (store == null) return;
    if (user == null) {
      _snack('Activa el GPS para iniciar la ruta desde tu posición.');
      return;
    }
    final ok = await _directions.openGoogleMapsNavigation(
      originLat: user.latitude,
      originLng: user.longitude,
      destLat: store.latitude,
      destLng: store.longitude,
    );
    if (!ok) _snack('No se pudo abrir Google Maps.');
  }

  Future<void> _openWaze() async {
    final store = _store;
    if (store == null) return;
    final ok = await _directions.openWazeNavigation(
      destLat: store.latitude,
      destLng: store.longitude,
    );
    if (!ok) _snack('No se pudo abrir Waze.');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final store = _store;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubicación de la tienda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Centrar mapa',
            onPressed: _fitBounds,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
              children: [
                if (widget.emphasizePickup)
                  Container(
                    width: double.infinity,
                    color: Colors.teal.shade50,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.storefront, color: Colors.teal.shade800),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Pedido con recojo en tienda. Sigue la ruta azul en el mapa.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(store!.latitude, store.longitude),
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.tucasa.mi_vocho',
                      ),
                      if (_route != null && _route!.points.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _route!.points,
                              color: const Color(0xFF003087),
                              strokeWidth: 5,
                            ),
                          ],
                        ),
                      MarkerLayer(markers: _buildMarkers()),
                    ],
                  ),
                ),
                _buildInfoPanel(primary),
              ],
            ),
    );
  }

  Widget _buildInfoPanel(Color primary) {
    final store = _store!;
    final user = _userPosition;
    double? distM;
    if (user != null) {
      distM = _location.distanceMeters(
        fromLat: user.latitude,
        fromLng: user.longitude,
        toLat: store.latitude,
        toLng: store.longitude,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            StoreInfo.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dirección: ${StoreInfo.address}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Horario de atención: ${StoreInfo.openingHours}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'Mapa gratuito · OpenStreetMap',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 10),
          if (_loadingRoute)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Calculando ruta...', style: TextStyle(fontSize: 12)),
              ],
            )
          else if (user != null && _route != null)
            Text(
              'Ruta en auto: ${_route!.distanceKm} · ${_route!.durationText}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            )
          else if (user != null && distM != null)
            Text(
              'Distancia aproximada: ${(distM / 1000).toStringAsFixed(1)} km',
              style: const TextStyle(fontWeight: FontWeight.w600),
            )
          else
            const Text(
              'Activa ubicación para ver tu posición y la ruta.',
              style: TextStyle(fontSize: 12),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: OutlinedButton.icon(
                  onPressed: _loadingRoute ? null : _refreshData,
                  icon: const Icon(Icons.route, size: 16),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Actualizar', maxLines: 1),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: OutlinedButton.icon(
                  onPressed: _openGoogleMaps,
                  icon: const Icon(Icons.map, size: 16),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Maps', maxLines: 1),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: ElevatedButton.icon(
                  onPressed: _openWaze,
                  icon: const Icon(Icons.navigation, size: 16),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Waze', maxLines: 1),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
