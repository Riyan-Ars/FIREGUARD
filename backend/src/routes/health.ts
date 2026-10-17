import { Router, Request, Response } from 'express';
import { appCache } from '../utils/cache';
import { config } from '../config';

export const healthRouter = Router();

healthRouter.get('/health', (req: Request, res: Response) => {
  const memoryUsage = process.memoryUsage();

  res.status(200).json({
    success: true,
    status: 'healthy',
    service: 'FIREGUARD Gateway Backend API',
    tagline: 'Detect Early. Alert Smart. Protect More.',
    version: '1.0.0',
    environment: config.nodeEnv,
    uptimeSeconds: Math.floor(process.uptime()),
    timestamp: new Date().toISOString(),
    metrics: {
      memory: {
        rssMb: Math.round(memoryUsage.rss / 1024 / 1024),
        heapUsedMb: Math.round(memoryUsage.heapUsed / 1024 / 1024),
        heapTotalMb: Math.round(memoryUsage.heapTotal / 1024 / 1024),
      },
      cache: appCache.getStats(),
    },
  });
});
