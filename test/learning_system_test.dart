import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoswipe/core/app_controller.dart';
import 'package:geoswipe/core/geometry/geometry.dart';
import 'package:geoswipe/core/learning_explanation.dart';
import 'package:geoswipe/data/level_catalog.dart';
import 'package:geoswipe/data/progress_repository.dart';
import 'package:geoswipe/data/review_variants.dart';
import 'package:geoswipe/models/learning_progress.dart';
import 'package:geoswipe/models/level.dart';
import 'package:geoswipe/models/progress.dart';
import 'support/course_solutions.dart';
import 'support/memory_store.dart';
import 'support/review_solutions.dart';

class DiskStore implements ProgressStore {
  DiskStore(this.file);
  final File file;
  @override
  Future<String?> read() async =>
      await file.exists() ? file.readAsString() : null;
  @override
  Future<void> write(String value) => file.writeAsString(value, flush: true);
}

void main() {
  final first = levels.first;
  late DateTime time;
  late MemoryStore store;
  late AppController app;
  setUp(() async {
    time = DateTime.utc(2026, 10, 16, 10);
    store = MemoryStore();
    app = AppController(ProgressRepository(store), clock: () => time);
    await app.load();
  });
  tearDown(() async {
    await app.persist();
    app.dispose();
  });

  void completeFirst({bool hint = false}) {
    if (hint) app.showHint(first);
    enterSolution(app, first);
    expect(app.submit(first).isCorrect, isTrue);
  }

  void reviewNow() {
    app.startReview(levelId: first.id);
    solveReview(app);
    expect(app.submit(app.reviewLevel!, review: true).isCorrect, isTrue);
  }

  test(
    'all skills start unstudied; opening/failed attempts means studying',
    () {
      expect(
        levels.every((l) => app.skill(l).state == SkillState.notStudied),
        isTrue,
      );
      app.openLevel(0);
      expect(app.skill(first).state, SkillState.studying);
      app.submit(first);
      expect(app.skill(first).state, SkillState.studying);
      expect(app.skill(first).dueAt, isNull);
      expect(app.progress.history.single.correct, isFalse);
    },
  );
  test(
    'three hints persist before submission, including input restart',
    () async {
      for (var i = 0; i < 4; i++) {
        app.showHint(first);
      }
      expect(app.puzzle(first).hintCount, 3);
      app.restart(first);
      expect(app.puzzle(first).hintCount, 3);
      await app.persist();
      final restored = AppController(
        ProgressRepository(store),
        clock: () => time,
      );
      await restored.load();
      expect(restored.puzzle(first).hintCount, 3);
      enterSolution(restored, first);
      restored.submit(first);
      expect(restored.skill(first).state, SkillState.assisted);
      expect(restored.progress.history.single.hintCount, 3);
      expect(restored.progress.history.single.at, time);
      expect(restored.masteredCount, 0);
      await restored.persist();
      restored.dispose();
    },
  );
  test(
    'intervals are exactly 1, 3, 7 days; only due independent variants confirm',
    () {
      completeFirst();
      expect(app.skill(first).state, SkillState.independent);
      expect(app.skill(first).dueAt, time.add(const Duration(days: 1)));
      time = time.add(
        const Duration(days: 1) - const Duration(microseconds: 1),
      );
      expect(app.dueLevels, isEmpty);
      time = time.add(const Duration(microseconds: 1));
      expect(app.dueLevels, [first]);
      for (final days in [3, 7, 7]) {
        reviewNow();
        expect(app.skill(first).dueAt, time.add(Duration(days: days)));
        time = app.skill(first).dueAt!;
      }
      expect(app.skill(first).reviewStage, 3);
      expect(app.skill(first).state, SkillState.confirmed);
      expect(app.masteredCount, 1);
      expect(app.progress.history.where((a) => a.scheduledReview).length, 3);
    },
  );
  test('early practice never advances or postpones the schedule', () {
    completeFirst();
    final due = app.skill(first).dueAt;
    for (var i = 0; i < 4; i++) {
      reviewNow();
    }
    expect(app.skill(first).dueAt, due);
    expect(app.skill(first).reviewStage, 0);
    expect(app.masteredCount, 0);
    expect(app.progress.history.every((a) => !a.scheduledReview), isTrue);
  });

  for (var stage = 0; stage <= 3; stage++) {
    test('error at review stage $stage schedules the preceding interval', () {
      final old = SkillProgress(
        state: stage == 3 ? SkillState.confirmed : SkillState.independent,
        reviewStage: stage,
        dueAt: time,
      );
      final next = old.record(
        correct: false,
        assisted: false,
        scheduledReview: true,
        now: time,
      );
      final target = (stage - 1).clamp(0, 2);
      expect(next.reviewStage, target);
      expect(next.state, SkillState.studying);
      expect(next.dueAt, time.add(Duration(days: [1, 3, 7][target])));
    });
  }
  test('v2 round trip preserves every skill state and UTC deadlines', () async {
    final skills = {
      for (final state in SkillState.values)
        state.name: SkillProgress(
          state: state,
          reviewStage: state == SkillState.confirmed ? 3 : 0,
          dueAt: state == SkillState.notStudied || state == SkillState.studying
              ? null
              : time,
        ),
    };
    await ProgressRepository(store).save(ProgressSnapshot(skills: skills));
    final restored = await ProgressRepository(store).load();
    expect(
      restored.toJson()['skills'],
      ProgressSnapshot(skills: skills).toJson()['skills'],
    );
  });
  test(
    'malformed learning records never overwrite the original save',
    () async {
      completeFirst();
      await app.persist();
      final valid = store.value!;
      final damagedSkills = [
        {
          'state': 'confirmed',
          'reviewStage': 0,
          'dueAt': time.toIso8601String(),
        },
        {
          'state': 'independent',
          'reviewStage': -1,
          'dueAt': time.toIso8601String(),
        },
        {'state': 'assisted', 'reviewStage': 0, 'dueAt': 'invalid-date'},
        {'state': 'invented', 'reviewStage': 0, 'dueAt': null},
      ];
      for (final skill in damagedSkills) {
        final broken = jsonDecode(valid) as Map<String, dynamic>;
        broken['skills'] = {first.id: skill};
        store.value = jsonEncode(broken);
        final raw = store.value;
        await app.load();
        expect(app.hasLoadError, isTrue);
        await app.persist();
        expect(store.value, raw);
      }
    },
  );
  test('closed/stale review objects cannot submit a second time', () {
    completeFirst();
    app.startReview();
    final stale = app.reviewLevel!;
    app.closeReview();
    expect(app.submit(stale, review: true).isCorrect, isFalse);
    expect(app.totalAttempts, 1);
    app.startReview();
    solveReview(app);
    app.submit(app.reviewLevel!, review: true);
    app.restart(app.reviewLevel!, review: true);
    expect(app.reviewLevel!.variant, 2);
    expect(app.submit(stale, review: true).isCorrect, isFalse);
    expect(app.totalAttempts, 2);
  });
  test(
    'a review opened early remains practice even if its due time passes',
    () {
      completeFirst();
      app.startReview();
      time = time.add(const Duration(days: 2));
      solveReview(app);
      app.submit(app.reviewLevel!, review: true);
      expect(app.skill(first).reviewStage, 0);
    },
  );
  test(
    'assisted learning needs an independent baseline before spaced promotion',
    () {
      completeFirst(hint: true);
      expect(app.skill(first).state, SkillState.assisted);
      time = app.skill(first).dueAt!;
      reviewNow();
      expect(app.skill(first).state, SkillState.independent);
      expect(app.skill(first).reviewStage, 0);
      // A fresh baseline starts a full day, rather than retaining an overdue date.
      expect(app.skill(first).dueAt, time.add(const Duration(days: 1)));
    },
  );
  test(
    'an error rolls back a stage and revokes confirmation without erasing solves',
    () {
      completeFirst();
      for (var i = 0; i < 3; i++) {
        time = app.skill(first).dueAt!;
        reviewNow();
      }
      expect(app.masteredCount, 1);
      time = app.skill(first).dueAt!;
      app.startReview();
      expect(app.submit(app.reviewLevel!, review: true).isCorrect, isFalse);
      expect(app.skill(first).reviewStage, 2);
      expect(app.skill(first).state, SkillState.studying);
      expect(app.masteredCount, 0);
      expect(app.completedCount, 1);
      expect(app.isUnlocked(1), isTrue);
      solveReview(app);
      app.submit(app.reviewLevel!, review: true);
      expect(app.skill(first).reviewStage, 2);
      expect(app.errorsByTopic['angles'], 1);
    },
  );
  test(
    'hint during a due review returns to assistance and the 1-day interval',
    () {
      completeFirst();
      time = app.skill(first).dueAt!;
      reviewNow();
      time = app.skill(first).dueAt!;
      app.startReview();
      app.showHint(app.reviewLevel!, review: true);
      solveReview(app);
      app.submit(app.reviewLevel!, review: true);
      expect(app.skill(first).state, SkillState.assisted);
      expect(app.skill(first).reviewStage, 0);
      expect(app.skill(first).dueAt, time.add(const Duration(days: 1)));
    },
  );
  test(
    'statistics count real checks and distinct levels, never repeated taps',
    () {
      app.submit(first);
      completeFirst(hint: true);
      app.submit(first);
      app.restart(first);
      enterSolution(app, first);
      app.submit(first);
      expect(app.completedCount, 1);
      expect(app.independentCount, 1);
      expect(app.totalAttempts, 3);
      expect(app.totalCorrect, 2);
      expect(app.errorsByTopic, {
        'angles': 1,
        'pythagoras': 0,
        'trigonometry': 0,
      });
      expect(app.progress.history.length, 3);
    },
  );
  test(
    'v1 migration preserves counters/retired IDs; never invents old events or mastery',
    () async {
      final legacy = ProgressSnapshot(
        levels: {
          first.id: const LevelProgress(
            attempts: 3,
            completions: 2,
            independentCompletions: 2,
            independentReviews: 1,
          ),
          'retired': const LevelProgress(attempts: 1),
        },
      ).toJson();
      legacy['version'] = 1;
      store.value = jsonEncode(legacy);
      await app.load();
      expect(app.totalAttempts, 4);
      expect(app.progress.forLevel('retired').attempts, 1);
      expect(app.skill(first).state, SkillState.independent);
      expect(app.masteredCount, 0);
      expect(app.progress.history, isEmpty);
      expect(app.isUnlocked(1), isTrue);
      expect(jsonDecode(store.value!)['version'], 2);
      final due = app.skill(first).dueAt;
      time = time.add(const Duration(hours: 1));
      await app.load();
      expect(app.skill(first).dueAt, due);
    },
  );
  test(
    'unfinished review keeps the same variant and hints across restart',
    () async {
      completeFirst();
      app.startReview();
      final v = app.reviewLevel!.variant;
      app.showHint(app.reviewLevel!, review: true);
      await app.persist();
      final restored = AppController(
        ProgressRepository(store),
        clock: () => time,
      );
      await restored.load();
      restored.startReview();
      expect(restored.reviewLevel!.variant, v);
      expect(restored.puzzle(restored.reviewLevel!, review: true).hintCount, 1);
      solveReview(restored);
      restored.submit(restored.reviewLevel!, review: true);
      restored.startReview();
      expect(restored.reviewLevel!.variant, v + 1);
      expect(restored.puzzle(restored.reviewLevel!, review: true).hintCount, 0);
      await restored.persist();
      restored.dispose();
    },
  );
  test(
    'full scenario with real disk JSON: new user → hint → solve → restart → due review',
    () async {
      final dir = await Directory.systemTemp.createTemp('geoswipe-learning-');
      addTearDown(() => dir.delete(recursive: true));
      var session = AppController(
        ProgressRepository(DiskStore(File('${dir.path}/save.json'))),
        clock: () => time,
      );
      await session.load();
      session.showHint(first);
      enterSolution(session, first);
      session.submit(first);
      await session.persist();
      session.dispose();
      session = AppController(
        ProgressRepository(DiskStore(File('${dir.path}/save.json'))),
        clock: () => time,
      );
      await session.load();
      expect(session.completedCount, 1);
      expect(session.independentCount, 0);
      expect(session.progress.history.single.hintCount, 1);
      expect(session.skill(first).state, SkillState.assisted);
      expect(session.isUnlocked(1), isTrue);
      time = time.add(const Duration(days: 1));
      expect(session.dueLevels, [first]);
      session.startReview();
      expect(session.reviewLevel!.targetAngle, isNot(first.targetAngle));
      solveReview(session);
      expect(
        session.submit(session.reviewLevel!, review: true).isCorrect,
        isTrue,
      );
      expect(session.skill(first).state, SkillState.independent);
      expect(session.masteredCount, 0);
      await session.persist();
      session.dispose();
      final saved = await ProgressRepository(
        DiskStore(File('${dir.path}/save.json')),
      ).load();
      expect(saved.history.length, 2);
      expect(saved.unlocked, contains(levels[1].id));
      expect(saved.forSkill(first.id).dueAt, time.add(const Duration(days: 1)));
    },
  );

  for (final base in levels) {
    test(
      '${base.id}: three hints, changed variants, mathematical checks and explanations',
      () async {
        expect(base.hints.length, 3);
        expect(base.hints[0], contains('?'));
        expect(base.hints[2], contains('Другой пример:'));
        completeBefore(app, base.id);
        enterSolution(app, base);
        app.submit(base);
        for (var i = 0; i < 4; i++) {
          app.startReview(levelId: base.id);
          final variant = app.reviewLevel!;
          expect(variant.variant, i + 1);
          expect(variant.hints.length, 3);
          if (variant.kind == PuzzleKind.numericAnswer) {
            expect(variant.instruction, isNot(base.instruction));
            expect(
              variant.validation
                  .check(
                    variant.initialGeometry,
                    answer: (reviewAnswer(variant) + 1).toString(),
                  )
                  .isCorrect,
              isFalse,
            );
          } else {
            expect(
              variant.initialGeometry.points['B']!.x,
              isNot(base.initialGeometry.points['B']!.x),
            );
          }
          expect(app.submit(variant, review: true).isCorrect, isFalse);
          solveReview(app);
          expect(app.submit(variant, review: true).isCorrect, isTrue);
          final explanation = learningExplanation(
            variant,
            app.puzzle(variant, review: true),
          );
          expect(explanation, contains('='));
          expect(explanation, contains(RegExp(r'\d')));
        }
        expect(reviewVariant(base, 10).variant, 11);
      },
    );
  }

  test('rotated reference ray keeps slider angles relative to OA', () {
    completeFirst();
    app.startReview();
    final level = app.reviewLevel!;
    expect(level.initialGeometry.points['A']!.y, isNot(0));
    expect(app.puzzle(level, review: true).angle, closeTo(15, 1e-8));
    app.rotate(level, level.targetAngle, review: true);
    expect(
      app.puzzle(level, review: true).angle,
      closeTo(level.targetAngle, 1e-8),
    );
    expect(app.submit(level, review: true).isCorrect, isTrue);
  });
  for (final id in [
    'triangle-isosceles',
    'triangle-right',
    'pythagoras-construct',
    'trig-side-ratio',
    'trig-scale',
    'trig-standard-angle',
    'angle-135',
  ]) {
    test('$id: reflected review construction remains a valid solution', () {
      final base = levels.firstWhere((l) => l.id == id);
      completeBefore(app, id);
      enterSolution(app, base);
      app.submit(base);
      app.startReview(levelId: id);
      solveReview(app);
      final level = app.reviewLevel!;
      final state = app.puzzle(level, review: true);
      if (level.kind == PuzzleKind.rotateRay) {
        app.rotate(level, 360 - state.angle, review: true);
      } else {
        final c = state.scene.points['C']!;
        app.moveVertex(level, 'C', GeoPoint(c.x, -c.y), review: true);
      }
      expect(app.submit(level, review: true).isCorrect, isTrue);
    });
  }
}
