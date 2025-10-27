import express from 'express';
import { signUp, signIn, signOut } from '#controllers/auth.controller.js';

const authRoutes = express.Router();

// Sign-Up Route
authRoutes.post('/sign-up', signUp);

// Sign-In Route
authRoutes.post('/sign-in', signIn);

// Sign-Out Route
authRoutes.post('/sign-out', signOut);

export default authRoutes;
