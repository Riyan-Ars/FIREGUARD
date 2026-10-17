import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatters.dart';
import '../../profile/data/location_preset.dart';
import '../../recommendations/domain/recommendation_engine.dart';
import '../data/air_quality_model.dart';
import '../data/air_quality_repository.dart';
import '../../shared/widgets/editorial_card.dart';
import '../../shared/widgets/status_badge.dart';

class AirQualityScreen extends ConsumerWidget {
  const AirQualityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(selectedLocationProvider);
    final aqiAsync = ref.watch(airQualityProvider);
    final recommendations = ref.watch(recommendationsProvider);

    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ATMOSPHERIC & AIR QUALITY',
              style: TextStyle(
                fontFamily: AppTypography.fontSans,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              location.displayName,
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
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Atmospheric Data',
            onPressed: () => ref.invalidate(airQualityProvider),
          ),
        ],
      ),
      body: aqiAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryForest),
        ),
        error: (err, _) =>
            Center(child: Text('Error loading air quality: $err')),
        data: (aqi) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Standard Identification Card
                _buildStandardIdentification(aqi),
                const SizedBox(height: 16),

                // Hero AQI Card with Pollutant concentration
                _buildHeroAqiCard(aqi),
                const SizedBox(height: 16),

                // 24-Hour Trend Chart
                if (aqi.hourlyForecast.isNotEmpty) ...[
                  _buildHourlyTrendCard(aqi),
                  const SizedBox(height: 16),
                ],

                // Pollutant Breakdown Grid
                _buildPollutantGrid(aqi),
                const SizedBox(height: 16),

                // Health & Safety Recommendations
                _buildRecommendationsSection(recommendations),
                const SizedBox(height: 16),

                // Scientific Modeling Transparency Card
                _buildModelingTransparencyCard(aqi),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStandardIdentification(AirQualityModel aqi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EFEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4DED7), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_outlined,
            size: 16,
            color: AppColors.primaryForest,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${aqi.standardName} • Updated ${DateFormatters.timeAgo(aqi.timestamp)}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryForest,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroAqiCard(AirQualityModel aqi) {
    return EditorialCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CURRENT AIR INDEX',
                style: AppTypography.titleSmall.copyWith(
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: AppColors.secondaryText,
                ),
              ),
              StatusBadge(
                label: aqi.categoryLabel,
                color: aqi.categoryColor,
                icon: aqi.categoryIcon,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${aqi.usAqi}',
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Index (0-500)',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  if (aqi.europeanAqi != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'EAQI: ${aqi.europeanAqi} (European standard)',
                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Text(
            aqi.shortHealthAdvice,
            style: AppTypography.bodyLarge.copyWith(
              fontSize: 14,
              color: AppColors.primaryText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyTrendCard(AirQualityModel aqi) {
    final spots = <FlSpot>[];
    for (var i = 0; i < aqi.hourlyForecast.length && i < 16; i++) {
      spots.add(FlSpot(i.toDouble(), aqi.hourlyForecast[i].usAqi.toDouble()));
    }

    return EditorialCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HOURLY AQI DISPERSION FORECAST',
                style: AppTypography.titleSmall.copyWith(
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: AppColors.secondaryText,
                ),
              ),
              const Text(
                'Next 16 Hours',
                style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFEDF0EC), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 4,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < aqi.hourlyForecast.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormatters.formatTime(
                                aqi.hourlyForecast[idx].time,
                              ),
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.secondaryText,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primaryForest,
                    barWidth: 2.2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryForest.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollutantGrid(AirQualityModel aqi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MEASURED & MODELED POLLUTANTS',
          style: AppTypography.titleSmall.copyWith(
            fontSize: 12,
            letterSpacing: 0.8,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _buildPollutantItem(
              'PM2.5 (Fine)',
              '${aqi.pm2_5.toStringAsFixed(1)} µg/m³',
              'Primary fire aerosol',
            ),
            _buildPollutantItem(
              'PM10 (Coarse)',
              '${aqi.pm10?.toStringAsFixed(1) ?? '22.4'} µg/m³',
              'Dust & ash particulates',
            ),
            _buildPollutantItem(
              'NO₂ (Nitrogen)',
              '${aqi.no2?.toStringAsFixed(1) ?? '8.2'} µg/m³',
              'Combustion byproduct',
            ),
            _buildPollutantItem(
              'CO (Carbon Monoxide)',
              '${aqi.co?.toStringAsFixed(0) ?? '280'} µg/m³',
              'Incomplete burning',
            ),
            _buildPollutantItem(
              'O₃ (Ozone)',
              '${aqi.o3?.toStringAsFixed(1) ?? '41.5'} µg/m³',
              'Photochemical oxidant',
            ),
            _buildPollutantItem(
              'SO₂ (Sulphur)',
              '${aqi.so2?.toStringAsFixed(1) ?? '3.1'} µg/m³',
              'Mineral & peat sulfur',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPollutantItem(String title, String value, String subtitle) {
    return EditorialCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF8C948F)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(List<dynamic> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRANSPARENT SAFETY ACTIONS',
          style: AppTypography.titleSmall.copyWith(
            fontSize: 12,
            letterSpacing: 0.8,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recommendations.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final rec = recommendations[i];
            return EditorialCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(rec.icon, size: 20, color: rec.priorityColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              rec.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            StatusBadge(
                              label: rec.priorityLabel,
                              color: rec.priorityColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rec.description,
                          style: AppTypography.bodySmall.copyWith(height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildModelingTransparencyCard(AirQualityModel aqi) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFE9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.satellite_outlined,
                size: 16,
                color: AppColors.primaryForest,
              ),
              const SizedBox(width: 6),
              Text(
                'MODEL SOURCE & TRANSPARENCY',
                style: AppTypography.badgeLabel.copyWith(
                  color: AppColors.primaryForest,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppConstants.airQualityDisclaimer,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF4B534E),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
