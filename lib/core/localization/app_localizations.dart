import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  id('id', 'Bahasa Indonesia'),
  en('en', 'English');

  final String code;
  final String displayName;
  const AppLanguage(this.code, this.displayName);
}

class LocaleNotifier extends Notifier<Locale> {
  static const String _prefKey = 'selected_locale_code';

  @override
  Locale build() {
    _loadPersistedLocale();
    // Default language is Indonesian ('id')
    return const Locale('id');
  }

  Future<void> _loadPersistedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefKey);
      if (code != null && (code == 'id' || code == 'en')) {
        state = Locale(code);
      }
    } catch (_) {}
  }

  Future<void> setLocale(String languageCode) async {
    if (languageCode != 'id' && languageCode != 'en') return;
    state = Locale(languageCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, languageCode);
    } catch (_) {}
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class AppStrings {
  final String locale;
  AppStrings(this.locale);

  static AppStrings of(BuildContext context) {
    final loc = Localizations.localeOf(context).languageCode;
    return AppStrings(loc);
  }

  bool get isId => locale == 'id';

  // Navigation
  String get navOverview => isId ? 'Beranda' : 'Home';
  String get navMap => isId ? 'Peta' : 'Map';
  String get navAirQuality => isId ? 'Kualitas Udara' : 'Air Quality';
  String get navAlerts => isId ? 'Peringatan' : 'Alerts';
  String get navProfile => isId ? 'Profil' : 'Profile';

  // Map Controls & Headers
  String get mapTitle => isId ? 'RADAR SATELIT & CUACA' : 'SATELLITE & WEATHER RADAR';
  String get mapGlobalReset => isId ? 'Tampilan Global' : 'Global View';
  String get mapMyLocation => isId ? 'Lokasi Saya' : 'My Location';
  String get mapRefresh => isId ? 'Segarkan' : 'Refresh';
  String get mapLayers => isId ? 'Lapisan Peta' : 'Map Layers';
  String get mapLayerHotspots => isId ? 'Titik Panas Satelit' : 'Hotspots';
  String get mapLayerAirQuality => isId ? 'Kualitas Udara' : 'Air Quality';
  String get mapLayerCombined => isId ? 'Titik Panas + Udara' : 'Hotspots + Air Quality';
  String get mapLayerBaseOnly => isId ? 'Peta Dasar Saja' : 'Base Map Only';
  String get mapFilterAll => isId ? 'Semua' : 'All';
  String get mapFilterHighConf => isId ? 'Tingkat Tinggi' : 'High Confidence';
  String get mapFilterWithin25km => isId ? 'Radius 25 km' : 'Within 25 km';
  String get mapFilterWithin50km => isId ? 'Radius 50 km' : 'Within 50 km';
  String get mapFilterWithin100km => isId ? 'Radius 100 km' : 'Within 100 km';
  String get mapLegendAnomaly => isId ? 'TINGKAT KEPERCAYAAN ANOMALI' : 'ANOMALY CONFIDENCE';
  String get mapLegendAqi => isId ? 'INDEKS KUALITAS UDARA (AQI)' : 'AIR QUALITY INDEX (AQI)';
  String get mapLegendGood => isId ? 'Baik (0-50)' : 'Good (0-50)';
  String get mapLegendModerate => isId ? 'Sedang (51-100)' : 'Moderate (51-100)';
  String get mapLegendSensitive => isId ? 'Sensitif (101-150)' : 'Sensitive (101-150)';
  String get mapLegendUnhealthy => isId ? 'Tidak Sehat (151-200)' : 'Unhealthy (151-200)';
  String get mapLegendVeryUnhealthy => isId ? 'Sangat Tidak Sehat (201-300)' : 'Very Unhealthy (201-300)';
  String get mapLegendHazardous => isId ? 'Berbahaya (>300)' : 'Hazardous (>300)';

  // Telemetry details
  String get coordinates => isId ? 'Koordinat' : 'Coordinates';
  String get confidence => isId ? 'Kepercayaan' : 'Confidence';
  String get distance => isId ? 'Jarak' : 'Distance';
  String get brightness => isId ? 'Suhu Termal' : 'Thermal Brightness';
  String get radiativePower => isId ? 'Daya Radiasi (FRP)' : 'Radiative Power (FRP)';
  String get observationTime => isId ? 'Waktu Pengamatan' : 'Observation Time';
  String get satellite => isId ? 'Satelit' : 'Satellite';
  String get instrument => isId ? 'Instrumen' : 'Instrument';
  String get dataSource => isId ? 'Sumber Data' : 'Data Source';

  // Air Quality
  String get aqiCurrentTitle => isId ? 'Indeks Kualitas Udara Saat Ini' : 'Current Air Quality Index';
  String get hourlyForecastTitle => isId ? 'Prakiraan 24 Jam Mendatang' : '24-Hour Forecast Trend';
  String get healthAdviceTitle => isId ? 'Panduan Tindakan' : 'Actionable Health Guidance';
  String get pollutantBreakdown => isId ? 'Rincian Polutan Udara' : 'Pollutant Breakdown';

  // Alerts
  String get alertsTitle => isId ? 'Peringatan & Sentinel' : 'Alerts & Sentinel';
  String get markAllRead => isId ? 'Tandai Semua Dibaca' : 'Mark all as read';
  String get noAlerts => isId ? 'Belum ada peringatan aktif di area pemantauan Anda.' : 'No active alerts in your monitoring zone.';

  // Settings & Profile
  String get settingsTitle => isId ? 'Pengaturan & Preferensi' : 'Settings & Preferences';
  String get languageSelect => isId ? 'Bahasa Aplikasi' : 'Application Language';
  String get monitoringZone => isId ? 'Zona Pemantauan Aktif' : 'Active Monitoring Zone';
  String get gpsLocation => isId ? 'Gunakan GPS Perangkat' : 'Use Device GPS';
  String get dataAttribution => isId ? 'Atribusi & Sumber Resmi' : 'Attribution & Official Sources';
  String get disclaimerTitle => isId ? 'Pernyataan Ilmiah' : 'Scientific Disclaimer';
}
