import express from 'express';

// Initialize Express app
const app = express();

// Define a route
app.get('/', (req, res) => {
  res.status(200).send('The Acquisitions API is working!');
});

export default app; 