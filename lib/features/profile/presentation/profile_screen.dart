import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../data/location_preset.dart';
import '../../shared/widgets/editorial_card.dart';

class NotifyHotspotsNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle(bool val) => state = val;
}

final notifyHotspotsProvider = NotifierProvider<NotifyHotspotsNotifier, bool>(
  NotifyHotspotsNotifier.new,
);

class NotifyAqiNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle(bool val) => state = val;
}

final notifyAqiProvider = NotifierProvider<NotifyAqiNotifier, bool>(
  NotifyAqiNotifier.new,
);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _handleGpsLocation(BuildContext context, WidgetRef ref) async {
    final s = AppStrings.of(context);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                s.isId
                    ? 'Layanan lokasi (GPS) tidak aktif. Silakan aktifkan GPS.'
                    : 'Location services are disabled. Please enable GPS.',
              ),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  s.isId
                      ? 'Izin GPS ditolak. Anda tetap dapat memilih lokasi manual di bawah.'
                      : 'GPS permission denied. You can still select locations manually below.',
                ),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                s.isId
                    ? 'Izin GPS ditolak permanen. Silakan gunakan pilihan zona manual.'
                    : 'GPS permission permanently denied. Please use manual location presets.',
              ),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final gpsPreset = LocationPreset(
        id: 'gps_current',
        name: s.isId ? 'Lokasi GPS Saya' : 'My GPS Location',
        region: '${position.latitude.toStringAsFixed(2)}°, ${position.longitude.toStringAsFixed(2)}°',
        latitude: position.latitude,
        longitude: position.longitude,
        isGps: true,
      );

      ref.read(selectedLocationProvider.notifier).select(gpsPreset);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s.isId
                  ? 'Lokasi berhasil diperbarui dari sensor GPS.'
                  : 'Location updated successfully from GPS.',
            ),
            backgroundColor: AppColors.primaryForest,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s.isId
                  ? 'Gagal mendeteksi koordinat GPS ($e).'
                  : 'Failed to acquire GPS coordinates ($e).',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(selectedLocationProvider);
    final alertRadius = ref.watch(alertRadiusProvider);
    final notifyHotspots = ref.watch(notifyHotspotsProvider);
    final notifyAqi = ref.watch(notifyAqiProvider);
    final currentLocale = ref.watch(localeProvider);
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        title: Text(
          s.settingsTitle.toUpperCase(),
          style: const TextStyle(
            fontFamily: AppTypography.fontSans,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Selection Card
            _buildSectionHeader(s.languageSelect.toUpperCase()),
            const SizedBox(height: 8),
            EditorialCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.language, size: 20, color: AppColors.primaryForest),
                          const SizedBox(width: 8),
                          Text(
                            currentLocale.languageCode == 'id'
                                ? 'Bahasa Indonesia (Default)'
                                : 'English (US)',
                            style: AppTypography.titleSmall,
                          ),
                        ],
                      ),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'id', label: Text('ID')),
                          ButtonSegment(value: 'en', label: Text('EN')),
                        ],
                        selected: {currentLocale.languageCode},
                        onSelectionChanged: (Set<String> newSelection) {
                          ref.read(localeProvider.notifier).setLocale(newSelection.first);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Selected Monitoring Location Card
            _buildSectionHeader(s.monitoringZone.toUpperCase()),
            const SizedBox(height: 8),
            EditorialCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(location.name, style: AppTypography.titleMedium),
                          Text(
                            '${location.region} • ${location.latitude.toStringAsFixed(4)}°, ${location.longitude.toStringAsFixed(4)}°',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.gps_fixed, color: AppColors.primaryForest),
                            tooltip: s.gpsLocation,
                            onPressed: () => _handleGpsLocation(context, ref),
                          ),
                          OutlinedButton(
                            onPressed: () => _showLocationDialog(context, ref),
                            child: Text(s.isId ? 'Ubah' : 'Change'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Text(
                    s.isId
                        ? 'GPS bersifat opsional. Eksplorasi peta global dan pemantauan regional tetap berfungsi penuh tanpa izin lokasi.'
                        : 'GPS is optional. Worldwide map exploration and regional monitoring remain fully functional without location permissions.',
                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Alert Radius Configuration
            _buildSectionHeader(s.isId ? 'RADIUS DETEKSI PERINGATAN' : 'ALERT DETECTION RADIUS'),
            const SizedBox(height: 8),
            EditorialCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.isId ? 'Radius Anomali Termal' : 'Thermal Anomaly Radius',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.forestSurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${alertRadius.round()} km',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryForest,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: alertRadius,
                    min: 15.0,
                    max: 150.0,
                    divisions: 9,
                    activeColor: AppColors.primaryForest,
                    inactiveColor: const Color(0xFFD3D8D4),
                    onChanged: (val) {
                      ref.read(alertRadiusProvider.notifier).setRadius(val);
                    },
                  ),
                  Text(
                    s.isId
                        ? 'Anomali termal di luar jarak ini dari titik referensi akan dikecualikan dari umpan peringatan prioritas.'
                        : 'Anomalies beyond this distance from your reference point are excluded from primary alert feeds.',
                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notification Toggles
            _buildSectionHeader(s.isId ? 'PREFERENSI NOTIFIKASI' : 'NOTIFICATION PREFERENCES'),
            const SizedBox(height: 8),
            EditorialCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      s.isId ? 'Peringatan Titik Api Aktif' : 'Thermal Hotspot Alerts',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      s.isId
                          ? 'Beri tahu ketika anomali berkeyakinan tinggi terdeteksi dalam radius'
                          : 'Notify when high-confidence anomalies appear within radius',
                      style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                    ),
                    activeThumbColor: AppColors.primaryForest,
                    value: notifyHotspots,
                    onChanged: (val) => ref.read(notifyHotspotsProvider.notifier).toggle(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(
                      s.isId ? 'Peringatan Udara Tidak Sehat' : 'Unhealthy Air Quality Warnings',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      s.isId
                          ? 'Beri tahu jika indeks AQI melampaui ambang batas 100 di zona pantau'
                          : 'Notify when US EPA AQI exceeds 100 in the selected basin',
                      style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                    ),
                    activeThumbColor: AppColors.primaryForest,
                    value: notifyAqi,
                    onChanged: (val) => ref.read(notifyAqiProvider.notifier).toggle(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Data Sources & Scientific Attribution
            _buildSectionHeader(s.dataAttribution.toUpperCase()),
            const SizedBox(height: 8),
            EditorialCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _AttributionRow(
                    title: 'NASA FIRMS',
                    desc: 'VIIRS (375m) & MODIS Active Fire / Thermal Anomaly Data',
                  ),
                  Divider(height: 16),
                  _AttributionRow(
                    title: 'Open-Meteo Air Quality',
                    desc: 'CAMS (ECMWF) & GFS Atmospheric Chemistry Modeling',
                  ),
                  Divider(height: 16),
                  _AttributionRow(
                    title: 'OpenStreetMap',
                    desc: 'Cartographic Basemap & Geocoding Attribution',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Scientific Disclaimers
            _buildSectionHeader(s.disclaimerTitle.toUpperCase()),
            const SizedBox(height: 8),
            EditorialCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.isId ? 'Pernyataan Satelit' : 'Satellite Thermal Detection',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.satelliteDisclaimer,
                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.isId ? 'Pernyataan Kualitas Udara' : 'Air Quality Dispersion Model',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.airQualityDisclaimer,
                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: AppTypography.fontSans,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.secondaryText,
        letterSpacing: 1.2,
      ),
    );
  }

  void _showLocationDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Reference Monitoring Location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: LocationPreset.defaultPresets.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final preset = LocationPreset.defaultPresets[i];
                    return ListTile(
                      title: Text(preset.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${preset.region} (${preset.latitude.toStringAsFixed(2)}°, ${preset.longitude.toStringAsFixed(2)}°)',
                        style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                      ),
                      onTap: () {
                        ref.read(selectedLocationProvider.notifier).select(preset);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttributionRow extends StatelessWidget {
  final String title;
  final String desc;

  const _AttributionRow({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryForest,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
        ),
      ],
    );
  }
}
