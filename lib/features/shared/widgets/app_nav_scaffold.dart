import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../air_quality/presentation/air_quality_screen.dart';
import '../../alerts/data/alert_repository.dart';
import '../../alerts/presentation/alerts_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../map/presentation/map_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class CurrentNavTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final currentNavTabProvider = NotifierProvider<CurrentNavTabNotifier, int>(
  CurrentNavTabNotifier.new,
);

class AppNavScaffold extends ConsumerWidget {
  const AppNavScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentNavTabProvider);
    final unreadAlerts = ref.watch(unreadAlertsCountProvider);

    final screens = const [
      HomeScreen(),
      MapScreen(),
      AirQualityScreen(),
      AlertsScreen(),
      ProfileScreen(),
    ];

    final s = AppStrings.of(context);

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.deepForest,
          border: Border(top: BorderSide(color: Color(0xFF1E3A32), width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  ref: ref,
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: s.navOverview,
                  isSelected: currentIndex == 0,
                ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  index: 1,
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map,
                  label: s.navMap,
                  isSelected: currentIndex == 1,
                ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  index: 2,
                  icon: Icons.air_outlined,
                  activeIcon: Icons.air,
                  label: s.navAirQuality,
                  isSelected: currentIndex == 2,
                ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  index: 3,
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications,
                  label: s.navAlerts,
                  badgeCount: unreadAlerts,
                  isSelected: currentIndex == 3,
                ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  index: 4,
                  icon: Icons.tune_outlined,
                  activeIcon: Icons.tune,
                  label: s.navProfile,
                  isSelected: currentIndex == 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required WidgetRef ref,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    int badgeCount = 0,
  }) {
    const activeColor = AppColors.pureWhite;
    const inactiveColor = Color(0xFF8BA59B);

    return InkWell(
      onTap: () => ref.read(currentNavTabProvider.notifier).setIndex(index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.alertOrange,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontSans,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
