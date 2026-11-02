import { Router, Response } from 'express';
import { prisma } from '../db';
import { AuthenticatedRequest, requireAuth } from '../middleware/auth';

export const progressRouter = Router();

progressRouter.use(requireAuth);

// GET /api/progress - Returns full ProgressSnapshot for Flutter client
progressRouter.get('/', async (req: AuthenticatedRequest, res: Response, next) => {
  try {
    const userId = req.user!.userId;

    const [state, levelList, skillList, historyList] = await Promise.all([
      prisma.userProgressState.findUnique({ where: { userId } }),
      prisma.levelProgress.findMany({ where: { userId } }),
      prisma.skillProgress.findMany({ where: { userId } }),
      prisma.attemptRecord.findMany({
        where: { userId },
        orderBy: { createdAt: 'asc' },
      }),
    ]);

    const levelsMap: Record<string, any> = {};
    for (const lp of levelList) {
      levelsMap[lp.levelId] = {
        attempts: lp.attempts,
        completions: lp.completions,
        assistedCompletions: lp.assistedCompletions,
        independentCompletions: lp.independentCompletions,
        independentReviews: lp.independentReviews,
      };
    }

    const skillsMap: Record<string, any> = {};
    for (const sp of skillList) {
      skillsMap[sp.skillId] = {
        state: sp.state,
        reviewStage: sp.reviewStage,
        dueAt: sp.dueAt ? sp.dueAt.toISOString() : null,
      };
    }

    const historyArray = historyList.map((h) => ({
      levelId: h.levelId,
      topicId: h.topicId,
      at: h.createdAt.toISOString(),
      correct: h.correct,
      hintCount: h.hintCount,
      review: h.review,
      scheduledReview: h.scheduledReview,
      variant: h.variant,
      answer: h.answer,
    }));

    const version = state?.version || 1;

    // Build standard GeoSwipe progress snapshot
    const responsePayload: Record<string, any> = {
      version,
      lastLevelId: state?.lastLevelId || null,
      levels: levelsMap,
    };

    // If version 2, include learning progress fields
    if (version >= 2 || Object.keys(skillsMap).length > 0 || historyArray.length > 0) {
      responsePayload.version = 2;
      responsePayload.skills = skillsMap;
      responsePayload.history = historyArray;
      responsePayload.unlocked = state?.unlockedLevels || [];
      responsePayload.activeHints = (state?.activeHints as Record<string, number>) || {};
      responsePayload.reviewVariants = (state?.reviewVariants as Record<string, number>) || {};
    }

    res.json(responsePayload);
  } catch (error) {
    next(error);
  }
});

// PUT /api/progress - Syncs entire ProgressSnapshot transactionally
progressRouter.put('/', async (req: AuthenticatedRequest, res: Response, next) => {
  try {
    const userId = req.user!.userId;
    const {
      version = 1,
      lastLevelId,
      levels = {},
      skills = {},
      unlocked = [],
      activeHints,
      reviewVariants,
    } = req.body;

    if (typeof levels !== 'object' || levels === null) {
      res.status(400).json({ error: 'Жарамсыз деңгейлер құрылымы (Invalid levels structure)' });
      return;
    }

    await prisma.$transaction(async (tx) => {
      // 1. Upsert UserProgressState
      await tx.userProgressState.upsert({
        where: { userId },
        update: {
          version: Number(version) || 1,
          lastLevelId: lastLevelId ? String(lastLevelId) : null,
          unlockedLevels: Array.isArray(unlocked) ? unlocked.map(String) : [],
          activeHints: activeHints ?? undefined,
          reviewVariants: reviewVariants ?? undefined,
        },
        create: {
          userId,
          version: Number(version) || 1,
          lastLevelId: lastLevelId ? String(lastLevelId) : null,
          unlockedLevels: Array.isArray(unlocked) ? unlocked.map(String) : [],
          activeHints: activeHints ?? undefined,
          reviewVariants: reviewVariants ?? undefined,
        },
      });

      // 2. Upsert each LevelProgress
      for (const [levelId, progress] of Object.entries(levels as Record<string, any>)) {
        if (!progress || typeof progress !== 'object') continue;

        const attempts = Math.max(0, Number(progress.attempts) || 0);
        const completions = Math.max(0, Number(progress.completions) || 0);
        const assistedCompletions = Math.max(0, Number(progress.assistedCompletions) || 0);
        const independentCompletions = Math.max(0, Number(progress.independentCompletions) || 0);
        const independentReviews = Math.max(0, Number(progress.independentReviews) || 0);

        await tx.levelProgress.upsert({
          where: {
            userId_levelId: {
              userId,
              levelId,
            },
          },
          update: {
            attempts,
            completions,
            assistedCompletions,
            independentCompletions,
            independentReviews,
          },
          create: {
            userId,
            levelId,
            attempts,
            completions,
            assistedCompletions,
            independentCompletions,
            independentReviews,
          },
        });
      }

      // 3. Upsert skills if present
      if (skills && typeof skills === 'object') {
        for (const [skillId, sp] of Object.entries(skills as Record<string, any>)) {
          if (!sp || typeof sp !== 'object') continue;

          const state = String(sp.state || 'notStudied');
          const reviewStage = Math.max(0, Math.min(3, Number(sp.reviewStage) || 0));
          const dueAt = sp.dueAt ? new Date(sp.dueAt) : null;

          await tx.skillProgress.upsert({
            where: {
              userId_skillId: {
                userId,
                skillId,
              },
            },
            update: {
              state,
              reviewStage,
              dueAt,
            },
            create: {
              userId,
              skillId,
              state,
              reviewStage,
              dueAt,
            },
          });
        }
      }
    });

    res.json({ success: true, message: 'Прогресс сәтті сақталды (Progress synced successfully)' });
  } catch (error) {
    next(error);
  }
});

// POST /api/progress/attempt - Records a single attempt and atomically updates level progress
progressRouter.post('/attempt', async (req: AuthenticatedRequest, res: Response, next) => {
  try {
    const userId = req.user!.userId;
    const {
      levelId,
      topicId = 'general',
      correct,
      hintCount = 0,
      review = false,
      scheduledReview = false,
      variant = 0,
      answer = '',
    } = req.body;

    if (!levelId || typeof correct !== 'boolean') {
      res.status(400).json({ error: 'levelId және correct өрістері міндетті (levelId and boolean correct required)' });
      return;
    }

    const isCorrect = Boolean(correct);
    const hints = Math.max(0, Number(hintCount) || 0);
    const isReview = Boolean(review);
    const isScheduled = Boolean(scheduledReview);
    const varNum = Number(variant) || 0;
    const ansStr = String(answer || '');

    const result = await prisma.$transaction(async (tx) => {
      // 1. Create AttemptRecord
      const attempt = await tx.attemptRecord.create({
        data: {
          userId,
          levelId: String(levelId),
          topicId: String(topicId),
          correct: isCorrect,
          hintCount: hints,
          review: isReview,
          scheduledReview: isScheduled,
          variant: varNum,
          answer: ansStr,
        },
      });

      // 2. Fetch existing level progress
      const existing = await tx.levelProgress.findUnique({
        where: {
          userId_levelId: {
            userId,
            levelId: String(levelId),
          },
        },
      });

      const currentAttempts = existing ? existing.attempts : 0;
      const currentCompletions = existing ? existing.completions : 0;
      const currentAssisted = existing ? existing.assistedCompletions : 0;
      const currentIndep = existing ? existing.independentCompletions : 0;
      const currentReviews = existing ? existing.independentReviews : 0;

      const newAttempts = currentAttempts + 1;
      const newCompletions = currentCompletions + (isCorrect ? 1 : 0);
      const newAssisted = currentAssisted + (isCorrect && hints > 0 ? 1 : 0);
      const newIndep = currentIndep + (isCorrect && hints === 0 ? 1 : 0);
      const newReviews = currentReviews + (isCorrect && hints === 0 && isReview ? 1 : 0);

      const updatedProgress = await tx.levelProgress.upsert({
        where: {
          userId_levelId: {
            userId,
            levelId: String(levelId),
          },
        },
        update: {
          attempts: newAttempts,
          completions: newCompletions,
          assistedCompletions: newAssisted,
          independentCompletions: newIndep,
          independentReviews: newReviews,
        },
        create: {
          userId,
          levelId: String(levelId),
          attempts: newAttempts,
          completions: newCompletions,
          assistedCompletions: newAssisted,
          independentCompletions: newIndep,
          independentReviews: newReviews,
        },
      });

      return { attempt, levelProgress: updatedProgress };
    });

    res.status(201).json(result);
  } catch (error) {
    next(error);
  }
});

// GET /api/progress/levels - Returns all level progresses
progressRouter.get('/levels', async (req: AuthenticatedRequest, res: Response, next) => {
  try {
    const userId = req.user!.userId;
    const levels = await prisma.levelProgress.findMany({
      where: { userId },
      orderBy: { levelId: 'asc' },
    });
    res.json(levels);
  } catch (error) {
    next(error);
  }
});

// GET /api/progress/history - Returns attempt history with pagination
progressRouter.get('/history', async (req: AuthenticatedRequest, res: Response, next) => {
  try {
    const userId = req.user!.userId;
    const { limit = '50', offset = '0', levelId } = req.query;

    const take = Math.min(100, Math.max(1, parseInt(limit as string, 10) || 50));
    const skip = Math.max(0, parseInt(offset as string, 10) || 0);

    const where: any = { userId };
    if (levelId) {
      where.levelId = String(levelId);
    }

    const [attempts, total] = await Promise.all([
      prisma.attemptRecord.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take,
        skip,
      }),
      prisma.attemptRecord.count({ where }),
    ]);

    res.json({
      total,
      limit: take,
      offset: skip,
      data: attempts,
    });
  } catch (error) {
    next(error);
  }
});
