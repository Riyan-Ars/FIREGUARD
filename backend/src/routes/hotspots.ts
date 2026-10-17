import { Router, Request, Response, NextFunction } from 'express';
import { firmsService } from '../services/firms.service';
import { AppError } from '../middleware/errorHandler';
import { HotspotsApiResponse } from '../models/hotspot.model';

export const hotspotsRouter = Router();

const SATELLITE_DISCLAIMER =
  'Thermal anomalies detected by satellites indicate high ground temperatures. ' +
  'They represent potential hotspots, not verified active fires.';

/**
 * GET /api/v1/hotspots
 * Query parameters:
 *   lat: number (-90 to 90)
 *   lon: number (-180 to 180)
 *   radius: number (5 to 300 km, default 50)
 *   days: number (1 to 5, default 1)
 *   confidence: 'all' | 'high' | 'nominal'
 *   sort: 'distance' | 'time' | 'frp'
 */
hotspotsRouter.get('/hotspots', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const latStr = (req.query.latitude || req.query.lat) as string | undefined;
    const lonStr = (req.query.longitude || req.query.lon) as string | undefined;
    const radiusStr = req.query.radius as string | undefined;
    const daysStr = req.query.days as string | undefined;
    const confidence = req.query.confidence as 'all' | 'high' | 'nominal' | undefined;
    const sort = req.query.sort as 'distance' | 'time' | 'frp' | undefined;

    let centerLat: number | undefined;
    let centerLon: number | undefined;

    if (latStr !== undefined || lonStr !== undefined) {
      if (!latStr || !lonStr) {
        throw new AppError('Both latitude (or lat) and longitude (or lon) must be provided when querying coordinates', 400, 'INVALID_COORDINATES');
      }
      centerLat = parseFloat(latStr);
      centerLon = parseFloat(lonStr);

      if (isNaN(centerLat) || centerLat < -90 || centerLat > 90) {
        throw new AppError('Query parameter latitude/lat must be a valid number between -90 and 90', 400, 'INVALID_LATITUDE');
      }
      if (isNaN(centerLon) || centerLon < -180 || centerLon > 180) {
        throw new AppError('Query parameter longitude/lon must be a valid number between -180 and 180', 400, 'INVALID_LONGITUDE');
      }
    }

    const radiusKm = radiusStr ? parseFloat(radiusStr) : 50;
    if (isNaN(radiusKm) || radiusKm < 5 || radiusKm > 300) {
      throw new AppError('Query parameter radius must be a number between 5 and 300 km', 400, 'INVALID_RADIUS');
    }

    const dayRange = daysStr ? parseInt(daysStr, 10) : 1;
    if (isNaN(dayRange) || dayRange < 1 || dayRange > 5) {
      throw new AppError('Query parameter days must be an integer between 1 and 5', 400, 'INVALID_DAY_RANGE');
    }

    const { hotspots, isCached } = await firmsService.getHotspots({
      centerLat,
      centerLon,
      radiusKm,
      dayRange,
      minConfidence: confidence,
      sortBy: sort,
    });

    const nowIso = new Date().toISOString();
    const response = {
      success: true,
      source: 'NASA FIRMS (VIIRS_SNPP_NRT)',
      retrievedAt: nowIso,
      data: hotspots,
      meta: {
        count: hotspots.length,
        center: centerLat !== undefined && centerLon !== undefined ? { latitude: centerLat, longitude: centerLon } : undefined,
        radiusKm,
        isCached,
        dataFreshness: hotspots.length > 0 ? hotspots[0].retrievedAt : nowIso,
        disclaimer: SATELLITE_DISCLAIMER,
      },
    };

    res.status(200).json(response);
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/v1/hotspots/:id
 * Retrieves detail for a specific hotspot observation
 */
hotspotsRouter.get('/hotspots/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const rawId = req.params.id;
    const id = Array.isArray(rawId) ? rawId[0] : rawId;
    if (!id || typeof id !== 'string' || id.trim().length === 0) {
      throw new AppError('Hotspot ID is required', 400, 'INVALID_ID');
    }

    const hotspot = await firmsService.getHotspotById(id);
    if (!hotspot) {
      throw new AppError(`Hotspot not found with ID: ${id}`, 404, 'HOTSPOT_NOT_FOUND');
    }

    res.status(200).json({
      success: true,
      data: hotspot,
      disclaimer: SATELLITE_DISCLAIMER,
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    next(err);
  }
});
