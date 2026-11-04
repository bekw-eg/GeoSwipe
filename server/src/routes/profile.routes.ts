import { Router, Response } from 'express';
import { prisma } from '../db';
import { AuthenticatedRequest, requireAuth } from '../middleware/auth';

export const profileRouter = Router();

profileRouter.use(requireAuth);

// Get current profile
profileRouter.get('/', async (req: AuthenticatedRequest, res: Response, next) => {
  try {
    const userId = req.user!.userId;
    const profile = await prisma.profile.findUnique({
      where: { userId },
    });

    if (!profile) {
      res.status(404).json({ error: 'Профиль табылмады (Profile not found)' });
      return;
    }

    res.json(profile);
  } catch (error) {
    next(error);
  }
});

// Update profile
profileRouter.put('/', async (req: AuthenticatedRequest, res: Response, next) => {
  try {
    const userId = req.user!.userId;
    const { displayName, avatarUrl, preferredLanguage } = req.body;

    const updated = await prisma.profile.upsert({
      where: { userId },
      update: {
        ...(displayName !== undefined ? { displayName: String(displayName).trim() } : {}),
        ...(avatarUrl !== undefined ? { avatarUrl: avatarUrl ? String(avatarUrl) : null } : {}),
        ...(preferredLanguage !== undefined ? { preferredLanguage: String(preferredLanguage) } : {}),
      },
      create: {
        userId,
        displayName: displayName ? String(displayName).trim() : req.user!.username,
        avatarUrl: avatarUrl ? String(avatarUrl) : null,
        preferredLanguage: preferredLanguage || 'ru',
      },
    });

    res.json(updated);
  } catch (error) {
    next(error);
  }
});
