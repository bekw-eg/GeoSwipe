import dotenv from 'dotenv';
import path from 'path';

// Load .env
dotenv.config({ path: path.resolve(__dirname, '../.env') });

export const config = {
  port: parseInt(process.env.PORT || '4000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  databaseUrl: process.env.DATABASE_URL || '',
  jwtSecret: process.env.JWT_SECRET || 'fallback-secret-key-geoswipe',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
};

if (!config.databaseUrl) {
  console.warn('WARNING: DATABASE_URL is not set in environment variables.');
}
