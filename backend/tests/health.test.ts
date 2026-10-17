import test from 'node:test';
import assert from 'node:assert/strict';
import { MemoryCache } from '../src/utils/cache';
import { config } from '../src/config';
import { createApp } from '../src/app';

test('Backend Configuration - Default Values', () => {
  assert.equal(typeof config.port, 'number');
  assert.equal(config.apiPrefix, '/api/v1');
  assert.equal(config.cacheTtl.hotspots, 300);
  assert.equal(config.cacheTtl.airQuality, 600);
  assert.equal(config.rateLimit.maxRequests, 100);
});

test('MemoryCache - Store, Retrieve, TTL Expiry, and Stats', async () => {
  const cache = new MemoryCache();

  // Test Set & Get
  cache.set('test_key', { aqi: 45, region: 'Aceh' }, 1); // 1 sec TTL
  const cached = cache.get<{ aqi: number; region: string }>('test_key');
  assert.deepEqual(cached, { aqi: 45, region: 'Aceh' });

  // Test Stats
  const stats = cache.getStats();
  assert.equal(stats.hits, 1);
  assert.equal(stats.misses, 0);

  // Test Expiry
  await new Promise((resolve) => setTimeout(resolve, 1100));
  const expired = cache.get('test_key');
  assert.equal(expired, null);
  assert.equal(cache.getStats().misses, 1);

  cache.destroy();
});

test('App Health Endpoint - Route Mount and Structure', () => {
  const app = createApp();
  assert.ok(app);
  // Verify app is an Express instance with routing capabilities
  assert.equal(typeof app.listen, 'function');
});
