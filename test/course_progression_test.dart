import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoswipe/core/app_controller.dart';
import 'package:geoswipe/core/geometry/geometry.dart';
import 'package:geoswipe/data/level_catalog.dart';
import 'package:geoswipe/data/progress_repository.dart';
import 'package:geoswipe/models/progress.dart';
import 'support/course_solutions.dart';
import 'support/memory_store.dart';

void main() {
  test(
    'fresh course cannot be skipped using navigation, inputs, hints or submit',
    () async {
      final store = MemoryStore();
      final controller = AppController(ProgressRepository(store));
      await controller.load();
      expect(controller.unlockedIndices, [0]);
      for (final index in [-1, 1, 10, 20, 29, 30]) {
        expect(controller.isUnlocked(index), isFalse);
        controller.openLevel(index);
        controller.changePage(index);
        expect(controller.currentIndex, 0);
      }
      for (final level in levels.skip(1)) {
        enterSolution(controller, level);
        controller.showHint(level);
        expect(controller.submit(level).isCorrect, isFalse);
        expect(controller.submit(level, review: true).isCorrect, isFalse);
        expect(controller.puzzle(level).hintUsed, isFalse);
        expect(controller.puzzle(level).answer, isEmpty);
        expect(controller.puzzle(level).result, isNull);
      }
      expect(controller.totalAttempts, 0);
      expect(controller.unlockedIndices, [0]);
      controller.dispose();
    },
  );

  test(
    'all 30 unlock one at a time, survive restart, and remain revisitable',
    () async {
      final store = MemoryStore();
      var controller = AppController(ProgressRepository(store));
      await controller.load();
      for (var i = 0; i < levels.length; i++) {
        final level = levels[i];
        expect(controller.unlockedIndices, List.generate(i + 1, (n) => n));
        controller.openLevel(i);
        if (i.isEven) controller.showHint(level);
        expect(controller.submit(level).isCorrect, isFalse);
        expect(controller.isUnlocked(i + 1), isFalse);
        enterSolution(controller, level);
        expect(controller.submit(level).isCorrect, isTrue, reason: level.id);
        controller.submit(level); // A completed attempt must not count twice.
        expect(controller.totalAttempts, 2 * (i + 1));
        expect(controller.completedCount, i + 1);
        expect(controller.masteredCount, 0);
        expect(controller.progress.forLevel(level.id).isAssistedOnly, i.isEven);
        await controller.persist();
        controller.dispose();
        controller = AppController(ProgressRepository(store));
        await controller.load();
        expect(controller.currentIndex, i);
        expect(controller.completedCount, i + 1);
        expect(controller.isUnlocked(i), isTrue);
        if (i < 29) expect(controller.isUnlocked(i + 1), isTrue);
        expect(controller.puzzle(level).isComplete, isFalse);
        controller.openLevel(0);
        expect(controller.currentIndex, 0);
      }
      expect(controller.unlockedIndices.length, 30);
      expect(controller.assistedCount, 15);
      for (final level in levels) {
        controller.startReview(levelId: level.id);
        enterSolution(controller, level, review: true);
        expect(controller.submit(level, review: true).isCorrect, isTrue);
      }
      // Only tasks with a previous independent completion have demonstrated mastery.
      expect(controller.masteredCount, 15);
      await controller.persist();
      controller.dispose();
    },
  );

  test(
    'version-1 saves preserve retired tasks and compatible completions without granting new mastery',
    () async {
      const done = LevelProgress(
        attempts: 1,
        completions: 1,
        independentCompletions: 1,
      );
      final store = MemoryStore(
        jsonEncode(
          ProgressSnapshot(
            levels: {
              'angle-60': done,
              'angle-180': done,
              'angle-270': done,
              'angle-315': done,
              'triangle-right': done,
              'pythagoras-3-4': done,
            },
            lastLevelId: 'angle-315',
          ).toJson(),
        ),
      );
      final controller = AppController(ProgressRepository(store));
      await controller.load();
      expect(controller.currentIndex, 0);
      expect(controller.completedCount, 2);
      expect(controller.masteredCount, 0);
      expect(controller.isUnlocked(10), isTrue);
      expect(controller.isUnlocked(11), isTrue);
      expect(controller.isUnlocked(13), isTrue);
      expect(controller.isUnlocked(14), isTrue);
      expect(controller.isUnlocked(20), isFalse);
      controller.openLevel(13);
      expect(controller.currentIndex, 13);
      await controller.persist();
      final saved = await ProgressRepository(store).load();
      for (final id in ['angle-60', 'angle-180', 'angle-270', 'angle-315']) {
        expect(saved.forLevel(id).independentCompletions, 1);
      }
      controller.dispose();
    },
  );

  test(
    'last-level references cannot bypass a lock and never destroy save data',
    () async {
      final store = MemoryStore(
        jsonEncode(ProgressSnapshot(lastLevelId: levels.last.id).toJson()),
      );
      final controller = AppController(ProgressRepository(store));
      await controller.load();
      expect(controller.currentIndex, 0);
      expect(controller.hasLoadError, isFalse);
      expect(controller.unlockedIndices, [0]);
      controller.dispose();
    },
  );

  test(
    'hints reveal progressively, survive input changes and count as assistance',
    () async {
      final controller = AppController(ProgressRepository(MemoryStore()));
      await controller.load();
      final level = levels.first;
      controller.showHint(level);
      expect(controller.puzzle(level).hintCount, 1);
      controller.rotate(level, 25);
      controller.showHint(level);
      controller.showHint(level);
      expect(controller.puzzle(level).hintCount, level.hints.length);
      enterSolution(controller, level);
      expect(controller.submit(level).isCorrect, isTrue);
      expect(controller.assistedCount, 1);
      expect(controller.isUnlocked(1), isTrue);
      controller.restart(level);
      expect(controller.puzzle(level).hintCount, 0);
      expect(controller.puzzle(level).hintUsed, isFalse);
      controller.dispose();
    },
  );

  test('moving C to an invalid triangle never unlocks the next task', () async {
    final controller = AppController(ProgressRepository(MemoryStore()));
    await controller.load();
    completeBefore(controller, 'triangle-isosceles');
    final level = levels[6];
    controller.moveVertex(level, 'C', const GeoPoint(3, 0));
    expect(controller.submit(level).isCorrect, isFalse);
    expect(controller.isUnlocked(7), isFalse);
    controller.dispose();
  });
}
