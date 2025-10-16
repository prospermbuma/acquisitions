import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import logger from '#config/logger.js';

// Import routes
import authRoutes from '#routes/auth.routes.js';

// Initialize Express app
const app = express();

// Middleware for security headers
app.use(helmet());

// Middleware for enabling CORS
app.use(cors());

// Middleware for parsing cookies
app.use(cookieParser());

// Middleware for parsing JSON requests
app.use(express.json());

// Middleware for parsing URL-encoded requests
app.use(express.urlencoded({ extended: true }));

// Middleware for logging HTTP requests
app.use(
  morgan('combined', {
    stream: { write: message => logger.info(message.trim()) },
  })
);

// Default route
app.get('/', (req, res) => {
  logger.info('Hello from Acquisitions API!');

  res.status(200).send('Hello from Acquisitions API!');
});

// Health check route
app.get('/health', (req, res) => {
  res.status(200).send({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

app.get('/api/', (req, res) => {
  res.status(200).json({ message: 'Acquisitions API is running!' });
});

// Use API routes
app.use('/api/v1/auth', authRoutes);

export default app;
