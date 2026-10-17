import 'dart:math' as math;

class GeoUtils {
  GeoUtils._();

  static const double _earthRadiusKm = 6371.0;

  /// Calculate great-circle distance between two coordinates in kilometers using Haversine formula
  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  static double _toRadians(double degree) => degree * math.pi / 180.0;

  /// Format latitude & longitude cleanly for editorial display
  static String formatCoordinate(double lat, double lon) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lonDir = lon >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}°$latDir, ${lon.abs().toStringAsFixed(4)}°$lonDir';
  }

  /// Format human distance (e.g. "14.2 km away")
  static String formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000).round()} m away';
    }
    return '${km.toStringAsFixed(1)} km away';
  }
}
