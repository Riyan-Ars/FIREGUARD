import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core brand palette (Editorial Environmental Tech)
  static const Color primaryForest = Color(0xFF173D32);
  static const Color deepForest = Color(0xFF102A24);
  static const Color forestSurface = Color(0xFFE8EFEA);
  static const Color forestHighlight = Color(0xFF225B4B);
  static const Color warmOffWhite = Color(0xFFF5F4EF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color alertOrange = Color(0xFFE87536);
  static const Color secondaryText = Color(0xFF727A74);
  static const Color primaryText = Color(0xFF16231E);
  static const Color borderSubtle = Color(0xFFE3E5DF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFEAECE7);

  // Environmental Status Categories (Air Quality & Thermal Anomalies)
  static const Color statusGood = Color(0xFF2E7D32);
  static const Color statusModerate = Color(0xFFD97706);
  static const Color statusUnhealthySensitive = Color(0xFFE87536);
  static const Color statusUnhealthy = Color(0xFFDC2626);
  static const Color statusVeryUnhealthy = Color(0xFF7C3AED);
  static const Color statusHazardous = Color(0xFF7F1D1D);

  // Satellite Hotspot confidence / thermal intensity
  static const Color hotspotHigh = Color(0xFFDC2626);
  static const Color hotspotNominal = Color(0xFFE87536);
  static const Color hotspotLow = Color(0xFFF59E0B);
  static const Color hotspotRadarBlue = Color(0xFF0284C7);
}
