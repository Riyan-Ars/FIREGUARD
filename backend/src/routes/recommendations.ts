import { Router, Request, Response, NextFunction } from 'express';
import { RecommendationService } from '../services/recommendation.service';
import { AppError } from '../middleware/errorHandler';

export const recommendationsRouter = Router();
const service = RecommendationService.getInstance();

recommendationsRouter.get('/recommendations', async (req: Request, res: Response, next: NextFunction) => {
  const startTime = Date.now();
  try {
    const latStr = (req.query.latitude || req.query.lat) as string;
    const lonStr = (req.query.longitude || req.query.lon) as string;

    if (!latStr || !lonStr) {
      throw new AppError('Query parameters "latitude" and "longitude" are required.', 400, 'INVALID_COORDINATES');
    }

    const latitude = parseFloat(latStr);
    const longitude = parseFloat(lonStr);

    if (isNaN(latitude) || latitude < -90 || latitude > 90) {
      throw new AppError('Latitude must be between -90 and 90.', 400, 'INVALID_LATITUDE');
    }

    if (isNaN(longitude) || longitude < -180 || longitude > 180) {
      throw new AppError('Longitude must be between -180 and 180.', 400, 'INVALID_LONGITUDE');
    }

    const { data, isCached } = await service.getRecommendations(latitude, longitude);
    const latencyMs = Date.now() - startTime;

    res.json({
      success: true,
      source: data.source,
      retrievedAt: data.retrievedAt,
      data: {
        context: data.context,
        recommendations: data.recommendations,
      },
      meta: {
        isCached,
        latencyMs,
      },
    });
  } catch (err) {
    next(err);
  }
});
