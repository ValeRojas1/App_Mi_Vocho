import '../../core/constants/store_info.dart';

class StoreSettingsModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? openingHours;

  const StoreSettingsModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.openingHours,
  });

  factory StoreSettingsModel.fromJson(Map<String, dynamic> json) =>
      StoreSettingsModel(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        city: json['city'] as String? ?? 'Huancayo',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        phone: json['phone'] as String?,
        openingHours: json['opening_hours'] as String?,
      );

  /// Respaldo si Supabase no responde (La Casa del Volkswagen — Huancayo).
  static const fallback = StoreSettingsModel(
    id: 'default',
    name: StoreInfo.name,
    address: StoreInfo.address,
    city: StoreInfo.fullCity,
    latitude: -12.0684,
    longitude: -75.2110,
    phone: null,
    openingHours: StoreInfo.openingHours,
  );
}
