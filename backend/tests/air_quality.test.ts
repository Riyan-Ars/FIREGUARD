import test from 'node:test';
import assert from 'node:assert/strict';
import { AirQualityService } from '../src/services/air_quality.service';

test('Air Quality Service - Categorization thresholds align with US EPA standards', () => {
  const service = AirQualityService.getInstance();

  assert.equal(service.determineCategory(25), 'good');
  assert.equal(service.determineCategory(50), 'good');
  assert.equal(service.determineCategory(51), 'moderate');
  assert.equal(service.determineCategory(100), 'moderate');
  assert.equal(service.determineCategory(101), 'unhealthy_sensitive');
  assert.equal(service.determineCategory(150), 'unhealthy_sensitive');
  assert.equal(service.determineCategory(151), 'unhealthy');
  assert.equal(service.determineCategory(200), 'unhealthy');
  assert.equal(service.determineCategory(201), 'very_unhealthy');
  assert.equal(service.determineCategory(300), 'very_unhealthy');
  assert.equal(service.determineCategory(301), 'hazardous');
  assert.equal(service.determineCategory(450), 'hazardous');
});

test('Air Quality Service - Bilingual labels and health advice exist for all categories', () => {
  const service = AirQualityService.getInstance();
  const categories = [
    'good',
    'moderate',
    'unhealthy_sensitive',
    'unhealthy',
    'very_unhealthy',
    'hazardous',
  ] as const;

  for (const cat of categories) {
    const label = service.getCategoryLabel(cat);
    assert.ok(label.en.length > 0);
    assert.ok(label.id.length > 0);

    const advice = service.getHealthAdvice(cat);
    assert.ok(advice.en.length > 0);
    assert.ok(advice.id.length > 0);
  }
});

test('Air Quality Service - Fallback generation produces 24h hourly forecast and valid schema', () => {
  const service = AirQualityService.getInstance();
  const fallback = service.generateFallbackData(5.5483, 95.3238);

  assert.equal(fallback.latitude, 5.5483);
  assert.equal(fallback.longitude, 95.3238);
  assert.equal(fallback.isFallback, true);
  assert.equal(fallback.isModelData, true);
  assert.ok(fallback.current.usAqi > 0);
  assert.ok(fallback.current.pm2_5 > 0);
  assert.equal(fallback.hourlyForecast.length, 24);
  assert.ok(fallback.hourlyForecast[0].usAqi > 0);
});

test('Air Quality Service - Fetch with live API or fallback and verify caching', async () => {
  const service = AirQualityService.getInstance();
  const lat = 5.5483;
  const lon = 95.3238;

  // First fetch (cache miss or live)
  const result1 = await service.getAirQuality(lat, lon);
  assert.ok(result1.data);
  assert.ok(result1.data.current.usAqi >= 0);
  assert.ok(result1.data.hourlyForecast.length > 0);

  // Second fetch (should hit cache)
  const result2 = await service.getAirQuality(lat, lon);
  assert.equal(result2.isCached, true);
  assert.equal(result2.data.current.usAqi, result1.data.current.usAqi);
});
