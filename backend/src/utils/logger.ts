export enum LogLevel {
  DEBUG = 'DEBUG',
  INFO = 'INFO',
  WARN = 'WARN',
  ERROR = 'ERROR',
}

class Logger {
  private sanitize(message: string): string {
    // Redact potential API keys or tokens from logs
    return message
      .replace(/([a-zA-Z0-9]{24,64})/g, (match) => `${match.substring(0, 4)}...[REDACTED]`);
  }

  private log(level: LogLevel, message: string, meta?: unknown) {
    const timestamp = new Date().toISOString();
    const cleanMsg = this.sanitize(message);
    const logLine = `[${timestamp}] [${level}] ${cleanMsg}`;

    if (level === LogLevel.ERROR) {
      console.error(logLine, meta !== undefined ? meta : '');
    } else if (level === LogLevel.WARN) {
      console.warn(logLine, meta !== undefined ? meta : '');
    } else {
      console.log(logLine, meta !== undefined ? meta : '');
    }
  }

  debug(message: string, meta?: unknown) {
    if (process.env.NODE_ENV !== 'production') {
      this.log(LogLevel.DEBUG, message, meta);
    }
  }

  info(message: string, meta?: unknown) {
    this.log(LogLevel.INFO, message, meta);
  }

  warn(message: string, meta?: unknown) {
    this.log(LogLevel.WARN, message, meta);
  }

  error(message: string, meta?: unknown) {
    this.log(LogLevel.ERROR, message, meta);
  }
}

export const logger = new Logger();
