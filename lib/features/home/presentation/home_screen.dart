import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/geo_utils.dart';
import '../../air_quality/data/air_quality_repository.dart';
import '../../hotspots/data/hotspot_repository.dart';
import '../../profile/data/location_preset.dart';
import '../../recommendations/domain/recommendation_engine.dart';
import '../../shared/widgets/app_nav_scaffold.dart';
import '../../shared/widgets/editorial_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../weather/data/weather_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(selectedLocationProvider);
    final aqiAsync = ref.watch(airQualityProvider);
    final hotspotsAsync = ref.watch(hotspotsProvider);
    final weatherAsync = ref.watch(weatherProvider);
    final recommendation = ref.watch(primaryRecommendationProvider);

    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryForest,
          backgroundColor: AppColors.pureWhite,
          onRefresh: () async {
            ref.invalidate(airQualityProvider);
            ref.invalidate(hotspotsProvider);
            ref.invalidate(weatherProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Editorial Header Bar
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.primaryForest,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.alertOrange,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.shield_outlined,
                                  size: 18,
                                  color: AppColors.pureWhite,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                AppConstants.appName,
                                style: AppTypography.wordmark,
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.deepForest,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF225B4B),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'SATELLITE SYNC',
                                  style: AppTypography.badgeLabel.copyWith(
                                    color: const Color(0xFFA7F3D0),
                                    fontSize: 9.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Location & Coordinates Selector
                      InkWell(
                        onTap: () => _showLocationSelector(context, ref),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F4D40),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF2A6353),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Color(0xFFC7D7D0),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                location.displayName,
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontSans,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.pureWhite,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 18,
                                color: Color(0xFFC7D7D0),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Observed: ${GeoUtils.formatCoordinate(location.latitude, location.longitude)} • Updated ${DateFormatters.timeAgo(DateTime.now())}',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontSans,
                          fontSize: 11,
                          color: Color(0xFF9CB1A7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Scientific Disclaimer Strip
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  color: const Color(0xFFEFECE3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 15,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppConstants.satelliteDisclaimer,
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFF525A55),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Main Content Body
              SliverPadding(
                padding: const EdgeInsets.all(18.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Section 1: Air Quality Hero Overview
                    _buildAirQualitySection(context, ref, aqiAsync),
                    const SizedBox(height: 16),

                    // Section 2: Live Weather Conditions
                    _buildWeatherSection(context, weatherAsync),
                    const SizedBox(height: 16),

                    // Section 3: Satellite Hotspot Summary
                    _buildHotspotSummarySection(context, ref, hotspotsAsync),
                    const SizedBox(height: 16),

                    // Section 4: Prioritized Health & Safety Action
                    _buildSafetyRecommendationSection(recommendation),
                    const SizedBox(height: 16),

                    // Section 5: Map Preview Card
                    _buildMapPreviewSection(
                      context,
                      ref,
                      hotspotsAsync,
                      location,
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherSection(
    BuildContext context,
    AsyncValue<dynamic> weatherAsync,
  ) {
    return weatherAsync.when(
      loading: () => const EditorialCard(
        child: SizedBox(
          height: 70,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryForest),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (weather) {
        final isId = Localizations.localeOf(context).languageCode == 'id';
        final windLabel =
            isId ? weather.windDirectionLabel : weather.windDirectionLabelEn;
        final desc = isId ? weather.description : weather.descriptionEn;
        return EditorialCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.forestSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.wb_sunny_outlined,
                  color: AppColors.primaryForest,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isId ? 'CUACA SAAT INI' : 'CURRENT WEATHER',
                      style: AppTypography.titleSmall.copyWith(
                        fontSize: 10.5,
                        letterSpacing: 0.6,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontSans,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${weather.temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontSans,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '💧 ${weather.relativeHumidity}%  💨 ${weather.windSpeed.toStringAsFixed(0)} km/h $windLabel',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAirQualitySection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> aqiAsync,
  ) {
    return aqiAsync.when(
      loading: () => const EditorialCard(
        child: SizedBox(
          height: 110,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryForest),
          ),
        ),
      ),
      error: (err, stack) =>
          EditorialCard(child: Text('Unable to load air quality: $err')),
      data: (aqi) {
        return EditorialCard(
          onTap: () => ref.read(currentNavTabProvider.notifier).setIndex(2),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.air,
                        size: 18,
                        color: AppColors.primaryForest,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AIR QUALITY INDEX',
                        style: AppTypography.titleSmall.copyWith(
                          fontSize: 12,
                          letterSpacing: 0.5,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(
                    label: aqi.categoryLabel,
                    color: aqi.categoryColor,
                    icon: aqi.categoryIcon,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${aqi.usAqi}',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontSans,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'US EPA AQI',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'PM2.5: ${aqi.pm2_5.toStringAsFixed(1)} µg/m³',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontSans,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Model: ECMWF CAMS',
                        style: AppTypography.bodySmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.forestSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.primaryForest,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        aqi.shortHealthAdvice,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.deepForest,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHotspotSummarySection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> hotspotsAsync,
  ) {
    return hotspotsAsync.when(
      loading: () => const EditorialCard(
        child: SizedBox(
          height: 90,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryForest),
          ),
        ),
      ),
      error: (err, stack) =>
          EditorialCard(child: Text('Error loading hotspots: $err')),
      data: (hotspots) {
        final count = hotspots.length;
        final nearest = hotspots.isNotEmpty ? hotspots.first : null;

        return EditorialCard(
          onTap: () => ref.read(currentNavTabProvider.notifier).setIndex(1),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.satellite_alt_outlined,
                        size: 18,
                        color: AppColors.alertOrange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'THERMAL ANOMALIES (HOTSPOTS)',
                        style: AppTypography.titleSmall.copyWith(
                          fontSize: 12,
                          letterSpacing: 0.5,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  if (count > 0 && hotspots.first.isDemo)
                    const StatusBadge(
                      label: 'DEMO DATA',
                      color: Color(0xFF6B7280),
                      showDot: false,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: count > 0
                          ? AppColors.alertOrange.withValues(alpha: 0.12)
                          : AppColors.forestSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: count > 0
                            ? AppColors.alertOrange.withValues(alpha: 0.3)
                            : AppColors.borderSubtle,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$count',
                          style: TextStyle(
                            fontFamily: AppTypography.fontSans,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: count > 0
                                ? AppColors.alertOrange
                                : AppColors.primaryForest,
                          ),
                        ),
                        Text(
                          'Detected',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          count > 0
                              ? 'Nearest: ${nearest?.distanceKm?.toStringAsFixed(1) ?? '—'} km away'
                              : 'No thermal anomalies detected nearby',
                          style: AppTypography.titleSmall.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          count > 0
                              ? 'Sensor: ${nearest?.instrument ?? 'VIIRS'} • FRP ${nearest?.frp.toStringAsFixed(1) ?? '—'} MW'
                              : 'Monitored via NASA VIIRS satellite sensor',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.secondaryText,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSafetyRecommendationSection(dynamic recommendation) {
    return EditorialCard(
      borderColor: AppColors.primaryForest.withValues(alpha: 0.3),
      borderWidth: 1.2,
      backgroundColor: const Color(0xFFF9FAF8),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryForest.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              recommendation.icon,
              size: 20,
              color: AppColors.primaryForest,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SAFETY RECOMMENDATION',
                      style: AppTypography.badgeLabel.copyWith(
                        fontSize: 10,
                        color: AppColors.secondaryText,
                        letterSpacing: 0.8,
                      ),
                    ),
                    StatusBadge(
                      label: recommendation.priorityLabel,
                      color: recommendation.priorityColor,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  recommendation.title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF4B5550),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreviewSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> hotspotsAsync,
    LocationPreset location,
  ) {
    return EditorialCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'REGIONAL SATELLITE RADAR',
                  style: AppTypography.titleSmall.copyWith(
                    fontSize: 12,
                    letterSpacing: 0.5,
                    color: AppColors.secondaryText,
                  ),
                ),
                Text(
                  'Radius: 50 km',
                  style: AppTypography.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),

          // Stylized Map Preview Container
          Container(
            height: 150,
            width: double.infinity,
            color: const Color(0xFFDCE4DD),
            child: Stack(
              children: [
                // Cartographic Grid Lines
                Positioned.fill(child: CustomPaint(painter: _MapGridPainter())),

                // Center Point Marker
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.deepForest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          location.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Icon(
                        Icons.my_location,
                        size: 18,
                        color: AppColors.primaryForest,
                      ),
                    ],
                  ),
                ),

                // Hotspot Pins simulation
                Positioned(
                  top: 25,
                  right: 40,
                  child: _buildMiniPin(AppColors.hotspotHigh, '334K'),
                ),
                Positioned(
                  bottom: 30,
                  left: 60,
                  child: _buildMiniPin(AppColors.hotspotNominal, '316K'),
                ),

                // Overlay CTA button
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(currentNavTabProvider.notifier).setIndex(1);
                    },
                    icon: const Icon(Icons.explore_outlined, size: 16),
                    label: const Text('Explore Full Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryForest,
                      foregroundColor: AppColors.pureWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPin(Color color, String temp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        temp,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showLocationSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Monitoring Region',
                      style: AppTypography.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose a monitored region in Aceh or Indonesia:',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: LocationPreset.defaultPresets.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final preset = LocationPreset.defaultPresets[i];
                      final isSelected =
                          ref.watch(selectedLocationProvider).id == preset.id;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.location_on_outlined,
                          color: isSelected
                              ? AppColors.primaryForest
                              : AppColors.secondaryText,
                        ),
                        title: Text(
                          preset.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primaryForest
                                : AppColors.primaryText,
                          ),
                        ),
                        subtitle: Text(
                          '${preset.region} • ${preset.latitude.toStringAsFixed(2)}°, ${preset.longitude.toStringAsFixed(2)}°',
                          style: AppTypography.bodySmall,
                        ),
                        onTap: () {
                          ref
                              .read(selectedLocationProvider.notifier)
                              .select(preset);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC7D3C9)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
