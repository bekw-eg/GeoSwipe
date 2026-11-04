import { test, describe, before, after } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import { app } from '../src/app';
import { prisma } from '../src/db';

describe('GeoSwipe PostgreSQL Backend API Test Suite', () => {
  let authToken = '';
  let studentToken = '';
  let userId = '';

  before(async () => {
    // Ensure clean state for test users
    await prisma.attemptRecord.deleteMany();
    await prisma.levelProgress.deleteMany();
    await prisma.skillProgress.deleteMany();
    await prisma.userProgressState.deleteMany();
    await prisma.profile.deleteMany();
    await prisma.user.deleteMany();
  });

  after(async () => {
    await prisma.$disconnect();
  });

  describe('Health Check', () => {
    test('GET /health returns 200 and healthy status', async () => {
      const res = await request(app).get('/health');
      assert.equal(res.status, 200);
      assert.equal(res.body.status, 'ok');
      assert.equal(res.body.database, 'PostgreSQL');
    });
  });

  describe('Authentication & Security', () => {
    test('POST /api/auth/register registers a new user with hashed password and profile', async () => {
      const res = await request(app).post('/api/auth/register').send({
        email: 'tester@geoswipe.local',
        username: 'tester',
        password: 'Password123!',
        displayName: 'Тесттік Пайдаланушы',
      });

      assert.equal(res.status, 201);
      assert.ok(res.body.token);
      assert.equal(res.body.user.email, 'tester@geoswipe.local');
      assert.equal(res.body.profile.displayName, 'Тесттік Пайдаланушы');
      authToken = res.body.token;
      userId = res.body.user.id;
    });

    test('POST /api/auth/register rejects duplicate email or username with 409', async () => {
      const res = await request(app).post('/api/auth/register').send({
        email: 'tester@geoswipe.local',
        username: 'another_user',
        password: 'Password123!',
      });
      assert.equal(res.status, 409);

      const res2 = await request(app).post('/api/auth/register').send({
        email: 'other@geoswipe.local',
        username: 'tester',
        password: 'Password123!',
      });
      assert.equal(res2.status, 409);
    });

    test('POST /api/auth/login validates credentials and returns token', async () => {
      const res = await request(app).post('/api/auth/login').send({
        identifier: 'tester@geoswipe.local',
        password: 'Password123!',
      });

      assert.equal(res.status, 200);
      assert.ok(res.body.token);

      // Invalid password
      const badRes = await request(app).post('/api/auth/login').send({
        identifier: 'tester@geoswipe.local',
        password: 'WrongPassword!',
      });
      assert.equal(badRes.status, 401);
    });

    test('Protected routes reject requests without token with 401', async () => {
      const res = await request(app).get('/api/auth/me');
      assert.equal(res.status, 401);

      const res2 = await request(app).get('/api/progress');
      assert.equal(res2.status, 401);
    });

    test('GET /api/auth/me returns current user info when authenticated', async () => {
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${authToken}`);

      assert.equal(res.status, 200);
      assert.equal(res.body.user.email, 'tester@geoswipe.local');
      assert.equal(res.body.profile.displayName, 'Тесттік Пайдаланушы');
    });
  });

  describe('Profile CRUD', () => {
    test('GET /api/profile and PUT /api/profile updates user profile', async () => {
      const getRes = await request(app)
        .get('/api/profile')
        .set('Authorization', `Bearer ${authToken}`);
      assert.equal(getRes.status, 200);

      const updateRes = await request(app)
        .put('/api/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          displayName: 'Жаңартылған Ат',
          preferredLanguage: 'kk',
        });

      assert.equal(updateRes.status, 200);
      assert.equal(updateRes.body.displayName, 'Жаңартылған Ат');
      assert.equal(updateRes.body.preferredLanguage, 'kk');
    });
  });

  describe('Progress Synchronization & PostgreSQL Persistence', () => {
    test('PUT /api/progress saves snapshot transactionally into PostgreSQL', async () => {
      const snapshot = {
        version: 1,
        lastLevelId: 'angle-45',
        levels: {
          'angle-45': {
            attempts: 5,
            completions: 4,
            assistedCompletions: 1,
            independentCompletions: 3,
            independentReviews: 1,
          },
          'angle-90': {
            attempts: 2,
            completions: 2,
            assistedCompletions: 0,
            independentCompletions: 2,
            independentReviews: 0,
          },
        },
      };

      const res = await request(app)
        .put('/api/progress')
        .set('Authorization', `Bearer ${authToken}`)
        .send(snapshot);

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
    });

    test('GET /api/progress retrieves persisted snapshot matching GeoSwipe format', async () => {
      const res = await request(app)
        .get('/api/progress')
        .set('Authorization', `Bearer ${authToken}`);

      assert.equal(res.status, 200);
      assert.equal(res.body.lastLevelId, 'angle-45');
      assert.ok(res.body.levels['angle-45']);
      assert.equal(res.body.levels['angle-45'].attempts, 5);
      assert.equal(res.body.levels['angle-45'].completions, 4);
      assert.equal(res.body.levels['angle-45'].independentCompletions, 3);
    });

    test('POST /api/progress/attempt atomically adds attempt and updates level progress', async () => {
      const res = await request(app)
        .post('/api/progress/attempt')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          levelId: 'angle-45',
          topicId: 'angles',
          correct: true,
          hintCount: 0,
          review: false,
          answer: '45.0',
        });

      assert.equal(res.status, 201);
      assert.equal(res.body.attempt.correct, true);
      assert.equal(res.body.levelProgress.attempts, 6); // was 5 + 1
      assert.equal(res.body.levelProgress.completions, 5); // was 4 + 1
      assert.equal(res.body.levelProgress.independentCompletions, 4); // was 3 + 1
    });

    test('GET /api/progress/history returns recorded attempts with pagination', async () => {
      const res = await request(app)
        .get('/api/progress/history?limit=10&offset=0')
        .set('Authorization', `Bearer ${authToken}`);

      assert.equal(res.status, 200);
      assert.ok(res.body.total >= 1);
      assert.equal(res.body.data[0].levelId, 'angle-45');
    });

    test('Ensures user data isolation (User B cannot access User A data)', async () => {
      // Register second user
      const studentRes = await request(app).post('/api/auth/register').send({
        email: 'student2@geoswipe.local',
        username: 'student2',
        password: 'Password123!',
      });
      studentToken = studentRes.body.token;

      // Student progress should be empty / fresh
      const res = await request(app)
        .get('/api/progress')
        .set('Authorization', `Bearer ${studentToken}`);

      assert.equal(res.status, 200);
      // Student has no level attempts for angle-45
      assert.equal(res.body.levels['angle-45'], undefined);
    });

    test('DELETE /api/progress resets and removes user progress data', async () => {
      const delRes = await request(app)
        .delete('/api/progress')
        .set('Authorization', `Bearer ${authToken}`);

      assert.equal(delRes.status, 200);
      assert.equal(delRes.body.success, true);

      // Verify empty progress
      const checkRes = await request(app)
        .get('/api/progress')
        .set('Authorization', `Bearer ${authToken}`);

      assert.equal(checkRes.status, 200);
      assert.deepEqual(checkRes.body.levels, {});
    });
  });
});
