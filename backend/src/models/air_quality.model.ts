export type AqiRiskCategory =
  | 'good'
  | 'moderate'
  | 'unhealthy_sensitive'
  | 'unhealthy'
  | 'very_unhealthy'
  | 'hazardous';

export interface HourlyAqiPoint {
  time: string;
  usAqi: number;
  pm2_5: number;
  pm10?: number;
}

export interface AirQualityCurrent {
  usAqi: number;
  europeanAqi?: number;
  pm2_5: number; // µg/m³
  pm10?: number; // µg/m³
  nitrogenDioxide?: number; // µg/m³
  ozone?: number; // µg/m³
  carbonMonoxide?: number; // µg/m³
  sulphurDioxide?: number; // µg/m³
}

export interface AirQualityData {
  latitude: number;
  longitude: number;
  current: AirQualityCurrent;
  category: AqiRiskCategory;
  categoryLabel: {
    en: string;
    id: string;
  };
  healthAdvice: {
    en: string;
    id: string;
  };
  hourlyForecast: HourlyAqiPoint[];
  standardName: string;
  dataSource: string;
  isModelData: boolean;
  isFallback: boolean;
  updatedAt: string;
}
