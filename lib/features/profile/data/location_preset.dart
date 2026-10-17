import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationPreset {
  final String id;
  final String name;
  final String region;
  final double latitude;
  final double longitude;
  final bool isGps;

  const LocationPreset({
    required this.id,
    required this.name,
    required this.region,
    required this.latitude,
    required this.longitude,
    this.isGps = false,
  });

  String get displayName => '$name, $region';

  static const List<LocationPreset> defaultPresets = [
    LocationPreset(
      id: 'aceh_banda',
      name: 'Banda Aceh',
      region: 'Aceh',
      latitude: 5.5483,
      longitude: 95.3238,
    ),
    LocationPreset(
      id: 'aceh_meulaboh',
      name: 'Meulaboh',
      region: 'Aceh Barat',
      latitude: 4.1449,
      longitude: 96.1265,
    ),
    LocationPreset(
      id: 'aceh_takengon',
      name: 'Takengon',
      region: 'Aceh Tengah',
      latitude: 4.6297,
      longitude: 96.8458,
    ),
    LocationPreset(
      id: 'aceh_langsa',
      name: 'Langsa',
      region: 'Aceh Timur',
      latitude: 4.7164,
      longitude: 97.9683,
    ),
    LocationPreset(
      id: 'riau_pekanbaru',
      name: 'Pekanbaru',
      region: 'Riau',
      latitude: 0.5071,
      longitude: 101.4478,
    ),
    LocationPreset(
      id: 'sumsel_palembang',
      name: 'Palembang',
      region: 'Sumatera Selatan',
      latitude: -2.9909,
      longitude: 104.7565,
    ),
    LocationPreset(
      id: 'kalbar_pontianak',
      name: 'Pontianak',
      region: 'Kalimantan Barat',
      latitude: -0.0263,
      longitude: 109.3425,
    ),
    LocationPreset(
      id: 'dki_jakarta',
      name: 'Jakarta Pusat',
      region: 'DKI Jakarta',
      latitude: -6.1818,
      longitude: 106.8223,
    ),
    LocationPreset(
      id: 'kalteng_palangkaraya',
      name: 'Palangkaraya',
      region: 'Kalimantan Tengah',
      latitude: -2.2161,
      longitude: 113.9135,
    ),
    LocationPreset(
      id: 'sulsel_makassar',
      name: 'Makassar',
      region: 'Sulawesi Selatan',
      latitude: -5.1477,
      longitude: 119.4327,
    ),
  ];

  static LocationPreset? findById(String id) {
    try {
      return defaultPresets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ── Selected Location ─────────────────────────────────────────────────────

class SelectedLocationNotifier extends Notifier<LocationPreset> {
  static const String _prefKey = 'selected_location_id';

  @override
  LocationPreset build() {
    _loadPersistedLocation();
    return LocationPreset.defaultPresets.first;
  }

  Future<void> _loadPersistedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_prefKey);
      if (id != null) {
        final preset = LocationPreset.findById(id);
        if (preset != null) {
          state = preset;
        }
      }
    } catch (_) {}
  }

  void select(LocationPreset preset) {
    state = preset;
    _persist(preset.id);
    _invalidateDataProviders();
  }

  void selectGps(double lat, double lon) {
    state = LocationPreset(
      id: 'gps_live',
      name: 'GPS',
      region: '${lat.toStringAsFixed(4)}°, ${lon.toStringAsFixed(4)}°',
      latitude: lat,
      longitude: lon,
      isGps: true,
    );
    _persist('gps_live');
    _invalidateDataProviders();
  }

  void _persist(String id) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefKey, id);
    });
  }

  /// Invalidates all data providers so they re-fetch for the new location.
  void _invalidateDataProviders() {
    // Providers watching selectedLocationProvider will auto-rebuild.
    // FutureProviders need explicit invalidation if they don't watch the location.
  }
}

final selectedLocationProvider =
    NotifierProvider<SelectedLocationNotifier, LocationPreset>(
  SelectedLocationNotifier.new,
);

// ── Alert Radius ─────────────────────────────────────────────────────────

class AlertRadiusNotifier extends Notifier<double> {
  static const String _prefKey = 'alert_radius_km';

  @override
  double build() {
    _loadPersistedRadius();
    return 50.0;
  }

  Future<void> _loadPersistedRadius() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getDouble(_prefKey);
      if (val != null && [25.0, 50.0, 100.0, 200.0].contains(val)) {
        state = val;
      }
    } catch (_) {}
  }

  void setRadius(double km) {
    state = km;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setDouble(_prefKey, km);
    });
  }
}

final alertRadiusProvider =
    NotifierProvider<AlertRadiusNotifier, double>(AlertRadiusNotifier.new);
