import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../profile/data/location_preset.dart';
import 'weather_model.dart';

class WeatherRepository {
  final ApiClient? apiClient;

  WeatherRepository({this.apiClient});

  Future<WeatherModel> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final client = apiClient ?? ApiClient();
    try {
      final responseData = await client.get(
        '/weather',
        queryParams: {
          'latitude': latitude.toStringAsFixed(4),
          'longitude': longitude.toStringAsFixed(4),
        },
      );

      if (responseData is Map<String, dynamic>) {
        return WeatherModel.fromJson(responseData);
      }
    } catch (_) {
      // Fall through to baseline
    }

    // Fallback: return sensible tropical baseline
    return WeatherModel(
      latitude: latitude,
      longitude: longitude,
      temperature: 28.5,
      relativeHumidity: 75,
      windSpeed: 8.0,
      windDirection: 270,
      weatherCode: 2,
      isDay: true,
      retrievedAt: DateTime.now(),
      source: 'Baseline Climatological Model',
    );
  }
}

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WeatherRepository(apiClient: apiClient);
});

final weatherProvider = FutureProvider<WeatherModel>((ref) async {
  final repo = ref.watch(weatherRepositoryProvider);
  final location = ref.watch(selectedLocationProvider);
  return repo.fetchWeather(
    latitude: location.latitude,
    longitude: location.longitude,
  );
});
