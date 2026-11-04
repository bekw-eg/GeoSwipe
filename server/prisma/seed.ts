import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding PostgreSQL database for GeoSwipe...');

  // Clean existing seed data if any
  await prisma.attemptRecord.deleteMany();
  await prisma.levelProgress.deleteMany();
  await prisma.skillProgress.deleteMany();
  await prisma.userProgressState.deleteMany();
  await prisma.profile.deleteMany();
  await prisma.user.deleteMany();

  const salt = await bcrypt.genSalt(10);
  const demoPasswordHash = await bcrypt.hash('DemoPassword123!', salt);
  const studentPasswordHash = await bcrypt.hash('StudentPassword123!', salt);

  // 1. Demo User
  const demoUser = await prisma.user.create({
    data: {
      email: 'demo@geoswipe.local',
      username: 'demo_user',
      passwordHash: demoPasswordHash,
      profile: {
        create: {
          displayName: 'Демо Пайдаланушы',
          preferredLanguage: 'ru',
        },
      },
      progressState: {
        create: {
          version: 2,
          lastLevelId: 'angle-45',
          unlockedLevels: ['angle-45', 'angle-90', 'angle-135'],
          activeHints: { 'angle-45': 0 },
          reviewVariants: { 'angle-45': 0 },
        },
      },
      levelProgresses: {
        create: [
          {
            levelId: 'angle-45',
            attempts: 3,
            completions: 3,
            assistedCompletions: 1,
            independentCompletions: 2,
            independentReviews: 1,
          },
          {
            levelId: 'angle-90',
            attempts: 2,
            completions: 1,
            assistedCompletions: 0,
            independentCompletions: 1,
            independentReviews: 0,
          },
        ],
      },
      skillProgresses: {
        create: [
          {
            skillId: 'angle-45',
            state: 'independent',
            reviewStage: 1,
            dueAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
          },
        ],
      },
      attemptRecords: {
        create: [
          {
            levelId: 'angle-45',
            topicId: 'angles',
            correct: true,
            hintCount: 0,
            review: false,
            scheduledReview: false,
            variant: 0,
            answer: '45.0',
          },
          {
            levelId: 'angle-45',
            topicId: 'angles',
            correct: true,
            hintCount: 1,
            review: false,
            scheduledReview: false,
            variant: 0,
            answer: '45.0',
          },
        ],
      },
    },
  });

  // 2. Student User (fresh beginner)
  await prisma.user.create({
    data: {
      email: 'student@geoswipe.local',
      username: 'student',
      passwordHash: studentPasswordHash,
      profile: {
        create: {
          displayName: 'Жаңа Оқушы',
          preferredLanguage: 'ru',
        },
      },
      progressState: {
        create: {
          version: 2,
          lastLevelId: 'angle-45',
          unlockedLevels: ['angle-45'],
        },
      },
    },
  });

  console.log(`Database seeded successfully! Demo user: ${demoUser.email}`);
}

main()
  .catch((e) => {
    console.error('Seeding failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
