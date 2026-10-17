import test from 'node:test';
import assert from 'node:assert/strict';
import { firmsService } from '../src/services/firms.service';
import { calculateHaversineDistanceKm, calculateBoundingBox } from '../src/utils/geo';
import { HotspotRecord } from '../src/models/hotspot.model';

test('Geospatial Utils - Haversine distance accuracy', () => {
  // Banda Aceh (5.5483, 95.3238) to Meulaboh (4.1449, 96.1265) is approx 179 km
  const dist = calculateHaversineDistanceKm(5.5483, 95.3238, 4.1449, 96.1265);
  assert.ok(dist >= 170 && dist <= 190, `Distance was ${dist}`);

  // Same coordinates should be 0 km
  const zeroDist = calculateHaversineDistanceKm(5.5483, 95.3238, 5.5483, 95.3238);
  assert.equal(zeroDist, 0);
});

test('Geospatial Utils - Bounding box derivation', () => {
  const bbox = calculateBoundingBox(5.5483, 95.3238, 50);
  assert.ok(bbox.south < 5.5483);
  assert.ok(bbox.north > 5.5483);
  assert.ok(bbox.west < 95.3238);
  assert.ok(bbox.east > 95.3238);
});

test('NASA FIRMS CSV Parser - Parses standard NRT CSV format correctly', () => {
  const mockCsv = `latitude,longitude,bright_ti4,scan,track,acq_date,acq_time,satellite,instrument,confidence,version,bright_ti5,frp,daynight
5.6234,95.4123,334.8,0.4,0.4,2026-10-17,0430,Suomi-NPP,VIIRS,h,2.0NRT,298.2,14.5,D
5.4112,95.2891,316.5,0.4,0.4,2026-10-17,0430,Suomi-NPP,VIIRS,nominal,2.0NRT,291.0,6.2,D
5.7891,95.1234,308.0,0.5,0.5,2026-10-17,0430,Suomi-NPP,VIIRS,l,2.0NRT,289.4,2.8,D`;

  const parsed = firmsService.parseFirmsCsv(mockCsv, 5.5483, 95.3238);
  assert.equal(parsed.length, 3);

  // Check High confidence record
  assert.equal(parsed[0].confidence, 'high');
  assert.equal(parsed[0].brightness, 334.8);
  assert.equal(parsed[0].frp, 14.5);
  assert.equal(parsed[0].isDemo, false);
  assert.ok(parsed[0].distanceKm !== undefined && parsed[0].distanceKm > 0);

  // Check Nominal confidence record
  assert.equal(parsed[1].confidence, 'nominal');

  // Check Low confidence record
  assert.equal(parsed[2].confidence, 'low');
});

test('Hotspot Deduplication - Removes repeated observations within identical grid hour', () => {
  const duplicates: HotspotRecord[] = [
    {
      id: 'HS-1',
      latitude: 5.5481,
      longitude: 95.3234,
      brightness: 330.0,
      confidence: 'high',
      acquisitionTime: '2026-10-17T04:30:00.000Z',
      satellite: 'Suomi-NPP',
      instrument: 'VIIRS',
      frp: 12.0,
      isDemo: false,
      source: 'NASA FIRMS',
      retrievedAt: '2026-10-17T04:35:00.000Z',
    },
    {
      id: 'HS-2', // Duplicate observation at ~same location and hour
      latitude: 5.5482,
      longitude: 95.3235,
      brightness: 331.0,
      confidence: 'high',
      acquisitionTime: '2026-10-17T04:30:00.000Z',
      satellite: 'Suomi-NPP',
      instrument: 'VIIRS',
      frp: 12.5,
      isDemo: false,
      source: 'NASA FIRMS',
      retrievedAt: '2026-10-17T04:35:00.000Z',
    },
    {
      id: 'HS-3', // Distinct observation at different location
      latitude: 4.8900,
      longitude: 96.2100,
      brightness: 320.0,
      confidence: 'nominal',
      acquisitionTime: '2026-10-17T04:30:00.000Z',
      satellite: 'Suomi-NPP',
      instrument: 'VIIRS',
      frp: 7.0,
      isDemo: false,
      source: 'NASA FIRMS',
      retrievedAt: '2026-10-17T04:35:00.000Z',
    },
  ];

  const unique = firmsService.deduplicateHotspots(duplicates);
  assert.equal(unique.length, 2);
});

test('Hotspots Service - Query default location and retrieve single hotspot by ID', async () => {
  const { hotspots, isCached } = await firmsService.getHotspots({
    centerLat: 5.5483,
    centerLon: 95.3238,
    radiusKm: 100,
  });

  assert.ok(Array.isArray(hotspots));
  assert.equal(typeof isCached, 'boolean');

  // Verify getHotspotById works with known baseline record or first item
  const testId = hotspots.length > 0 ? hotspots[0].id : 'FIRMS-DEMO-AC-01';
  const single = await firmsService.getHotspotById(testId);
  assert.ok(single);
  assert.equal(single?.id, testId);
});
