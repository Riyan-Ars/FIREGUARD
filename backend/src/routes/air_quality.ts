import { Router, Request, Response, NextFunction } from 'express';
import { AirQualityService } from '../services/air_quality.service';
import { AppError } from '../middleware/errorHandler';

export const airQualityRouter = Router();
const airQualityService = AirQualityService.getInstance();

/**
 * GET /api/v1/air-quality
 * Query params:
 *   lat: Latitude (-90 to 90)
 *   lon: Longitude (-180 to 180)
 */
airQualityRouter.get('/air-quality', async (req: Request, res: Response, next: NextFunction) => {
  const startTime = Date.now();
  try {
    const latStr = (req.query.latitude || req.query.lat) as string;
    const lonStr = (req.query.longitude || req.query.lon) as string;

    if (!latStr || !lonStr) {
      throw new AppError('Query parameters "latitude" (or "lat") and "longitude" (or "lon") are required.', 400, 'INVALID_COORDINATES');
    }

    const lat = parseFloat(latStr);
    const lon = parseFloat(lonStr);

    if (isNaN(lat) || lat < -90 || lat > 90) {
      throw new AppError('Latitude must be a valid floating-point number between -90 and 90.', 400, 'INVALID_LATITUDE');
    }

    if (isNaN(lon) || lon < -180 || lon > 180) {
      throw new AppError('Longitude must be a valid floating-point number between -180 and 180.', 400, 'INVALID_LONGITUDE');
    }

    const { data, isCached } = await airQualityService.getAirQuality(lat, lon);
    const latencyMs = Date.now() - startTime;

    res.json({
      success: true,
      source: data.dataSource,
      retrievedAt: data.updatedAt,
      data,
      meta: {
        isCached,
        latencyMs,
      },
    });
  } catch (err) {
    next(err);
  }
});
