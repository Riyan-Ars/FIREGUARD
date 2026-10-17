import { Request, Response, NextFunction } from 'express';
import { config } from '../config';

interface RateLimitRecord {
  count: number;
  resetTime: number;
}

const clientRecords = new Map<string, RateLimitRecord>();

export const rateLimiter = (req: Request, res: Response, next: NextFunction): void => {
  const clientIp = (req.headers['x-forwarded-for'] as string) || req.socket.remoteAddress || 'unknown';
  const now = Date.now();
  const windowMs = config.rateLimit.windowMs;
  const maxRequests = config.rateLimit.maxRequests;

  let record = clientRecords.get(clientIp);

  if (!record || now > record.resetTime) {
    record = {
      count: 1,
      resetTime: now + windowMs,
    };
    clientRecords.set(clientIp, record);
  } else {
    record.count++;
  }

  // Set standard rate limit headers
  res.setHeader('X-RateLimit-Limit', maxRequests);
  res.setHeader('X-RateLimit-Remaining', Math.max(0, maxRequests - record.count));
  res.setHeader('X-RateLimit-Reset', Math.ceil(record.resetTime / 1000));

  if (record.count > maxRequests) {
    const retryAfterSeconds = Math.ceil((record.resetTime - now) / 1000);
    res.setHeader('Retry-After', retryAfterSeconds);
    res.status(429).json({
      success: false,
      error: {
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Too many requests. Please slow down.',
        retryAfterSeconds,
      },
      timestamp: new Date().toISOString(),
    });
    return;
  }

  next();
};

// Periodically clean up stale client records every 5 minutes
setInterval(() => {
  const now = Date.now();
  for (const [ip, record] of clientRecords.entries()) {
    if (now > record.resetTime) {
      clientRecords.delete(ip);
    }
  }
}, 300000).unref();
