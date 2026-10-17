import { AirQualityService } from './air_quality.service';
import { firmsService } from './firms.service';
import { appCache } from '../utils/cache';
import {
  RecommendationItem,
  RecommendationsResponse,
  EnvironmentalContext,
} from '../models/recommendation.model';
import { logger } from '../utils/logger';

export class RecommendationService {
  private static instance: RecommendationService;

  public static getInstance(): RecommendationService {
    if (!RecommendationService.instance) {
      RecommendationService.instance = new RecommendationService();
    }
    return RecommendationService.instance;
  }

  public async getRecommendations(
    lat: number,
    lon: number
  ): Promise<{ data: RecommendationsResponse; isCached: boolean }> {
    const cacheKey = `recommendations:${lat.toFixed(2)}:${lon.toFixed(2)}`;
    const cached = appCache.get<RecommendationsResponse>(cacheKey);

    if (cached) {
      return { data: cached, isCached: true };
    }

    logger.info(`Synthesizing recommendations for ${lat}, ${lon}...`);

    // Fetch air quality and hotspots in parallel
    const [aqResult, hotspotsResult] = await Promise.allSettled([
      AirQualityService.getInstance().getAirQuality(lat, lon),
      firmsService.getHotspots({ centerLat: lat, centerLon: lon, radiusKm: 100 }),
    ]);

    const usAqi = aqResult.status === 'fulfilled' ? aqResult.value.data.current.usAqi : undefined;
    const pm2_5 = aqResult.status === 'fulfilled' ? aqResult.value.data.current.pm2_5 : undefined;
    const hotspots = hotspotsResult.status === 'fulfilled' ? hotspotsResult.value.hotspots : [];

    let nearestHotspotDistanceKm: number | undefined;
    if (hotspots.length > 0) {
      const distances = hotspots
        .map((h) => h.distanceKm)
        .filter((d): d is number => typeof d === 'number');
      if (distances.length > 0) {
        nearestHotspotDistanceKm = Math.min(...distances);
      }
    }

    const context: EnvironmentalContext = {
      latitude: lat,
      longitude: lon,
      usAqi,
      pm2_5,
      nearestHotspotDistanceKm,
      activeHotspotsCount: hotspots.length,
    };

    const recommendations = this.evaluateRules(context);

    const response: RecommendationsResponse = {
      context,
      recommendations,
      retrievedAt: new Date().toISOString(),
      source: 'FIREGUARD Environmental Decision Engine',
    };

    // Cache for 5 minutes (300 seconds)
    appCache.set(cacheKey, response, 300);

    return { data: response, isCached: false };
  }

  private evaluateRules(ctx: EnvironmentalContext): RecommendationItem[] {
    const items: RecommendationItem[] = [];
    const aqi = ctx.usAqi ?? 50;
    const hotspotDist = ctx.nearestHotspotDistanceKm ?? 999;
    const count = ctx.activeHotspotsCount ?? 0;

    // Rule 1: High Smoke / Proximity Hazard
    if (hotspotDist <= 20 || aqi > 150) {
      items.push({
        id: 'REC-HAZARD-001',
        category: 'emergency',
        priority: 'high',
        title: {
          en: 'Active Wildfire Proximity Alert',
          id: 'Peringatan Jarak Dekat Titik Panas',
        },
        description: {
          en: 'Thermal anomaly detected within 20 km. Keep vehicle fueled, pack essential documents, and monitor local authorities.',
          id: 'Anomali termal terdeteksi dalam 20 km. Siapkan kendaraan, dokumen penting, dan ikuti instruksi BPBD/aparat setempat.',
        },
        rationale: `Nearest hotspot is ${hotspotDist.toFixed(1)} km away. AQI is ${aqi}.`,
      });
    }

    // Rule 2: Mask Protection
    if (aqi > 100 || hotspotDist <= 50) {
      items.push({
        id: 'REC-HEALTH-001',
        category: 'health',
        priority: aqi > 150 ? 'high' : 'medium',
        title: {
          en: 'Use N95 / KN95 Particulate Respirator',
          id: 'Gunakan Masker N95 / KN95',
        },
        description: {
          en: 'Standard cloth masks do not block PM2.5 smoke particulates. Use certified N95 or KN95 respirators outdoors.',
          id: 'Masker kain standar tidak menyaring partikel halus PM2.5. Gunakan respirator bersertifikasi N95/KN95 di luar ruangan.',
        },
        rationale: `PM2.5 exposure risk elevated (AQI: ${aqi}).`,
      });
    }

    // Rule 3: Indoor Air Sealing
    if (aqi > 100 || count > 0) {
      items.push({
        id: 'REC-INDOOR-001',
        category: 'indoor',
        priority: 'medium',
        title: {
          en: 'Seal Ventilation and Run Air Purifier',
          id: 'Tutup Ventilasi dan Nyalakan Penyaring Udara',
        },
        description: {
          en: 'Close windows and exterior doors. Set air conditioning units to internal recirculate mode.',
          id: 'Tutup jendela dan ventilasi luar. Pasang AC pada mode sirkulasi dalam (recirculate) untuk mencegah asap masuk.',
        },
        rationale: 'Prevent fine particulates from penetrating living and working spaces.',
      });
    }

    // Rule 4: Outdoor Activity Moderation
    if (aqi > 150) {
      items.push({
        id: 'REC-ACT-001',
        category: 'activity',
        priority: 'high',
        title: {
          en: 'Cancel Strenuous Outdoor Activities',
          id: 'Hentikan Olahraga & Aktivitas Berat di Luar',
        },
        description: {
          en: 'Heavy exercise dramatically increases particle inhalation into deep lung tissue. Move workouts indoors.',
          id: 'Aktivitas berat melipatgandakan volume partikel yang masuk ke paru-paru. Alihkan semua olahraga ke dalam ruangan.',
        },
        rationale: `Air quality has reached unhealthy threshold (AQI: ${aqi}).`,
      });
    } else if (aqi > 50) {
      items.push({
        id: 'REC-ACT-002',
        category: 'activity',
        priority: 'low',
        title: {
          en: 'Moderate Outdoor Physical Exertion',
          id: 'Batasi Beban Aktivitas Luar Ruangan',
        },
        description: {
          en: 'Sensitive groups (asthmatics, children, elderly) should take frequent breaks during outdoor tasks.',
          id: 'Kelompok rentan (penderita asma, anak-anak, lansia) dianjurkan lebih sering beristirahat saat di luar.',
        },
        rationale: 'Moderate air pollution level.',
      });
    } else {
      items.push({
        id: 'REC-GEN-001',
        category: 'activity',
        priority: 'low',
        title: {
          en: 'Air Quality is Optimal',
          id: 'Kualitas Udara Bersih & Optimal',
        },
        description: {
          en: 'Good conditions for outdoor recreation and regular natural ventilation.',
          id: 'Kondisi udara baik untuk aktivitas luar ruangan dan ventilasi alami ruangan.',
        },
        rationale: `AQI is ${aqi} (Good).`,
      });
    }

    return items;
  }
}
