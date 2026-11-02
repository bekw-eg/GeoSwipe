import express from 'express';
import cors from 'cors';
import { authRouter } from './routes/auth.routes';
import { profileRouter } from './routes/profile.routes';
import { progressRouter } from './routes/progress.routes';
import { errorHandler } from './middleware/errorHandler';

export const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'GeoSwipe PostgreSQL Backend API',
    database: 'PostgreSQL',
    timestamp: new Date().toISOString(),
  });
});

// API Routes
app.use('/api/auth', authRouter);
app.use('/api/profile', profileRouter);
app.use('/api/progress', progressRouter);

// Global Error Handler
app.use(errorHandler);
