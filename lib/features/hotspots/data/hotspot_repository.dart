import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../core/utils/geo_utils.dart';
import '../../profile/data/location_preset.dart';
import 'hotspot_model.dart';

class HotspotRepository {
  final ApiClient? apiClient;
  final http.Client? httpClient;

  HotspotRepository({this.apiClient, this.httpClient});

  /// Fetch hotspots for given bounding area or center radius.
  /// Queries the FIREGUARD Backend Gateway first, with resilient fallback.
  Future<List<HotspotModel>> fetchHotspots({
    required double centerLat,
    required double centerLon,
    double radiusKm = 100.0,
    String? firmsApiKey,
  }) async {
    // 1. Primary: Query the FIREGUARD Backend Gateway
    final client = apiClient ?? ApiClient(client: httpClient);
    try {
      final responseData = await client.get(
        '/hotspots',
        queryParams: {
          'latitude': centerLat.toStringAsFixed(4),
          'longitude': centerLon.toStringAsFixed(4),
          'radius': radiusKm.toInt().toString(),
          'days': '1',
        },
      );

      if (responseData is List) {
        final hotspots = responseData.map((item) {
          final jsonMap = item as Map<String, dynamic>;
          final model = HotspotModel.fromJson(
            jsonMap,
            isDemo: jsonMap['isDemo'] == true,
          );
          if (jsonMap['distanceKm'] != null) {
            return model.copyWithDistance((jsonMap['distanceKm'] as num).toDouble());
          }
          final dist = GeoUtils.calculateDistanceKm(
            lat1: centerLat,
            lon1: centerLon,
            lat2: model.latitude,
            lon2: model.longitude,
          );
          return model.copyWithDistance(dist);
        }).toList();

        hotspots.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
        return hotspots;
      }
    } catch (_) {
      // Backend request failed or offline; check if direct client key was provided
    }

    // 2. Secondary: If direct client NASA FIRMS API key was provided
    if (firmsApiKey != null &&
        firmsApiKey.isNotEmpty &&
        firmsApiKey != 'DEMO_KEY') {
      try {
        final fallbackHttp = httpClient ?? http.Client();
        final deltaDeg = radiusKm / 111.0;
        final south = (centerLat - deltaDeg).toStringAsFixed(2);
        final north = (centerLat + deltaDeg).toStringAsFixed(2);
        final west = (centerLon - deltaDeg).toStringAsFixed(2);
        final east = (centerLon + deltaDeg).toStringAsFixed(2);

        final url = Uri.parse(
          'https://firms.modaps.eosdis.nasa.gov/api/area/csv/$firmsApiKey/VIIRS_SNPP_NRT/$west,$south,$east,$north/1',
        );

        final response = await fallbackHttp
            .get(url)
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200 &&
            response.body.isNotEmpty &&
            !response.body.contains('Invalid MAP_KEY')) {
          final lines = const LineSplitter().convert(response.body);
          if (lines.length > 1) {
            final headers = lines.first.split(',');
            final latIdx = headers.indexOf('latitude');
            final lonIdx = headers.indexOf('longitude');
            final brightIdx = headers.indexOf('bright_ti4');
            final confIdx = headers.indexOf('confidence');
            final frpIdx = headers.indexOf('frp');

            final results = <HotspotModel>[];
            for (var i = 1; i < lines.length; i++) {
              final cols = lines[i].split(',');
              if (cols.length > latIdx && cols.length > lonIdx) {
                final lat = double.tryParse(cols[latIdx]);
                final lon = double.tryParse(cols[lonIdx]);
                if (lat != null && lon != null) {
                  final dist = GeoUtils.calculateDistanceKm(
                    lat1: centerLat,
                    lon1: centerLon,
                    lat2: lat,
                    lon2: lon,
                  );
                  results.add(
                    HotspotModel(
                      id: 'FIRMS-${DateTime.now().year}-$i',
                      latitude: lat,
                      longitude: lon,
                      brightness: brightIdx != -1 && cols.length > brightIdx
                          ? double.tryParse(cols[brightIdx]) ?? 310.0
                          : 310.0,
                      confidence: confIdx != -1 &&
                              cols.length > confIdx &&
                              cols[confIdx].toLowerCase().startsWith('h')
                          ? HotspotConfidence.high
                          : HotspotConfidence.nominal,
                      acquisitionTime: DateTime.now().subtract(
                        Duration(minutes: (i * 25) % 360),
                      ),
                      satellite: 'Suomi-NPP VIIRS',
                      instrument: 'VIIRS (375m)',
                      frp: frpIdx != -1 && cols.length > frpIdx
                          ? double.tryParse(cols[frpIdx]) ?? 4.5
                          : 4.5,
                      distanceKm: dist,
                      isDemo: false,
                      source: 'NASA FIRMS (Live Direct)',
                    ),
                  );
                }
              }
            }
            if (results.isNotEmpty) {
              results.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
              return results;
            }
          }
        }
      } catch (_) {
        // Fallback to verified demo dataset on error
      }
    }

    // 3. Fallback: Return realistic DEMO dataset clearly labeled with isDemo = true
    return _getDemoHotspots(centerLat, centerLon, radiusKm);
  }

  List<HotspotModel> _getDemoHotspots(
    double centerLat,
    double centerLon,
    double radiusKm,
  ) {
    final now = DateTime.now();

    final rawMockData = [
      {
        'id': 'FIRMS-ID-ACEH-001',
        'offsetLat': 0.18,
        'offsetLon': 0.14,
        'brightness': 334.8,
        'confidence': HotspotConfidence.high,
        'frp': 14.8,
        'satellite': 'Suomi-NPP',
        'instrument': 'VIIRS 375m',
        'ageMinutes': 45,
      },
      {
        'id': 'FIRMS-ID-ACEH-002',
        'offsetLat': -0.22,
        'offsetLon': -0.09,
        'brightness': 318.5,
        'confidence': HotspotConfidence.nominal,
        'frp': 6.8,
        'satellite': 'NOAA-20',
        'instrument': 'VIIRS 375m',
        'ageMinutes': 120,
      },
      {
        'id': 'FIRMS-ID-ACEH-003',
        'offsetLat': 0.35,
        'offsetLon': -0.25,
        'brightness': 309.2,
        'confidence': HotspotConfidence.low,
        'frp': 3.1,
        'satellite': 'Aqua',
        'instrument': 'MODIS 1km',
        'ageMinutes': 240,
      },
      {
        'id': 'FIRMS-ID-ACEH-004',
        'offsetLat': -0.48,
        'offsetLon': 0.31,
        'brightness': 341.2,
        'confidence': HotspotConfidence.high,
        'frp': 19.5,
        'satellite': 'Suomi-NPP',
        'instrument': 'VIIRS 375m',
        'ageMinutes': 320,
      },
    ];

    final hotspots = <HotspotModel>[];
    for (final data in rawMockData) {
      final lat = centerLat + (data['offsetLat'] as double);
      final lon = centerLon + (data['offsetLon'] as double);
      final dist = GeoUtils.calculateDistanceKm(
        lat1: centerLat,
        lon1: centerLon,
        lat2: lat,
        lon2: lon,
      );

      if (dist <= radiusKm * 1.5) {
        hotspots.add(
          HotspotModel(
            id: data['id'] as String,
            latitude: lat,
            longitude: lon,
            brightness: data['brightness'] as double,
            confidence: data['confidence'] as HotspotConfidence,
            acquisitionTime: now.subtract(
              Duration(minutes: data['ageMinutes'] as int),
            ),
            satellite: data['satellite'] as String,
            instrument: data['instrument'] as String,
            frp: data['frp'] as double,
            distanceKm: dist,
            isDemo: true,
            source: 'NASA FIRMS VIIRS (DEMO)',
          ),
        );
      }
    }

    hotspots.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    return hotspots;
  }
}

// Riverpod Provider
final hotspotRepositoryProvider = Provider<HotspotRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HotspotRepository(apiClient: apiClient);
});

final hotspotsProvider = FutureProvider<List<HotspotModel>>((ref) async {
  final repo = ref.watch(hotspotRepositoryProvider);
  final location = ref.watch(selectedLocationProvider);
  return repo.fetchHotspots(
    centerLat: location.latitude,
    centerLon: location.longitude,
  );
});
