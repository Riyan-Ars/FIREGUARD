export type HotspotConfidence = 'low' | 'nominal' | 'high';

export interface HotspotRecord {
  id: string;
  latitude: number;
  longitude: number;
  brightness: number; // Brightness temperature in Kelvin
  confidence: HotspotConfidence;
  confidenceScore?: number; // Numeric 0-100 if provided by sensor
  acquisitionTime: string; // ISO 8601 UTC
  satellite: string; // e.g. "Suomi-NPP", "NOAA-20", "Aqua", "Terra"
  instrument: string; // e.g. "VIIRS 375m", "MODIS 1km"
  frp: number; // Fire Radiative Power (MW)
  daynight?: 'D' | 'N';
  distanceKm?: number; // Calculated distance from requested monitoring location
  isDemo: boolean; // Explicitly true if from fallback/demo dataset, false if live satellite
  source: string; // Attribution, e.g. "NASA FIRMS (VIIRS NRT)"
  retrievedAt: string; // ISO 8601 UTC when data was ingested by gateway
}

export interface HotspotQueryOptions {
  centerLat?: number;
  centerLon?: number;
  radiusKm?: number;
  dayRange?: number;
  minConfidence?: 'all' | 'high' | 'nominal';
  sortBy?: 'distance' | 'time' | 'frp';
}

export interface HotspotsApiResponse {
  success: boolean;
  data: HotspotRecord[];
  meta: {
    count: number;
    center?: { latitude: number; longitude: number };
    radiusKm?: number;
    isCached: boolean;
    dataFreshness: string;
    disclaimer: string;
  };
}
