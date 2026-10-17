import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../profile/data/location_preset.dart';
import 'alert_model.dart';

class AlertNotifier extends Notifier<List<AlertModel>> {
  @override
  List<AlertModel> build() {
    // Kick off a live fetch immediately after first build.
    // Errors are swallowed; demo alerts remain as fallback.
    Future.microtask(() => _fetchLive());
    return _demoAlerts();
  }

  // ── Public mutations ──────────────────────────────────────────────

  void markAsRead(String id) {
    state = [
      for (final alert in state)
        if (alert.id == id) alert.copyWith(isRead: true) else alert,
    ];
  }

  void markAllAsRead() {
    state = [for (final alert in state) alert.copyWith(isRead: true)];
  }

  void addAlert(AlertModel alert) {
    if (state.any((a) => a.id == alert.id)) return;
    state = [alert, ...state];
  }

  /// Called from location-change listeners to refresh alerts for a new area.
  Future<void> refreshForLocation(double lat, double lon) async {
    await _fetchLive(lat: lat, lon: lon);
  }

  // ── Internal ──────────────────────────────────────────────────────

  Future<void> _fetchLive({double lat = 5.5483, double lon = 95.3238}) async {
    try {
      final location = ref.read(selectedLocationProvider);
      final effectiveLat = lat != 5.5483 ? lat : location.latitude;
      final effectiveLon = lon != 95.3238 ? lon : location.longitude;

      final apiClient = ref.read(apiClientProvider);
      final dynamic response = await apiClient.get(
        '/alerts',
        queryParams: {
          'latitude': effectiveLat.toStringAsFixed(4),
          'longitude': effectiveLon.toStringAsFixed(4),
        },
      );

      if (response is List && response.isNotEmpty) {
        final readIds = state.where((a) => a.isRead).map((a) => a.id).toSet();
        final live = response.map((item) {
          final m = item as Map<String, dynamic>;
          var type = AlertType.systemNotice;
          if (m['type'] == 'hotspotThermal') type = AlertType.hotspotThermal;
          if (m['type'] == 'airQualityDegraded') {
            type = AlertType.airQualityDegraded;
          }

          var sev = AlertSeverity.info;
          if (m['severity'] == 'critical') sev = AlertSeverity.critical;
          if (m['severity'] == 'warning') sev = AlertSeverity.warning;

          final id =
              m['id']?.toString() ?? 'ALT-${DateTime.now().millisecondsSinceEpoch}';
          return AlertModel(
            id: id,
            type: type,
            severity: sev,
            title: m['title']?.toString() ?? 'Alert',
            summary: m['summary']?.toString() ?? '',
            locationName: m['locationName']?.toString() ?? 'Regional',
            distanceKm: (m['distanceKm'] as num?)?.toDouble(),
            eventTime:
                DateTime.tryParse(m['eventTime']?.toString() ?? '') ??
                DateTime.now(),
            source: m['source']?.toString() ?? 'FIREGUARD Gateway',
            isRead: readIds.contains(id),
          );
        }).toList();

        state = live;
      }
    } catch (_) {
      // Keep existing demo/live alerts on connection drop.
    }
  }

  // ── Demo fallback ─────────────────────────────────────────────────

  List<AlertModel> _demoAlerts() {
    final now = DateTime.now();
    return [
      AlertModel(
        id: 'alt_01',
        type: AlertType.hotspotThermal,
        severity: AlertSeverity.warning,
        title: 'High-Temperature Thermal Anomaly Detected',
        summary:
            'Suomi-NPP VIIRS detected a 334.8 K thermal anomaly ~28 km northeast of monitoring center. FRP: 14.8 MW.',
        locationName: 'Aceh Besar / Indrapuri Sector',
        distanceKm: 28.4,
        eventTime: now.subtract(const Duration(minutes: 42)),
        source: 'NASA FIRMS VIIRS (DEMO)',
        isRead: false,
      ),
      AlertModel(
        id: 'alt_02',
        type: AlertType.airQualityDegraded,
        severity: AlertSeverity.info,
        title: 'Morning Particulate Matter Level Stable',
        summary:
            'US EPA AQI index is currently 48 (Good). Atmospheric dispersion forecast remains favorable today.',
        locationName: 'Banda Aceh Basin',
        eventTime: now.subtract(const Duration(hours: 2, minutes: 15)),
        source: 'Open-Meteo CAMS Model',
        isRead: false,
      ),
      AlertModel(
        id: 'alt_03',
        type: AlertType.systemNotice,
        severity: AlertSeverity.info,
        title: 'Monitoring Baseline Active',
        summary:
            'Thermal anomaly detection radius is configured to 50 km. Data refreshes on app foreground and location change.',
        locationName: 'System',
        eventTime: now.subtract(const Duration(hours: 5)),
        source: 'FIREGUARD Core',
        isRead: true,
      ),
    ];
  }
}

// ── Providers ──────────────────────────────────────────────────────

final alertsProvider =
    NotifierProvider<AlertNotifier, List<AlertModel>>(AlertNotifier.new);

final unreadAlertsCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(alertsProvider);
  return alerts.where((a) => !a.isRead).length;
});
