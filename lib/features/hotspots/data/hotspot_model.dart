import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum HotspotConfidence { low, nominal, high }

class HotspotModel {
  final String id;
  final double latitude;
  final double longitude;
  final double brightness; // Brightness temperature in Kelvin
  final HotspotConfidence confidence;
  final DateTime acquisitionTime;
  final String satellite;
  final String instrument;
  final double frp; // Fire Radiative Power (MW)
  final double? distanceKm;
  final bool isDemo;
  final String source;

  const HotspotModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.brightness,
    required this.confidence,
    required this.acquisitionTime,
    required this.satellite,
    required this.instrument,
    required this.frp,
    this.distanceKm,
    this.isDemo = false,
    this.source = 'NASA FIRMS (VIIRS)',
  });

  HotspotModel copyWithDistance(double km) {
    return HotspotModel(
      id: id,
      latitude: latitude,
      longitude: longitude,
      brightness: brightness,
      confidence: confidence,
      acquisitionTime: acquisitionTime,
      satellite: satellite,
      instrument: instrument,
      frp: frp,
      distanceKm: km,
      isDemo: isDemo,
      source: source,
    );
  }

  Color get statusColor {
    switch (confidence) {
      case HotspotConfidence.high:
        return AppColors.hotspotHigh;
      case HotspotConfidence.nominal:
        return AppColors.hotspotNominal;
      case HotspotConfidence.low:
        return AppColors.hotspotLow;
    }
  }

  String get confidenceLabel {
    switch (confidence) {
      case HotspotConfidence.high:
        return 'High Confidence';
      case HotspotConfidence.nominal:
        return 'Nominal Confidence';
      case HotspotConfidence.low:
        return 'Low Confidence';
    }
  }

  factory HotspotModel.fromJson(
    Map<String, dynamic> json, {
    bool isDemo = false,
  }) {
    HotspotConfidence parseConfidence(dynamic val) {
      final str = val?.toString().toLowerCase() ?? '';
      if (str == 'h' ||
          str.contains('high') ||
          (int.tryParse(str) ?? 0) >= 80) {
        return HotspotConfidence.high;
      } else if (str == 'l' ||
          str.contains('low') ||
          (int.tryParse(str) ?? 0) <= 40) {
        return HotspotConfidence.low;
      }
      return HotspotConfidence.nominal;
    }

    return HotspotModel(
      id:
          json['id']?.toString() ??
          'HS-${DateTime.now().millisecondsSinceEpoch}',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      brightness: (json['brightness'] as num?)?.toDouble() ?? 315.0,
      confidence: parseConfidence(json['confidence']),
      acquisitionTime: json['acquisitionTime'] != null
          ? DateTime.tryParse(json['acquisitionTime']) ?? DateTime.now()
          : DateTime.now(),
      satellite: json['satellite']?.toString() ?? 'Suomi NPP',
      instrument: json['instrument']?.toString() ?? 'VIIRS 375m',
      frp: (json['frp'] as num?)?.toDouble() ?? 4.2,
      isDemo: isDemo,
      source: json['source']?.toString() ?? 'NASA FIRMS',
    );
  }
}
