import express, { Application, Request, Response, NextFunction } from 'express';
import { config } from './config';
import { rateLimiter } from './middleware/rateLimiter';
import { errorHandler, AppError } from './middleware/errorHandler';
import { healthRouter } from './routes/health';
import { hotspotsRouter } from './routes/hotspots';
import { airQualityRouter } from './routes/air_quality';
import { weatherRouter } from './routes/weather';
import { recommendationsRouter } from './routes/recommendations';
import { alertsRouter } from './routes/alerts';
import { logger } from './utils/logger';

export const createApp = (): Application => {
  const app = express();

  // Disable powered-by header for security
  app.disable('x-powered-by');

  // JSON Body Parser with sensible limit
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true, limit: '1mb' }));

  // CORS Middleware
  app.use((req: Request, res: Response, next: NextFunction) => {
    const origin = req.headers.origin as string;
    if (config.allowedOrigins.includes('*') || (origin && config.allowedOrigins.includes(origin))) {
      res.setHeader('Access-Control-Allow-Origin', origin || '*');
    }
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');

    if (req.method === 'OPTIONS') {
      res.status(204).end();
      return;
    }
    next();
  });

  // Request Logging
  app.use((req: Request, res: Response, next: NextFunction) => {
    const start = Date.now();
    res.on('finish', () => {
      const duration = Date.now() - start;
      logger.info(`${req.method} ${req.originalUrl} ${res.statusCode} (${duration}ms)`);
    });
    next();
  });

  // Apply Rate Limiter
  app.use(rateLimiter);

  // Mount API Routes
  app.use(config.apiPrefix, healthRouter);
  app.use(config.apiPrefix, hotspotsRouter);
  app.use(config.apiPrefix, airQualityRouter);
  app.use(config.apiPrefix, weatherRouter);
  app.use(config.apiPrefix, recommendationsRouter);
  app.use(config.apiPrefix, alertsRouter);

  // 404 Route Handler
  app.use((req: Request, res: Response, next: NextFunction) => {
    next(new AppError(`Route not found: ${req.method} ${req.originalUrl}`, 404, 'NOT_FOUND'));
  });

  // Global Error Handler
  app.use(errorHandler);

  return app;
};
