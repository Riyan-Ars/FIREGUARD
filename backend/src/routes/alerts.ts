import { Router, Request, Response, NextFunction } from 'express';
import { AlertService } from '../services/alert.service';

export const alertsRouter = Router();
const service = AlertService.getInstance();

alertsRouter.get('/alerts', async (req: Request, res: Response, next: NextFunction) => {
  const startTime = Date.now();
  try {
    const latStr = (req.query.latitude || req.query.lat) as string;
    const lonStr = (req.query.longitude || req.query.lon) as string;
    const radStr = req.query.radius as string;

    const lat = latStr ? parseFloat(latStr) : 5.5483;
    const lon = lonStr ? parseFloat(lonStr) : 95.3238;
    const radius = radStr ? parseFloat(radStr) : 100;

    const { data, isCached } = await service.getAlerts(lat, lon, radius);
    const latencyMs = Date.now() - startTime;

    res.json({
      success: true,
      source: data.source,
      retrievedAt: data.retrievedAt,
      data: data.alerts,
      meta: {
        total: data.total,
        isCached,
        latencyMs,
      },
    });
  } catch (err) {
    next(err);
  }
});
