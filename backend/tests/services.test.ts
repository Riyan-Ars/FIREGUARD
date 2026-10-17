import test from 'node:test';
import assert from 'node:assert/strict';
import { WeatherService } from '../src/services/weather.service';
import { RecommendationService } from '../src/services/recommendation.service';
import { AlertService } from '../src/services/alert.service';

test('Weather Service - Fetches live Open-Meteo weather and caches result', async () => {
  const service = WeatherService.getInstance();
  const lat = 5.5483;
  const lon = 95.3238;

  const res1 = await service.getWeather(lat, lon);
  assert.ok(res1.data);
  assert.equal(typeof res1.data.current.temperature, 'number');
  assert.equal(typeof res1.data.current.relativeHumidity, 'number');
  assert.equal(typeof res1.data.current.windSpeed, 'number');
  assert.equal(typeof res1.data.current.windDirection, 'number');

  // Second fetch hits cache
  const res2 = await service.getWeather(lat, lon);
  assert.equal(res2.isCached, true);
  assert.equal(res2.data.current.temperature, res1.data.current.temperature);
});

test('Recommendation Service - Synthesizes context into actionable prioritized items', async () => {
  const service = RecommendationService.getInstance();
  const lat = 5.5483;
  const lon = 95.3238;

  const res = await service.getRecommendations(lat, lon);
  assert.ok(res.data);
  assert.ok(Array.isArray(res.data.recommendations));
  assert.ok(res.data.recommendations.length > 0);

  // Each recommendation must have bilingual title and description
  for (const rec of res.data.recommendations) {
    assert.ok(rec.id);
    assert.ok(rec.title.en.length > 0);
    assert.ok(rec.title.id.length > 0);
    assert.ok(rec.description.en.length > 0);
    assert.ok(rec.description.id.length > 0);
    assert.ok(['high', 'medium', 'low'].includes(rec.priority));
  }
});

test('Alert Service - Produces system notices and scans active satellite conditions', async () => {
  const service = AlertService.getInstance();
  const lat = 5.5483;
  const lon = 95.3238;

  const res = await service.getAlerts(lat, lon, 100);
  assert.ok(res.data);
  assert.ok(Array.isArray(res.data.alerts));
  assert.ok(res.data.total >= 1); // Sentinel alert is always active

  const sentinel = res.data.alerts.find((a) => a.id === 'ALT-SYS-NRT');
  assert.ok(sentinel);
  assert.equal(sentinel?.severity, 'info');
});
