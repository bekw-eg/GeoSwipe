-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "profiles" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "displayName" TEXT NOT NULL,
    "avatarUrl" TEXT,
    "preferredLanguage" TEXT NOT NULL DEFAULT 'ru',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_progress_states" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "lastLevelId" TEXT,
    "unlockedLevels" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "activeHints" JSONB,
    "reviewVariants" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_progress_states_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "level_progresses" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "levelId" TEXT NOT NULL,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "completions" INTEGER NOT NULL DEFAULT 0,
    "assistedCompletions" INTEGER NOT NULL DEFAULT 0,
    "independentCompletions" INTEGER NOT NULL DEFAULT 0,
    "independentReviews" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "level_progresses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "skill_progresses" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "skillId" TEXT NOT NULL,
    "state" TEXT NOT NULL DEFAULT 'notStudied',
    "reviewStage" INTEGER NOT NULL DEFAULT 0,
    "dueAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "skill_progresses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "attempt_records" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "levelId" TEXT NOT NULL,
    "topicId" TEXT NOT NULL,
    "correct" BOOLEAN NOT NULL,
    "hintCount" INTEGER NOT NULL DEFAULT 0,
    "review" BOOLEAN NOT NULL DEFAULT false,
    "scheduledReview" BOOLEAN NOT NULL DEFAULT false,
    "variant" INTEGER NOT NULL DEFAULT 0,
    "answer" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "attempt_records_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_username_key" ON "users"("username");

-- CreateIndex
CREATE UNIQUE INDEX "profiles_userId_key" ON "profiles"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "user_progress_states_userId_key" ON "user_progress_states"("userId");

-- CreateIndex
CREATE INDEX "level_progresses_userId_idx" ON "level_progresses"("userId");

-- CreateIndex
CREATE INDEX "level_progresses_levelId_idx" ON "level_progresses"("levelId");

-- CreateIndex
CREATE UNIQUE INDEX "level_progresses_userId_levelId_key" ON "level_progresses"("userId", "levelId");

-- CreateIndex
CREATE INDEX "skill_progresses_userId_idx" ON "skill_progresses"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "skill_progresses_userId_skillId_key" ON "skill_progresses"("userId", "skillId");

-- CreateIndex
CREATE INDEX "attempt_records_userId_idx" ON "attempt_records"("userId");

-- CreateIndex
CREATE INDEX "attempt_records_userId_levelId_idx" ON "attempt_records"("userId", "levelId");

-- CreateIndex
CREATE INDEX "attempt_records_userId_createdAt_idx" ON "attempt_records"("userId", "createdAt");

-- AddForeignKey
ALTER TABLE "profiles" ADD CONSTRAINT "profiles_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_progress_states" ADD CONSTRAINT "user_progress_states_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "level_progresses" ADD CONSTRAINT "level_progresses_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "skill_progresses" ADD CONSTRAINT "skill_progresses_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attempt_records" ADD CONSTRAINT "attempt_records_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
