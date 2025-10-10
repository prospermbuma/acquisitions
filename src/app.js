import express from 'express';
import logger from './config/logger.js';

// Initialize Express app
const app = express();

// Define a route
app.get('/', (req, res) => {
  logger.info('Hello from Acquisitions API!');

  res.status(200).send('Hello from Acquisitions API!');
});

export default app;
