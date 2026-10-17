import { firmsService } from './firms.service';
import { AirQualityService } from './air_quality.service';
import { AlertRecord, AlertsResponse } from '../models/alert.model';
import { appCache } from '../utils/cache';
import { logger } from '../utils/logger';

export class AlertService {
  private static instance: AlertService;

  public static getInstance(): AlertService {
    if (!AlertService.instance) {
      AlertService.instance = new AlertService();
    }
    return AlertService.instance;
  }

  public async getAlerts(
    lat = 5.5483,
    lon = 95.3238,
    radiusKm = 100
  ): Promise<{ data: AlertsResponse; isCached: boolean }> {
    const cacheKey = `alerts:${lat.toFixed(2)}:${lon.toFixed(2)}:${radiusKm}`;
    const cached = appCache.get<AlertsResponse>(cacheKey);

    if (cached) {
      return { data: cached, isCached: true };
    }

    logger.info(`Evaluating alerts for ${lat}, ${lon} (radius: ${radiusKm}km)...`);

    const alerts: AlertRecord[] = [];
    const now = new Date();

    // 1. Check Hotspots
    try {
      const { hotspots } = await firmsService.getHotspots({
        centerLat: lat,
        centerLon: lon,
        radiusKm,
        minConfidence: 'nominal',
      });

      for (const hs of hotspots.slice(0, 5)) {
        const dist = hs.distanceKm ? `${hs.distanceKm.toFixed(1)} km` : 'nearby';
        const isHighConf = hs.confidence === 'high';
        alerts.push({
          id: `ALT-FIRMS-${hs.id}`,
          type: 'hotspotThermal',
          severity: isHighConf ? 'critical' : 'warning',
          title: isHighConf ? 'High Confidence Thermal Anomaly' : 'Thermal Hotspot Detected',
          summary: `Satellite ${hs.satellite} (${hs.instrument}) detected ground temperature ${hs.brightness.toFixed(1)} K approx ${dist} away.`,
          locationName: `${hs.latitude.toFixed(3)}°, ${hs.longitude.toFixed(3)}°`,
          distanceKm: hs.distanceKm,
          eventTime: hs.acquisitionTime,
          source: hs.source,
        });
      }
    } catch (err) {
      logger.warn(`Could not evaluate hotspot alerts: ${err}`);
    }

    // 2. Check Air Quality
    try {
      const { data: aq } = await AirQualityService.getInstance().getAirQuality(lat, lon);
      if (aq.current.usAqi > 100) {
        const isSevere = aq.current.usAqi > 150;
        alerts.push({
          id: `ALT-AQI-${Math.round(lat * 100)}-${Math.round(lon * 100)}`,
          type: 'airQualityDegraded',
          severity: isSevere ? 'critical' : 'warning',
          title: `Degraded Air Quality: ${aq.categoryLabel.en}`,
          summary: `US AQI is ${aq.current.usAqi} (PM2.5: ${aq.current.pm2_5} µg/m³). ${aq.healthAdvice.en}`,
          locationName: `${lat.toFixed(3)}°, ${lon.toFixed(3)}°`,
          eventTime: aq.updatedAt,
          source: aq.dataSource,
        });
      }
    } catch (err) {
      logger.warn(`Could not evaluate air quality alerts: ${err}`);
    }

    // 3. System Sentinel Advisory (always informative)
    alerts.push({
      id: 'ALT-SYS-NRT',
      type: 'systemNotice',
      severity: 'info',
      title: 'Satellite Sentinel Active',
      summary: 'VIIRS NRT polar orbiting satellites (Suomi-NPP & NOAA-20) active. Real-time scanning coverage across regional sector.',
      locationName: 'Regional Coverage',
      eventTime: now.toISOString(),
      source: 'FIREGUARD Sentinel Service',
    });

    const response: AlertsResponse = {
      alerts,
      total: alerts.length,
      retrievedAt: now.toISOString(),
      source: 'FIREGUARD Alert Dispatcher',
    };

    // Cache for 3 minutes (180 seconds)
    appCache.set(cacheKey, response, 180);

    return { data: response, isCached: false };
  }
}
