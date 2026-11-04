import { Router, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../db';
import { config } from '../config';
import { AuthenticatedRequest, requireAuth } from '../middleware/auth';

export const authRouter = Router();

// Register new user
authRouter.post('/register', async (req, res, next) => {
  try {
    const { email, username, password, displayName } = req.body;

    if (!email || typeof email !== 'string' || !email.includes('@')) {
      res.status(400).json({ error: 'Жарамды email көрсетіңіз (Valid email required)' });
      return;
    }

    if (!username || typeof username !== 'string' || username.trim().length < 3) {
      res.status(400).json({ error: 'Пайдаланушы аты кемінде 3 таңба болуы керек (Username min 3 chars)' });
      return;
    }

    if (!password || typeof password !== 'string' || password.length < 6) {
      res.status(400).json({ error: 'Құпиясөз кемінде 6 таңба болуы керек (Password min 6 chars)' });
      return;
    }

    const cleanEmail = email.toLowerCase().trim();
    const cleanUsername = username.trim();

    // Check existing
    const existing = await prisma.user.findFirst({
      where: {
        OR: [{ email: cleanEmail }, { username: cleanUsername }],
      },
    });

    if (existing) {
      res.status(409).json({
        error: existing.email === cleanEmail
          ? 'Бұл email тіркелген (Email already registered)'
          : 'Бұл пайдаланушы аты бос емес (Username already taken)',
      });
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // Create user, profile, and initial progress state in a transaction
    const newUser = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          email: cleanEmail,
          username: cleanUsername,
          passwordHash,
          profile: {
            create: {
              displayName: displayName || cleanUsername,
              preferredLanguage: 'ru',
            },
          },
          progressState: {
            create: {
              version: 1,
              lastLevelId: 'angle-45',
              unlockedLevels: ['angle-45'],
            },
          },
        },
        include: {
          profile: true,
        },
      });
      return user;
    });

    const token = jwt.sign(
      {
        userId: newUser.id,
        email: newUser.email,
        username: newUser.username,
      },
      config.jwtSecret,
      { expiresIn: '7d' }
    );

    res.status(201).json({
      token,
      user: {
        id: newUser.id,
        email: newUser.email,
        username: newUser.username,
      },
      profile: newUser.profile,
    });
  } catch (error) {
    next(error);
  }
});

// Login
authRouter.post('/login', async (req, res, next) => {
  try {
    const { identifier, password } = req.body;

    if (!identifier || !password) {
      res.status(400).json({ error: 'Email/username және құпиясөз қажет (Identifier and password required)' });
      return;
    }

    const cleanIdentifier = String(identifier).trim().toLowerCase();

    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { email: cleanIdentifier },
          { username: cleanIdentifier },
        ],
      },
      include: {
        profile: true,
      },
    });

    if (!user) {
      res.status(401).json({ error: 'Пайдаланушы табылмады немесе құпиясөз қате (Invalid credentials)' });
      return;
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      res.status(401).json({ error: 'Пайдаланушы табылмады немесе құпиясөз қате (Invalid credentials)' });
      return;
    }

    const token = jwt.sign(
      {
        userId: user.id,
        email: user.email,
        username: user.username,
      },
      config.jwtSecret,
      { expiresIn: '7d' }
    );

    res.status(200).json({
      token,
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
      },
      profile: user.profile,
    });
  } catch (error) {
    next(error);
  }
});

// Get current user profile
authRouter.get('/me', requireAuth, async (req: AuthenticatedRequest, res: Response, next) => {
  try {
    const userId = req.user!.userId;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        profile: true,
      },
    });

    if (!user) {
      res.status(404).json({ error: 'Пайдаланушы табылмады (User not found)' });
      return;
    }

    res.json({
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        createdAt: user.createdAt,
      },
      profile: user.profile,
    });
  } catch (error) {
    next(error);
  }
});
