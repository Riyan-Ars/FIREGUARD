import 'package:flutter_test/flutter_test.dart';
import 'package:fireguard/core/utils/geo_utils.dart';
import 'package:fireguard/features/air_quality/data/air_quality_model.dart';
import 'package:fireguard/features/hotspots/data/hotspot_model.dart';
import 'package:fireguard/features/recommendations/domain/recommendation_engine.dart';
import 'package:fireguard/features/recommendations/domain/recommendation_model.dart';

void main() {
  group('Geographic Utilities Tests', () {
    test('Haversine distance calculation is accurate', () {
      // Banda Aceh (5.5483, 95.3238) to Meulaboh (4.1449, 96.1265) is approx 179 km
      final dist = GeoUtils.calculateDistanceKm(
        lat1: 5.5483,
        lon1: 95.3238,
        lat2: 4.1449,
        lon2: 96.1265,
      );
      expect(dist, greaterThan(170.0));
      expect(dist, lessThan(190.0));
    });

    test('Same point distance is 0 km', () {
      final dist = GeoUtils.calculateDistanceKm(
        lat1: 5.5483,
        lon1: 95.3238,
        lat2: 5.5483,
        lon2: 95.3238,
      );
      expect(dist, closeTo(0.0, 0.001));
    });

    test('Format coordinate outputs proper hemisphere letters', () {
      final formatted = GeoUtils.formatCoordinate(5.5483, 95.3238);
      expect(formatted, contains('N'));
      expect(formatted, contains('E'));

      final southWest = GeoUtils.formatCoordinate(-6.2, -106.8);
      expect(southWest, contains('S'));
      expect(southWest, contains('W'));
    });
  });

  group('Air Quality Model Category Tests', () {
    test('AQI category thresholds match US EPA standards', () {
      final good = AirQualityModel(
        usAqi: 35,
        pm2_5: 8.4,
        timestamp: DateTime.now(),
      );
      expect(good.category, equals(AqiCategory.good));

      final moderate = AirQualityModel(
        usAqi: 82,
        pm2_5: 26.0,
        timestamp: DateTime.now(),
      );
      expect(moderate.category, equals(AqiCategory.moderate));

      final sensitive = AirQualityModel(
        usAqi: 125,
        pm2_5: 45.0,
        timestamp: DateTime.now(),
      );
      expect(sensitive.category, equals(AqiCategory.unhealthySensitive));

      final unhealthy = AirQualityModel(
        usAqi: 165,
        pm2_5: 82.0,
        timestamp: DateTime.now(),
      );
      expect(unhealthy.category, equals(AqiCategory.unhealthy));

      final veryUnhealthy = AirQualityModel(
        usAqi: 240,
        pm2_5: 180.0,
        timestamp: DateTime.now(),
      );
      expect(veryUnhealthy.category, equals(AqiCategory.veryUnhealthy));

      final hazardous = AirQualityModel(
        usAqi: 350,
        pm2_5: 350.0,
        timestamp: DateTime.now(),
      );
      expect(hazardous.category, equals(AqiCategory.hazardous));
    });
  });

  group('Recommendation Engine Rule Tests', () {
    test('Recommends respirator when AQI exceeds 150', () {
      final aqi = AirQualityModel(
        usAqi: 160,
        pm2_5: 75.0,
        timestamp: DateTime.now(),
      );
      final recs = RecommendationEngine.evaluate(
        airQuality: aqi,
        nearbyHotspots: [],
      );

      final priorityRec = recs.first;
      expect(priorityRec.priority, equals(RecommendationPriority.high));
      expect(priorityRec.title, contains('Mask'));
    });

    test('Includes proximity advisory when hotspot within 25 km', () {
      final aqi = AirQualityModel(
        usAqi: 45,
        pm2_5: 10.0,
        timestamp: DateTime.now(),
      );
      final hotspot = HotspotModel(
        id: 'hs_1',
        latitude: 5.6,
        longitude: 95.4,
        brightness: 320.0,
        confidence: HotspotConfidence.high,
        acquisitionTime: DateTime.now(),
        satellite: 'VIIRS',
        instrument: 'VIIRS',
        frp: 8.0,
        distanceKm: 18.0, // within 25km
      );

      final recs = RecommendationEngine.evaluate(
        airQuality: aqi,
        nearbyHotspots: [hotspot],
      );

      final proximityRec = recs.firstWhere((r) => r.id == 'hotspot_proximity');
      expect(proximityRec, isNotNull);
      expect(proximityRec.title, contains('25 km'));
    });
  });

  group('Hotspot Model Parsing Tests', () {
    test('Correctly parses confidence and values from JSON', () {
      final json = {
        'id': 'TEST-01',
        'latitude': 5.54,
        'longitude': 95.32,
        'brightness': 330.5,
        'confidence': 'high',
        'satellite': 'Suomi-NPP',
        'instrument': 'VIIRS',
        'frp': 12.4,
      };

      final model = HotspotModel.fromJson(json, isDemo: true);
      expect(model.confidence, equals(HotspotConfidence.high));
      expect(model.brightness, equals(330.5));
      expect(model.frp, equals(12.4));
      expect(model.isDemo, isTrue);
    });
  });
}
