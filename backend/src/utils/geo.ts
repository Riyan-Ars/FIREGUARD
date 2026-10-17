const EARTH_RADIUS_KM = 6371.0;

/**
 * Calculates the great-circle distance between two geographic coordinates using the Haversine formula.
 */
export function calculateHaversineDistanceKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return parseFloat((EARTH_RADIUS_KM * c).toFixed(2));
}

function toRadians(degrees: number): number {
  return (degrees * Math.PI) / 180.0;
}

export interface BoundingBox {
  south: number;
  west: number;
  north: number;
  east: number;
}

/**
 * Derives a latitude/longitude bounding box from a center point and a radius in kilometers.
 * 1 degree latitude ≈ 111 km.
 */
export function calculateBoundingBox(
  centerLat: number,
  centerLon: number,
  radiusKm: number
): BoundingBox {
  const deltaLat = radiusKm / 111.0;
  // Adjust longitude delta for latitude convergence: 111 * cos(lat)
  const cosLat = Math.cos(toRadians(centerLat));
  const deltaLon = radiusKm / (111.0 * (Math.abs(cosLat) > 0.01 ? Math.abs(cosLat) : 1));

  return {
    south: parseFloat((centerLat - deltaLat).toFixed(4)),
    west: parseFloat((centerLon - deltaLon).toFixed(4)),
    north: parseFloat((centerLat + deltaLat).toFixed(4)),
    east: parseFloat((centerLon + deltaLon).toFixed(4)),
  };
}
