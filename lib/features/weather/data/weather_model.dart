/// Weather data model — maps to the FIREGUARD Gateway /weather response.
class WeatherModel {
  final double latitude;
  final double longitude;
  final double temperature;
  final int relativeHumidity;
  final double windSpeed;
  final int windDirection;
  final int? weatherCode;
  final bool? isDay;
  final DateTime retrievedAt;
  final String source;

  const WeatherModel({
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.relativeHumidity,
    required this.windSpeed,
    required this.windDirection,
    this.weatherCode,
    this.isDay,
    required this.retrievedAt,
    required this.source,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    // The gateway wraps the payload inside `data`; callers may strip it first.
    final current = (json['current'] as Map<String, dynamic>?) ?? json;
    return WeatherModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      temperature: (current['temperature'] as num?)?.toDouble() ?? 25.0,
      relativeHumidity: (current['relativeHumidity'] as num?)?.toInt() ?? 70,
      windSpeed: (current['windSpeed'] as num?)?.toDouble() ?? 5.0,
      windDirection: (current['windDirection'] as num?)?.toInt() ?? 0,
      weatherCode: (current['weatherCode'] as num?)?.toInt(),
      isDay: current['isDay'] as bool?,
      retrievedAt: DateTime.tryParse(
              json['retrievedAt']?.toString() ?? '') ??
          DateTime.now(),
      source: json['source']?.toString() ?? 'Open-Meteo',
    );
  }

  /// Human-readable weather description based on WMO weather code.
  String get description {
    if (weatherCode == null) return 'Cuaca tidak tersedia';
    final c = weatherCode!;
    if (c == 0) return 'Cerah';
    if (c <= 3) return 'Berawan sebagian';
    if (c <= 19) return 'Berkabut / berasap';
    if (c <= 29) return 'Gerimis';
    if (c <= 39) return 'Berkabut';
    if (c <= 49) return 'Kabut';
    if (c <= 59) return 'Gerimis';
    if (c <= 69) return 'Hujan';
    if (c <= 79) return 'Salju / es';
    if (c <= 84) return 'Hujan lebat';
    if (c <= 99) return 'Badai petir';
    return 'Tidak diketahui';
  }

  String get descriptionEn {
    if (weatherCode == null) return 'N/A';
    final c = weatherCode!;
    if (c == 0) return 'Clear sky';
    if (c <= 3) return 'Partly cloudy';
    if (c <= 19) return 'Haze / smoke';
    if (c <= 39) return 'Fog';
    if (c <= 49) return 'Freezing fog';
    if (c <= 59) return 'Drizzle';
    if (c <= 69) return 'Rain';
    if (c <= 79) return 'Snow';
    if (c <= 84) return 'Rain showers';
    if (c <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  /// Wind direction as 8-point compass label (Indonesian).
  String get windDirectionLabel {
    const dirs = ['U', 'TL', 'T', 'TG', 'S', 'BD', 'B', 'BL'];
    final idx = ((windDirection + 22.5) ~/ 45) % 8;
    return dirs[idx];
  }

  String get windDirectionLabelEn {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final idx = ((windDirection + 22.5) ~/ 45) % 8;
    return dirs[idx];
  }

  WeatherModel copyWith({
    double? latitude,
    double? longitude,
    double? temperature,
    int? relativeHumidity,
    double? windSpeed,
    int? windDirection,
    int? weatherCode,
    bool? isDay,
    DateTime? retrievedAt,
    String? source,
  }) {
    return WeatherModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      temperature: temperature ?? this.temperature,
      relativeHumidity: relativeHumidity ?? this.relativeHumidity,
      windSpeed: windSpeed ?? this.windSpeed,
      windDirection: windDirection ?? this.windDirection,
      weatherCode: weatherCode ?? this.weatherCode,
      isDay: isDay ?? this.isDay,
      retrievedAt: retrievedAt ?? this.retrievedAt,
      source: source ?? this.source,
    );
  }
}
