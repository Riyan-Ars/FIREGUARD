import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum AqiCategory {
  good,
  moderate,
  unhealthySensitive,
  unhealthy,
  veryUnhealthy,
  hazardous,
}

class HourlyAqiPoint {
  final DateTime time;
  final int usAqi;
  final double pm2_5;

  const HourlyAqiPoint({
    required this.time,
    required this.usAqi,
    required this.pm2_5,
  });
}

class AirQualityModel {
  final int usAqi; // US EPA standard
  final int? europeanAqi; // European EAQI (distinctly separated)
  final double pm2_5; // µg/m³
  final double? pm10; // µg/m³
  final double? no2; // µg/m³
  final double? o3; // µg/m³
  final double? co; // µg/m³
  final double? so2; // µg/m³
  final DateTime timestamp;
  final String standardName; // e.g. "US EPA AQI Standard (0-500)"
  final String dataSource; // e.g. "Open-Meteo Atmospheric Model (ECMWF CAMS)"
  final bool
  isModelData; // true: atmospheric simulation model, not local station
  final bool isStale;
  final List<HourlyAqiPoint> hourlyForecast;

  const AirQualityModel({
    required this.usAqi,
    this.europeanAqi,
    required this.pm2_5,
    this.pm10,
    this.no2,
    this.o3,
    this.co,
    this.so2,
    required this.timestamp,
    this.standardName = 'US EPA AQI Standard',
    this.dataSource = 'Open-Meteo Atmospheric Chemistry (ECMWF CAMS)',
    this.isModelData = true,
    this.isStale = false,
    this.hourlyForecast = const [],
  });

  AqiCategory get category {
    if (usAqi <= 50) return AqiCategory.good;
    if (usAqi <= 100) return AqiCategory.moderate;
    if (usAqi <= 150) return AqiCategory.unhealthySensitive;
    if (usAqi <= 200) return AqiCategory.unhealthy;
    if (usAqi <= 300) return AqiCategory.veryUnhealthy;
    return AqiCategory.hazardous;
  }

  String get categoryLabel {
    switch (category) {
      case AqiCategory.good:
        return 'Good';
      case AqiCategory.moderate:
        return 'Moderate';
      case AqiCategory.unhealthySensitive:
        return 'Unhealthy for Sensitive Groups';
      case AqiCategory.unhealthy:
        return 'Unhealthy';
      case AqiCategory.veryUnhealthy:
        return 'Very Unhealthy';
      case AqiCategory.hazardous:
        return 'Hazardous';
    }
  }

  Color get categoryColor {
    switch (category) {
      case AqiCategory.good:
        return AppColors.statusGood;
      case AqiCategory.moderate:
        return AppColors.statusModerate;
      case AqiCategory.unhealthySensitive:
        return AppColors.statusUnhealthySensitive;
      case AqiCategory.unhealthy:
        return AppColors.statusUnhealthy;
      case AqiCategory.veryUnhealthy:
        return AppColors.statusVeryUnhealthy;
      case AqiCategory.hazardous:
        return AppColors.statusHazardous;
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case AqiCategory.good:
        return Icons.check_circle_outline;
      case AqiCategory.moderate:
        return Icons.info_outline;
      case AqiCategory.unhealthySensitive:
        return Icons.warning_amber_rounded;
      case AqiCategory.unhealthy:
        return Icons.health_and_safety_outlined;
      case AqiCategory.veryUnhealthy:
        return Icons.report_problem_outlined;
      case AqiCategory.hazardous:
        return Icons.dangerous_outlined;
    }
  }

  String get shortHealthAdvice {
    switch (category) {
      case AqiCategory.good:
        return 'Air quality is satisfactory. Normal outdoor activities recommended.';
      case AqiCategory.moderate:
        return 'Air quality is acceptable. Unusually sensitive individuals should monitor symptoms.';
      case AqiCategory.unhealthySensitive:
        return 'People with respiratory conditions, children, and elderly should limit prolonged exertion.';
      case AqiCategory.unhealthy:
        return 'Everyone may begin to experience health effects. Wear a mask outdoors and close windows.';
      case AqiCategory.veryUnhealthy:
        return 'Health alert: serious risk. Avoid outdoor exertion and keep indoor air filtered.';
      case AqiCategory.hazardous:
        return 'Emergency conditions. Entire population is likely affected. Remain indoors.';
    }
  }

  factory AirQualityModel.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final hourly = json['hourly'] as Map<String, dynamic>? ?? {};

    final forecast = <HourlyAqiPoint>[];

    // Check if backend provided hourlyForecast array of objects
    if (json['hourlyForecast'] is List) {
      final list = json['hourlyForecast'] as List;
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final t = DateTime.tryParse(item['time']?.toString() ?? '');
          if (t != null) {
            forecast.add(
              HourlyAqiPoint(
                time: t,
                usAqi: (item['usAqi'] as num?)?.toInt() ?? 45,
                pm2_5: (item['pm2_5'] as num?)?.toDouble() ?? 12.0,
              ),
            );
          }
        }
      }
    } else {
      // Parse raw Open-Meteo parallel arrays
      final times = (hourly['time'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final aqis = (hourly['us_aqi'] as List?) ?? [];
      final pms = (hourly['pm2_5'] as List?) ?? [];

      for (var i = 0; i < times.length && i < 24; i++) {
        final t = DateTime.tryParse(times[i]);
        if (t != null) {
          forecast.add(
            HourlyAqiPoint(
              time: t,
              usAqi: i < aqis.length && aqis[i] != null
                  ? (aqis[i] as num).toInt()
                  : 45,
              pm2_5: i < pms.length && pms[i] != null
                  ? (pms[i] as num).toDouble()
                  : 12.0,
            ),
          );
        }
      }
    }

    final usAqiVal = (current['usAqi'] as num?)?.toInt() ??
        (current['us_aqi'] as num?)?.toInt() ??
        48;
    final europeanAqiVal = (current['europeanAqi'] as num?)?.toInt() ??
        (current['european_aqi'] as num?)?.toInt();
    final pm25Val = (current['pm2_5'] as num?)?.toDouble() ?? 12.4;
    final pm10Val = (current['pm10'] as num?)?.toDouble();
    final no2Val = (current['nitrogenDioxide'] as num?)?.toDouble() ??
        (current['nitrogen_dioxide'] as num?)?.toDouble();
    final o3Val = (current['ozone'] as num?)?.toDouble();
    final coVal = (current['carbonMonoxide'] as num?)?.toDouble() ??
        (current['carbon_monoxide'] as num?)?.toDouble();
    final so2Val = (current['sulphurDioxide'] as num?)?.toDouble() ??
        (current['sulphur_dioxide'] as num?)?.toDouble();

    final dataSource = json['dataSource']?.toString() ??
        'Open-Meteo Air Quality (CAMS/ECMWF Model)';
    final standardName = json['standardName']?.toString() ??
        'US EPA AQI Standard (0-500)';

    return AirQualityModel(
      usAqi: usAqiVal,
      europeanAqi: europeanAqiVal,
      pm2_5: pm25Val,
      pm10: pm10Val,
      no2: no2Val,
      o3: o3Val,
      co: coVal,
      so2: so2Val,
      timestamp: DateTime.now(),
      standardName: standardName,
      dataSource: dataSource,
      isModelData: json['isModelData'] != false,
      isStale: false,
      hourlyForecast: forecast,
    );
  }
}
