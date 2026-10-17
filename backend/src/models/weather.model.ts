export interface WeatherCurrent {
  temperature: number; // °C
  relativeHumidity: number; // %
  windSpeed: number; // km/h
  windDirection: number; // degrees (0-360)
  weatherCode?: number;
  isDay?: boolean;
}

export interface WeatherData {
  latitude: number;
  longitude: number;
  current: WeatherCurrent;
  retrievedAt: string;
  source: string;
}
