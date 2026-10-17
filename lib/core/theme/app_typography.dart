import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const String fontSans = 'Roboto';

  // Wordmark branding
  static const TextStyle wordmark = TextStyle(
    fontFamily: fontSans,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.8,
    color: AppColors.pureWhite,
  );

  static const TextStyle wordmarkDark = TextStyle(
    fontFamily: fontSans,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.8,
    color: AppColors.deepForest,
  );

  // Headlines
  static const TextStyle display = TextStyle(
    fontFamily: fontSans,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: AppColors.primaryText,
    height: 1.15,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontSans,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.primaryText,
    height: 1.25,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontSans,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.primaryText,
    height: 1.3,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontSans,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.primaryText,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontSans,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryText,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontSans,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontSans,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
    height: 1.35,
  );

  // Technical Labels / Monospace for Coordinates & Sensors
  static const TextStyle monoCoord = TextStyle(
    fontFamily: 'Courier',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.primaryForest,
  );

  static const TextStyle badgeLabel = TextStyle(
    fontFamily: fontSans,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );
}
