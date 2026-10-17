import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/geo_utils.dart';
import '../../air_quality/data/air_quality_repository.dart';
import '../../hotspots/data/hotspot_model.dart';
import '../../hotspots/data/hotspot_repository.dart';
import '../../profile/data/location_preset.dart';
import '../../shared/widgets/editorial_card.dart';

enum MapFilter { all, highConfidenceOnly, within25km, within50km }
enum MapLayerMode { combined, hotspots, airQuality, baseOnly }

class MapFilterNotifier extends Notifier<MapFilter> {
  @override
  MapFilter build() => MapFilter.all;

  void setFilter(MapFilter filter) {
    state = filter;
  }
}

final mapFilterProvider = NotifierProvider<MapFilterNotifier, MapFilter>(
  MapFilterNotifier.new,
);

class MapLayerNotifier extends Notifier<MapLayerMode> {
  @override
  MapLayerMode build() => MapLayerMode.combined;

  void setLayer(MapLayerMode mode) {
    state = mode;
  }
}

final mapLayerProvider = NotifierProvider<MapLayerNotifier, MapLayerMode>(
  MapLayerNotifier.new,
);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  HotspotModel? _selectedHotspot;
  bool _showAqiDetail = false;

  // Regional AQI monitoring points for map layer exploration
  static const List<Map<String, dynamic>> _regionalAqiPoints = [
    {'name': 'Banda Aceh', 'lat': 5.5483, 'lon': 95.3238, 'aqi': 48, 'pm25': 12.4, 'cat': 'Baik'},
    {'name': 'Meulaboh', 'lat': 4.1449, 'lon': 96.1265, 'aqi': 54, 'pm25': 14.8, 'cat': 'Sedang'},
    {'name': 'Takengon', 'lat': 4.6297, 'lon': 96.8458, 'aqi': 35, 'pm25': 8.6, 'cat': 'Baik'},
    {'name': 'Langsa', 'lat': 4.4716, 'lon': 97.9683, 'aqi': 62, 'pm25': 18.2, 'cat': 'Sedang'},
    {'name': 'Medan', 'lat': 3.5952, 'lon': 98.6722, 'aqi': 85, 'pm25': 28.5, 'cat': 'Sedang'},
    {'name': 'Pekanbaru', 'lat': 0.5071, 'lon': 101.4478, 'aqi': 118, 'pm25': 42.6, 'cat': 'Sensitif'},
    {'name': 'Palembang', 'lat': -2.9761, 'lon': 104.7754, 'aqi': 76, 'pm25': 24.1, 'cat': 'Sedang'},
    {'name': 'Pontianak', 'lat': -0.0263, 'lon': 109.3425, 'aqi': 68, 'pm25': 20.3, 'cat': 'Sedang'},
    {'name': 'Jakarta', 'lat': -6.2088, 'lon': 106.8456, 'aqi': 132, 'pm25': 48.0, 'cat': 'Sensitif'},
  ];

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return AppColors.statusGood;
    if (aqi <= 100) return AppColors.statusModerate;
    if (aqi <= 150) return AppColors.statusUnhealthySensitive;
    if (aqi <= 200) return AppColors.statusUnhealthy;
    if (aqi <= 300) return AppColors.statusVeryUnhealthy;
    return AppColors.statusHazardous;
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(selectedLocationProvider);
    final hotspotsAsync = ref.watch(hotspotsProvider);
    final currentFilter = ref.watch(mapFilterProvider);
    final layerMode = ref.watch(mapLayerProvider);
    final alertRadius = ref.watch(alertRadiusProvider);
    final s = AppStrings.of(context);

    final centerLatLng = LatLng(location.latitude, location.longitude);

    final showHotspots = layerMode == MapLayerMode.combined || layerMode == MapLayerMode.hotspots;
    final showAirQuality = layerMode == MapLayerMode.combined || layerMode == MapLayerMode.airQuality;

    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.mapTitle,
              style: const TextStyle(
                fontFamily: AppTypography.fontSans,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              '${location.displayName} (${location.latitude.toStringAsFixed(2)}°, ${location.longitude.toStringAsFixed(2)}°)',
              style: const TextStyle(
                fontFamily: AppTypography.fontSans,
                fontSize: 11,
                color: Color(0xFFC7D7D0),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.public),
            tooltip: s.mapGlobalReset,
            onPressed: () {
              // Reset to Worldwide view
              _mapController.move(const LatLng(2.0, 105.0), 3.5);
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: s.mapMyLocation,
            onPressed: () {
              _mapController.move(centerLatLng, 9.5);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: s.mapRefresh,
            onPressed: () {
              ref.invalidate(hotspotsProvider);
              ref.invalidate(airQualityProvider);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Base Interactive Map supporting Worldwide Pan & Zoom
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerLatLng,
              initialZoom: 9.0,
              minZoom: 1.5,
              maxZoom: 18.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedHotspot = null;
                  _showAqiDetail = false;
                });
              },
            ),
            children: [
              // OpenStreetMap Compliant Tile Layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fireguard.app',
              ),

              // Active Radius Ring
              if (showHotspots)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: centerLatLng,
                      radius: alertRadius * 1000,
                      useRadiusInMeter: true,
                      color: AppColors.primaryForest.withValues(alpha: 0.08),
                      borderColor: AppColors.primaryForest.withValues(alpha: 0.4),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

              // Air Quality Layer Markers
              if (showAirQuality)
                MarkerLayer(
                  markers: _regionalAqiPoints.map((pt) {
                    final aqi = pt['aqi'] as int;
                    final color = _getAqiColor(aqi);
                    return Marker(
                      point: LatLng(pt['lat'] as double, pt['lon'] as double),
                      width: 52,
                      height: 52,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAqiDetail = true;
                            _selectedHotspot = null;
                          });
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.45),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.air, size: 10, color: Colors.white),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$aqi',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // Hotspots Layer Markers
              if (showHotspots)
                hotspotsAsync.maybeWhen(
                  data: (allHotspots) {
                    final filteredHotspots = allHotspots.where((h) {
                      switch (currentFilter) {
                        case MapFilter.all:
                          return true;
                        case MapFilter.highConfidenceOnly:
                          return h.confidence == HotspotConfidence.high;
                        case MapFilter.within25km:
                          return (h.distanceKm ?? 999) <= 25.0;
                        case MapFilter.within50km:
                          return (h.distanceKm ?? 999) <= 50.0;
                      }
                    }).toList();

                    return MarkerLayer(
                      markers: [
                        // User / Center Location Pin
                        Marker(
                          point: centerLatLng,
                          width: 44,
                          height: 44,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: AppColors.deepForest,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.my_location,
                                  size: 16,
                                  color: AppColors.pureWhite,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Thermal Hotspots
                        ...filteredHotspots.map((hs) {
                          final isSelected = _selectedHotspot?.id == hs.id;
                          return Marker(
                            point: LatLng(hs.latitude, hs.longitude),
                            width: isSelected ? 48 : 34,
                            height: isSelected ? 48 : 34,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedHotspot = hs;
                                  _showAqiDetail = false;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: hs.statusColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? AppColors.pureWhite : Colors.white70,
                                    width: isSelected ? 3.0 : 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: hs.statusColor.withValues(alpha: 0.4),
                                      blurRadius: isSelected ? 8 : 4,
                                      spreadRadius: isSelected ? 2 : 0,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.local_fire_department,
                                    size: isSelected ? 22 : 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                  orElse: () => const MarkerLayer(markers: []),
                ),
            ],
          ),

          // Top Filter & Layer Bar
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Layer Selector Pill Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildLayerPill(s.mapLayerCombined, MapLayerMode.combined, layerMode),
                      const SizedBox(width: 6),
                      _buildLayerPill(s.mapLayerHotspots, MapLayerMode.hotspots, layerMode),
                      const SizedBox(width: 6),
                      _buildLayerPill(s.mapLayerAirQuality, MapLayerMode.airQuality, layerMode),
                      const SizedBox(width: 6),
                      _buildLayerPill(s.mapLayerBaseOnly, MapLayerMode.baseOnly, layerMode),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Hotspot Filter Chips (Visible when hotspots layer active)
                if (showHotspots)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(s.mapFilterAll, MapFilter.all, currentFilter),
                        const SizedBox(width: 6),
                        _buildFilterChip(s.mapFilterHighConf, MapFilter.highConfidenceOnly, currentFilter),
                        const SizedBox(width: 6),
                        _buildFilterChip(s.mapFilterWithin25km, MapFilter.within25km, currentFilter),
                        const SizedBox(width: 6),
                        _buildFilterChip(s.mapFilterWithin50km, MapFilter.within50km, currentFilter),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Dynamic Map Legend (Bottom Left)
          Positioned(
            left: 12,
            bottom: (_selectedHotspot != null || _showAqiDetail) ? 220 : 24,
            child: _buildLegendCard(showHotspots, showAirQuality, s),
          ),

          // Hotspot Detail Panel
          if (_selectedHotspot != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: _buildHotspotDetailModal(_selectedHotspot!, s),
            ),

          // Air Quality Detail Panel
          if (_showAqiDetail)
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: _buildAqiDetailModal(s),
            ),
        ],
      ),
    );
  }

  Widget _buildLayerPill(String label, MapLayerMode mode, MapLayerMode current) {
    final isSelected = mode == current;
    return InkWell(
      onTap: () => ref.read(mapLayerProvider.notifier).setLayer(mode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryForest : AppColors.pureWhite.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryForest : AppColors.borderSubtle,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.pureWhite : AppColors.primaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, MapFilter filter, MapFilter current) {
    final isSelected = filter == current;
    return InkWell(
      onTap: () => ref.read(mapFilterProvider.notifier).setFilter(filter),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepForest : AppColors.pureWhite.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.deepForest : AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.pureWhite : AppColors.primaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendCard(bool showHotspots, bool showAqi, AppStrings s) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle, width: 0.8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHotspots) ...[
            Text(
              s.mapLegendAnomaly,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryText,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            _buildLegendRow(AppColors.hotspotHigh, 'High (>80%)'),
            const SizedBox(height: 2),
            _buildLegendRow(AppColors.hotspotNominal, 'Nominal (40-80%)'),
            const SizedBox(height: 2),
            _buildLegendRow(AppColors.hotspotLow, 'Low (<40%)'),
          ],
          if (showHotspots && showAqi) const Divider(height: 8),
          if (showAqi) ...[
            Text(
              s.mapLegendAqi,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryText,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            _buildLegendRow(AppColors.statusGood, s.mapLegendGood),
            const SizedBox(height: 2),
            _buildLegendRow(AppColors.statusModerate, s.mapLegendModerate),
            const SizedBox(height: 2),
            _buildLegendRow(AppColors.statusUnhealthySensitive, s.mapLegendSensitive),
            const SizedBox(height: 2),
            _buildLegendRow(AppColors.statusUnhealthy, s.mapLegendUnhealthy),
          ],
          const Divider(height: 8),
          const Text(
            '© OpenStreetMap • NASA FIRMS • Open-Meteo',
            style: TextStyle(fontSize: 8, color: Color(0xFF888E8A)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: AppColors.primaryText),
        ),
      ],
    );
  }

  Widget _buildHotspotDetailModal(HotspotModel hs, AppStrings s) {
    return EditorialCard(
      borderColor: AppColors.alertOrange.withValues(alpha: 0.4),
      borderWidth: 1.5,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: hs.statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.satellite_alt, size: 16, color: hs.statusColor),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hs.satellite, style: AppTypography.titleSmall.copyWith(fontSize: 13)),
                      Text(hs.instrument, style: AppTypography.bodySmall.copyWith(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _selectedHotspot = null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailCol(s.coordinates, GeoUtils.formatCoordinate(hs.latitude, hs.longitude)),
              _buildDetailCol(s.confidence, hs.confidenceLabel),
              _buildDetailCol(s.distance, hs.distanceKm != null ? GeoUtils.formatDistance(hs.distanceKm!) : '—'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailCol(s.brightness, '${hs.brightness.toStringAsFixed(1)} K'),
              _buildDetailCol(s.radiativePower, '${hs.frp.toStringAsFixed(1)} MW'),
              _buildDetailCol(s.observationTime, DateFormatters.timeAgo(hs.acquisitionTime)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAqiDetailModal(AppStrings s) {
    return EditorialCard(
      borderColor: AppColors.statusModerate.withValues(alpha: 0.4),
      borderWidth: 1.5,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.statusModerate.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.air, size: 16, color: AppColors.statusModerate),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.aqiCurrentTitle, style: AppTypography.titleSmall.copyWith(fontSize: 13)),
                      const Text('Open-Meteo Atmospheric Chemistry (ECMWF)', style: TextStyle(fontSize: 10, color: AppColors.secondaryText)),
                    ],
                  ),
                ],
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _showAqiDetail = false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailCol('Index Standard', 'US EPA AQI (0-500)'),
              _buildDetailCol('Fine Particulate', 'PM2.5: 14.8 µg/m³'),
              _buildDetailCol('Category', 'Sedang / Moderate'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCol(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 9.5, color: AppColors.secondaryText)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
      ],
    );
  }
}
