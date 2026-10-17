class AppConstants {
  AppConstants._();

  static const String appName = 'FIREGUARD';
  static const String tagline = 'Detect Early. Alert Smart. Protect More.';

  // Scientific & Cartographic Disclaimer
  static const String satelliteDisclaimer =
      'Thermal anomalies detected by satellites indicate high ground temperatures. '
      'They represent potential hotspots, not verified active fires.';

  static const String airQualityDisclaimer =
      'Air quality metrics are derived from Open-Meteo atmospheric models (CAMS/ECMWF) '
      'and verified regional sensors. Modeled data provides geographic awareness and '
      'is distinct from direct localized reference-grade station measurements.';

  static const double defaultLatitude = 5.5483; // Banda Aceh
  static const double defaultLongitude = 95.3238;
  static const String defaultLocationName = 'Banda Aceh, Aceh';

  static const double defaultAlertRadiusKm = 50.0;
}
