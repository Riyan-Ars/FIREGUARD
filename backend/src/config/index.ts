import dotenv from 'dotenv';
import path from 'path';

// Load environment variables from .env file if available
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

export interface AppConfig {
  port: number;
  nodeEnv: 'development' | 'production' | 'test';
  apiPrefix: string;
  allowedOrigins: string[];
  nasaFirmsMapKey?: string;
  cacheTtl: {
    hotspots: number;
    airQuality: number;
  };
  rateLimit: {
    windowMs: number;
    maxRequests: number;
  };
}

const parseNumber = (val: string | undefined, fallback: number): number => {
  if (!val) return fallback;
  const parsed = parseInt(val, 10);
  return isNaN(parsed) ? fallback : parsed;
};

export const config: AppConfig = {
  port: parseNumber(process.env.PORT, 3000),
  nodeEnv: (process.env.NODE_ENV as AppConfig['nodeEnv']) || 'development',
  apiPrefix: process.env.API_PREFIX || '/api/v1',
  allowedOrigins: (process.env.ALLOWED_ORIGINS || '*').split(',').map((o) => o.trim()),
  nasaFirmsMapKey: process.env.NASA_FIRMS_MAP_KEY || undefined,
  cacheTtl: {
    hotspots: parseNumber(process.env.HOTSPOT_CACHE_TTL_SECONDS, 300),
    airQuality: parseNumber(process.env.AIR_QUALITY_CACHE_TTL_SECONDS, 600),
  },
  rateLimit: {
    windowMs: parseNumber(process.env.RATE_LIMIT_WINDOW_MS, 60000),
    maxRequests: parseNumber(process.env.RATE_LIMIT_MAX_REQUESTS, 100),
  },
};
