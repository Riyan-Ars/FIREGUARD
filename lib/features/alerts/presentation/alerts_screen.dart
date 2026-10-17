import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatters.dart';
import '../data/alert_model.dart';
import '../data/alert_repository.dart';
import '../../shared/widgets/editorial_card.dart';
import '../../shared/widgets/status_badge.dart';

enum AlertFilterType { all, hotspotsOnly, aqiOnly }

class AlertFilterNotifier extends Notifier<AlertFilterType> {
  @override
  AlertFilterType build() => AlertFilterType.all;

  void setFilter(AlertFilterType filter) {
    state = filter;
  }
}

final alertFilterProvider =
    NotifierProvider<AlertFilterNotifier, AlertFilterType>(
      AlertFilterNotifier.new,
    );

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    final filter = ref.watch(alertFilterProvider);

    final filteredList = alerts.where((a) {
      switch (filter) {
        case AlertFilterType.all:
          return true;
        case AlertFilterType.hotspotsOnly:
          return a.type == AlertType.hotspotThermal;
        case AlertFilterType.aqiOnly:
          return a.type == AlertType.airQualityDegraded;
      }
    }).toList();

    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        title: Text(
          s.alertsTitle.toUpperCase(),
          style: const TextStyle(
            fontFamily: AppTypography.fontSans,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(alertsProvider.notifier).markAllAsRead();
            },
            child: Text(
              s.markAllRead,
              style: const TextStyle(color: AppColors.pureWhite, fontSize: 12),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: AppColors.pureWhite,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterTab(ref, s.isId ? 'Semua Peringatan' : 'All Alerts', AlertFilterType.all, filter),
                const SizedBox(width: 8),
                _buildFilterTab(
                  ref,
                  s.isId ? 'Titik Panas' : 'Thermal Hotspots',
                  AlertFilterType.hotspotsOnly,
                  filter,
                ),
                const SizedBox(width: 8),
                _buildFilterTab(
                  ref,
                  s.isId ? 'Kualitas Udara' : 'Air Quality',
                  AlertFilterType.aqiOnly,
                  filter,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Notification Architecture Disclosure
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF0EFEB),
            child: Row(
              children: const [
                Icon(
                  Icons.sensors_outlined,
                  size: 14,
                  color: AppColors.secondaryText,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Local device alerts active. Push notifications require backend sync.',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF5D6660)),
                  ),
                ),
              ],
            ),
          ),

          // Alerts List
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.notifications_none,
                          size: 48,
                          color: Color(0xFFBDC4BE),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No active environmental alerts',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final alert = filteredList[i];
                      return EditorialCard(
                        onTap: () {
                          ref
                              .read(alertsProvider.notifier)
                              .markAsRead(alert.id);
                        },
                        borderColor: alert.isRead
                            ? AppColors.borderSubtle
                            : alert.severityColor.withValues(alpha: 0.5),
                        borderWidth: alert.isRead ? 1.0 : 1.5,
                        backgroundColor: alert.isRead
                            ? AppColors.pureWhite
                            : const Color(0xFFFDFAF6),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: alert.severityColor.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                alert.typeIcon,
                                size: 20,
                                color: alert.severityColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        alert.locationName,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.secondaryText,
                                        ),
                                      ),
                                      StatusBadge(
                                        label: alert.severity.name
                                            .toUpperCase(),
                                        color: alert.severityColor,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    alert.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: alert.isRead
                                          ? FontWeight.w600
                                          : FontWeight.w700,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    alert.summary,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: const Color(0xFF4C5550),
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Source: ${alert.source}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF8A928D),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        DateFormatters.timeAgo(alert.eventTime),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(
    WidgetRef ref,
    String label,
    AlertFilterType type,
    AlertFilterType current,
  ) {
    final isSelected = type == current;
    return InkWell(
      onTap: () => ref.read(alertFilterProvider.notifier).setFilter(type),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryForest : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.pureWhite : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
}
