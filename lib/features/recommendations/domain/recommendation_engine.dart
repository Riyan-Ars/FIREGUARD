import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../air_quality/data/air_quality_model.dart';
import '../../air_quality/data/air_quality_repository.dart';
import '../../hotspots/data/hotspot_model.dart';
import '../../hotspots/data/hotspot_repository.dart';
import 'recommendation_model.dart';

class RecommendationEngine {
  RecommendationEngine._();

  /// Transparent rule-based safety recommendations evaluated from AQI and nearby anomalies
  static List<RecommendationModel> evaluate({
    required AirQualityModel airQuality,
    required List<HotspotModel> nearbyHotspots,
    bool isId = true,
  }) {
    final list = <RecommendationModel>[];

    // Check AQI Severity
    if (airQuality.usAqi > 200) {
      list.add(
        RecommendationModel(
          id: 'aqi_extreme',
          title: isId
              ? 'Hindari Seluruh Aktivitas di Luar Ruangan'
              : 'Avoid All Outdoor Exertion',
          description: isId
              ? 'Kualitas udara berada pada tingkat sangat berbahaya. Tutup rapat pintu dan jendela, serta nyalakan penyaring udara dalam ruangan.'
              : 'Air quality is in the very unhealthy / hazardous range. Keep windows and doors tightly sealed and run HEPA air filtration if available.',
          priority: RecommendationPriority.high,
          category: RecommendationCategory.emergency,
          icon: Icons.masks_outlined,
        ),
      );
    } else if (airQuality.usAqi > 150) {
      list.add(
        RecommendationModel(
          id: 'aqi_unhealthy',
          title: isId
              ? 'Wajib Gunakan Masker Respirator (N95/KN95) di Luar'
              : 'Wear Respirator Mask (N95/KN95) Outdoors',
          description: isId
              ? 'Kadar partikulat halus (PM2.5) meningkat tajam. Kurangi paparan luar ruangan dan gunakan masker pelindung standar saat bepergian.'
              : 'Fine particulate matter (PM2.5) levels are elevated. Reduce outdoor exposure and wear a well-fitted protective mask if commuting.',
          priority: RecommendationPriority.high,
          category: RecommendationCategory.health,
          icon: Icons.masks_outlined,
        ),
      );
    } else if (airQuality.usAqi > 100) {
      list.add(
        RecommendationModel(
          id: 'aqi_sensitive',
          title: isId
              ? 'Kelompok Sensitif Disarankan Batasi Aktivitas Berat di Luar'
              : 'Sensitive Groups Should Limit Outdoor Strenuous Work',
          description: isId
              ? 'Anak-anak, lansia, dan penderita asma/gangguan pernapasan dianjurkan sering beristirahat dan menghindari olahraga berat di luar.'
              : 'Children, older adults, and individuals with asthma or cardiovascular conditions should take frequent breaks and avoid intense outdoor workouts.',
          priority: RecommendationPriority.medium,
          category: RecommendationCategory.health,
          icon: Icons.nature_people_outlined,
        ),
      );
    } else {
      list.add(
        RecommendationModel(
          id: 'aqi_good',
          title: isId
              ? 'Kualitas Udara Sangat Baik untuk Aktivitas Luar'
              : 'Ideal Air Quality for Outdoor Activities',
          description: isId
              ? 'Indeks polutan udara bersih dan aman. Sangat baik untuk olahraga luar ruangan dan ventilasi udara alami.'
              : 'Current environmental readings indicate clean atmospheric conditions. Great time for open ventilation and physical exercise.',
          priority: RecommendationPriority.low,
          category: RecommendationCategory.activity,
          icon: Icons.directions_run_outlined,
        ),
      );
    }

    // Hotspot Geographic Proximity Rules (Distinct from AQI)
    final closeHotspots = nearbyHotspots
        .where((h) => (h.distanceKm ?? 999) < 25.0)
        .toList();
    if (closeHotspots.isNotEmpty) {
      list.add(
        RecommendationModel(
          id: 'hotspot_proximity',
          title: isId
              ? 'Anomali Titik Panas Terdeteksi dalam 25 km'
              : 'Satellite Hotspot Detected Within 25 km',
          description: isId
              ? 'Satelit mendeteksi anomali termal di dekat area Anda. Pantau arah kepulan asap dan ikuti informasi resmi BPBD setempat.'
              : 'Thermal anomalies exist nearby. Check for visible smoke plumes and monitor local BPBD / forest management updates. Do not assume active ground fire without field verification.',
          priority: RecommendationPriority.medium,
          category: RecommendationCategory.emergency,
          icon: Icons.fireplace_outlined,
        ),
      );
    }

    // General Standard Advice
    list.add(
      RecommendationModel(
        id: 'medical_guidance',
        title: isId
            ? 'Konsultasi Medis Jika Mengalami Gejala Sesak Napas'
            : 'Seek Medical Care for Severe Symptoms',
        description: isId
            ? 'Jika mengalami batuk terus-menerus, sesak napas, atau nyeri dada, segera hubungi fasilitas kesehatan terdekat.'
            : 'If you experience persistent coughing, shortness of breath, or chest tightness, seek immediate consultation from health professionals. FIREGUARD provides environmental observations, not clinical diagnosis.',
        priority: RecommendationPriority.low,
        category: RecommendationCategory.health,
        icon: Icons.medical_services_outlined,
      ),
    );

    return list;
  }
}

final recommendationsProvider = Provider<List<RecommendationModel>>((ref) {
  final aqiAsync = ref.watch(airQualityProvider);
  final hotspotsAsync = ref.watch(hotspotsProvider);
  final locale = ref.watch(localeProvider);

  final aqi =
      aqiAsync.value ??
      AirQualityModel(usAqi: 48, pm2_5: 12.0, timestamp: DateTime.now());

  final hotspots = hotspotsAsync.value ?? [];
  return RecommendationEngine.evaluate(
    airQuality: aqi,
    nearbyHotspots: hotspots,
    isId: locale.languageCode == 'id',
  );
});

final primaryRecommendationProvider = Provider<RecommendationModel>((ref) {
  final all = ref.watch(recommendationsProvider);
  return all.first;
});
