export interface RecommendationItem {
  id: string;
  category: 'health' | 'indoor' | 'activity' | 'emergency';
  priority: 'high' | 'medium' | 'low';
  title: {
    en: string;
    id: string;
  };
  description: {
    en: string;
    id: string;
  };
  rationale: string;
}

export interface EnvironmentalContext {
  latitude: number;
  longitude: number;
  usAqi?: number;
  pm2_5?: number;
  nearestHotspotDistanceKm?: number;
  activeHotspotsCount?: number;
}

export interface RecommendationsResponse {
  context: EnvironmentalContext;
  recommendations: RecommendationItem[];
  retrievedAt: string;
  source: string;
}
