export type AlertType = 'hotspotThermal' | 'airQualityDegraded' | 'systemNotice';
export type AlertSeverity = 'info' | 'warning' | 'critical';

export interface AlertRecord {
  id: string;
  type: AlertType;
  severity: AlertSeverity;
  title: string;
  summary: string;
  locationName: string;
  distanceKm?: number;
  eventTime: string;
  source: string;
}

export interface AlertsResponse {
  alerts: AlertRecord[];
  total: number;
  retrievedAt: string;
  source: string;
}
