import express from 'express';
import { signUp } from '#controllers/auth.controller.js';

const authRoutes = express.Router();

// Sign-Up Route
authRoutes.post('/sign-up', signUp);

// Sign-In Route
authRoutes.post('/sign-in', (req, res) => {
  res.send('POST /api/auth/sign-in response');
});

// Sign-Out Route
authRoutes.post('/sign-out', (req, res) => {
  res.send('POST /api/auth/sign-out response');
});

export default authRoutes;
