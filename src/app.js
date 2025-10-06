import express from 'express';
import dotenv from 'dotenv';

// Initialize Express app
const app = express();

// Load environment variables from .env file
dotenv.config();

// Set the port
const PORT = process.env.PORT || 3000;

// Define a route
app.get('/', (req, res) => {
  res.send('The API is working!');
});

// Start the server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});