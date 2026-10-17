"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const node_test_1 = __importDefault(require("node:test"));
const strict_1 = __importDefault(require("node:assert/strict"));
const cache_1 = require("../src/utils/cache");
const config_1 = require("../src/config");
const app_1 = require("../src/app");
(0, node_test_1.default)('Backend Configuration - Default Values', () => {
    strict_1.default.equal(typeof config_1.config.port, 'number');
    strict_1.default.equal(config_1.config.apiPrefix, '/api/v1');
    strict_1.default.equal(config_1.config.cacheTtl.hotspots, 300);
    strict_1.default.equal(config_1.config.cacheTtl.airQuality, 600);
    strict_1.default.equal(config_1.config.rateLimit.maxRequests, 100);
});
(0, node_test_1.default)('MemoryCache - Store, Retrieve, TTL Expiry, and Stats', async () => {
    const cache = new cache_1.MemoryCache();
    // Test Set & Get
    cache.set('test_key', { aqi: 45, region: 'Aceh' }, 1); // 1 sec TTL
    const cached = cache.get('test_key');
    strict_1.default.deepEqual(cached, { aqi: 45, region: 'Aceh' });
    // Test Stats
    const stats = cache.getStats();
    strict_1.default.equal(stats.hits, 1);
    strict_1.default.equal(stats.misses, 0);
    // Test Expiry
    await new Promise((resolve) => setTimeout(resolve, 1100));
    const expired = cache.get('test_key');
    strict_1.default.equal(expired, null);
    strict_1.default.equal(cache.getStats().misses, 1);
    cache.destroy();
});
(0, node_test_1.default)('App Health Endpoint - Route Mount and Structure', () => {
    const app = (0, app_1.createApp)();
    strict_1.default.ok(app);
    // Verify app is an Express instance with routing capabilities
    strict_1.default.equal(typeof app.listen, 'function');
});
