import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum AlertType { hotspotThermal, airQualityDegraded, systemNotice }

enum AlertSeverity { info, warning, critical }

class AlertModel {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String summary;
  final String locationName;
  final double? distanceKm;
  final DateTime eventTime;
  final String source;
  final bool isRead;
  final bool isLocal; // local notification vs push

  const AlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.summary,
    required this.locationName,
    this.distanceKm,
    required this.eventTime,
    required this.source,
    this.isRead = false,
    this.isLocal = true,
  });

  AlertModel copyWith({bool? isRead}) {
    return AlertModel(
      id: id,
      type: type,
      severity: severity,
      title: title,
      summary: summary,
      locationName: locationName,
      distanceKm: distanceKm,
      eventTime: eventTime,
      source: source,
      isRead: isRead ?? this.isRead,
      isLocal: isLocal,
    );
  }

  Color get severityColor {
    switch (severity) {
      case AlertSeverity.critical:
        return AppColors.statusUnhealthy;
      case AlertSeverity.warning:
        return AppColors.alertOrange;
      case AlertSeverity.info:
        return AppColors.primaryForest;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case AlertType.hotspotThermal:
        return Icons.local_fire_department_outlined;
      case AlertType.airQualityDegraded:
        return Icons.air_outlined;
      case AlertType.systemNotice:
        return Icons.notifications_none_outlined;
    }
  }
}
