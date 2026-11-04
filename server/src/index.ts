import { app } from './app';
import { config } from './config';
import { prisma } from './db';

const server = app.listen(config.port, () => {
  console.log(`🚀 GeoSwipe PostgreSQL Backend is running on port ${config.port}`);
  console.log(`🔗 Health check available at http://localhost:${config.port}/health`);
});

// Graceful shutdown
const shutdown = async () => {
  console.log('Shutting down server gracefully...');
  server.close(async () => {
    await prisma.$disconnect();
    console.log('Database disconnected. Process terminated.');
    process.exit(0);
  });
};

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
