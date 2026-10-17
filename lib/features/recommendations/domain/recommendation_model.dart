import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum RecommendationPriority { high, medium, low }

enum RecommendationCategory { health, indoor, activity, emergency }

class RecommendationModel {
  final String id;
  final String title;
  final String description;
  final RecommendationPriority priority;
  final RecommendationCategory category;
  final IconData icon;

  const RecommendationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.icon,
  });

  Color get priorityColor {
    switch (priority) {
      case RecommendationPriority.high:
        return AppColors.alertOrange;
      case RecommendationPriority.medium:
        return AppColors.statusModerate;
      case RecommendationPriority.low:
        return AppColors.statusGood;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case RecommendationPriority.high:
        return 'High Priority';
      case RecommendationPriority.medium:
        return 'Advisory';
      case RecommendationPriority.low:
        return 'Standard';
    }
  }
}
