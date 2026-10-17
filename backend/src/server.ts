import { createApp } from './app';
import { config } from './config';
import { logger } from './utils/logger';

const app = createApp();

const server = app.listen(config.port, () => {
  logger.info(`FIREGUARD Gateway running on port ${config.port} in ${config.nodeEnv} mode`);
  logger.info(`Health check available at http://localhost:${config.port}${config.apiPrefix}/health`);
});

const gracefulShutdown = (signal: string) => {
  logger.info(`Received ${signal}. Shutting down gracefully...`);
  server.close(() => {
    logger.info('HTTP server closed.');
    process.exit(0);
  });

  // Force close if graceful shutdown takes too long
  setTimeout(() => {
    logger.error('Forced shutdown timeout reached.');
    process.exit(1);
  }, 10000).unref();
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

process.on('uncaughtException', (err) => {
  logger.error('Uncaught Exception:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  logger.error('Unhandled Rejection:', reason);
});
