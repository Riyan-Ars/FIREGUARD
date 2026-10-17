import { appCache } from '../utils/cache';
import { logger } from '../utils/logger';
import { WeatherData, WeatherCurrent } from '../models/weather.model';
import { AppError } from '../middleware/errorHandler';

export class WeatherService {
  private static instance: WeatherService;

  public static getInstance(): WeatherService {
    if (!WeatherService.instance) {
      WeatherService.instance = new WeatherService();
    }
    return WeatherService.instance;
  }

  /**
   * Fetch weather data for given coordinates from Open-Meteo Weather Forecast API.
   * Note: Weather data is strictly meteorological and does not imply smoke dispersion alone.
   */
  public async getWeather(
    latitude: number,
    longitude: number
  ): Promise<{ data: WeatherData; isCached: boolean }> {
    const cacheKey = `weather:${latitude.toFixed(2)}:${longitude.toFixed(2)}`;
    const cached = appCache.get<WeatherData>(cacheKey);

    if (cached) {
      return { data: cached, isCached: true };
    }

    logger.info(`Cache MISS for ${cacheKey}. Fetching Open-Meteo weather...`);

    const url = new URL('https://api.open-meteo.com/v1/forecast');
    url.searchParams.set('latitude', latitude.toString());
    url.searchParams.set('longitude', longitude.toString());
    url.searchParams.set(
      'current',
      'temperature_2m,relative_humidity_2m,wind_speed_10m,wind_direction_10m,weather_code,is_day'
    );
    url.searchParams.set('timezone', 'auto');

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8000);

    try {
      const res = await fetch(url.toString(), {
        signal: controller.signal,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'FIREGUARD-WeatherGateway/1.0',
        },
      });

      if (!res.ok) {
        throw new AppError(
          `Open-Meteo Weather API returned status ${res.status}: ${res.statusText}`,
          res.status === 429 ? 429 : 502,
          'WEATHER_PROVIDER_ERROR'
        );
      }

      const json = await res.json() as {
        current?: Record<string, unknown>;
      };

      const cur = json.current || {};
      const current: WeatherCurrent = {
        temperature: typeof cur.temperature_2m === 'number' ? cur.temperature_2m : 25.0,
        relativeHumidity: typeof cur.relative_humidity_2m === 'number' ? cur.relative_humidity_2m : 70,
        windSpeed: typeof cur.wind_speed_10m === 'number' ? cur.wind_speed_10m : 5.0,
        windDirection: typeof cur.wind_direction_10m === 'number' ? cur.wind_direction_10m : 0,
        weatherCode: typeof cur.weather_code === 'number' ? cur.weather_code : undefined,
        isDay: typeof cur.is_day === 'number' ? cur.is_day === 1 : undefined,
      };

      const result: WeatherData = {
        latitude,
        longitude,
        current,
        retrievedAt: new Date().toISOString(),
        source: 'Open-Meteo Weather API',
      };

      // Cache for 10 minutes (600 seconds)
      appCache.set(cacheKey, result, 600);

      return { data: result, isCached: false };
    } catch (err: unknown) {
      if (err instanceof AppError) throw err;
      const msg = err instanceof Error ? err.message : String(err);
      throw new AppError(
        `Failed to reach Open-Meteo Weather service: ${msg}`,
        502,
        'WEATHER_PROVIDER_UNAVAILABLE'
      );
    } finally {
      clearTimeout(timeout);
    }
  }
}
