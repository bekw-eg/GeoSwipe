import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoswipe/core/app_controller.dart';
import 'package:geoswipe/data/level_catalog.dart';
import 'package:geoswipe/data/progress_repository.dart';
import 'package:geoswipe/models/progress.dart';
import 'support/memory_store.dart';

void main() {
  late MemoryStore store;
  late AppController controller;
  setUp(() async {
    store = MemoryStore();
    controller = AppController(ProgressRepository(store));
    await controller.load();
  });
  tearDown(() async {
    await controller.persist();
    controller.dispose();
  });

  test('fresh install has honest empty statistics', () {
    expect(controller.completedCount, 0);
    expect(controller.totalAttempts, 0);
    expect(controller.masteredCount, 0);
    controller.startReview();
    expect(controller.reviewLevel, isNull);
  });
  test('wrong answers count as attempts and can be corrected', () {
    final level = levels.first;
    expect(controller.submit(level).isCorrect, isFalse);
    expect(controller.totalAttempts, 1);
    expect(controller.completedCount, 0);
    controller.rotate(level, 46.5);
    expect(controller.puzzle(level).result, isNull);
    expect(controller.submit(level).isCorrect, isTrue);
    expect(controller.totalAttempts, 2);
    expect(controller.totalCorrect, 1);
  });
  test('solved session is immutable and cannot count twice', () {
    final level = levels.first;
    controller.rotate(level, 45);
    controller.submit(level);
    controller.submit(level);
    controller.rotate(level, 90);
    controller.showHint(level);
    expect(controller.totalAttempts, 1);
    expect(controller.puzzle(level).angle, 45);
    expect(controller.puzzle(level).hintUsed, isFalse);
  });
  test('assisted completion does not count as mastery', () {
    final level = levels.first;
    controller.showHint(level);
    controller.rotate(level, 45);
    controller.submit(level);
    expect(controller.completedCount, 1);
    expect(controller.assistedCount, 1);
    expect(controller.masteredCount, 0);
    expect(controller.progress.forLevel(level.id).independentCompletions, 0);
  });
  test('mastery requires two independent solves including a fresh review', () {
    final level = levels.first;
    controller.rotate(level, 45);
    controller.submit(level);
    expect(controller.masteredCount, 0);
    controller.startReview();
    expect(controller.puzzle(level, review: true).isComplete, isFalse);
    controller.rotate(level, 45, review: true);
    controller.submit(level, review: true);
    expect(controller.masteredCount, 1);
    expect(controller.totalAttempts, 2);
  });
  test('assisted review and repeated play alone cannot confirm mastery', () {
    final level = levels.first;
    for (var i = 0; i < 2; i++) {
      controller.restart(level);
      controller.rotate(level, 45);
      controller.submit(level);
    }
    expect(controller.masteredCount, 0);
    controller.startReview();
    controller.showHint(level, review: true);
    controller.rotate(level, 45, review: true);
    controller.submit(level, review: true);
    expect(controller.masteredCount, 0);
  });
  test('review prioritizes completed levels not yet mastered', () {
    for (final level in levels.take(2)) {
      controller.rotate(level, level.targetAngle);
      controller.submit(level);
    }
    controller.startReview(levelId: levels.first.id);
    controller.rotate(levels.first, 45, review: true);
    controller.submit(levels.first, review: true);
    controller.closeReview();
    controller.startReview();
    expect(controller.reviewLevel, levels[1]);
  });
  test(
    'round trip restores progress and last visited level after restart',
    () async {
      controller.showHint(levels.first);
      controller.rotate(levels.first, 45);
      controller.submit(levels.first);
      controller.changePage(2);
      await controller.persist();
      final restored = AppController(ProgressRepository(store));
      await restored.load();
      expect(restored.completedCount, 1);
      expect(restored.assistedCount, 1);
      expect(restored.totalAttempts, 1);
      expect(restored.currentIndex, 2);
      restored.dispose();
    },
  );
  test(
    'writes remain ordered when actions happen in quick succession',
    () async {
      for (final level in levels) {
        controller.rotate(level, level.targetAngle);
        controller.submit(level);
      }
      await controller.persist();
      final result = await ProgressRepository(store).load();
      expect(result.levels.length, levels.length);
      expect(result.forLevel(levels.last.id).isCompleted, isTrue);
    },
  );
  test(
    'failed writes are visible and can be retried without losing progress',
    () async {
      store.failWrite = true;
      controller.rotate(levels.first, 45);
      controller.submit(levels.first);
      await controller.persist();
      expect(controller.hasSaveError, isTrue);
      expect(controller.completedCount, 1);
      store.failWrite = false;
      await controller.persist();
      expect(controller.hasSaveError, isFalse);
      expect(
        (await ProgressRepository(
          store,
        ).load()).forLevel(levels.first.id).isCompleted,
        isTrue,
      );
    },
  );
  test(
    'corrupt and future saves are kept intact and never overwritten',
    () async {
      for (final raw in ['{broken', '{"version":99,"levels":{}}', '[]']) {
        final protected = MemoryStore(raw);
        final app = AppController(ProgressRepository(protected));
        await app.load();
        expect(app.hasLoadError, isTrue);
        app.rotate(levels.first, 45);
        app.submit(levels.first);
        await app.persist();
        expect(protected.value, raw);
        expect(protected.writes, 0);
        app.dispose();
      }
    },
  );
  test('temporary read failure supports non-destructive retry', () async {
    store.failRead = true;
    await controller.load();
    expect(controller.hasLoadError, isTrue);
    store.failRead = false;
    await controller.load();
    expect(controller.hasLoadError, isFalse);
  });
  test(
    'successful read retry resets temporary puzzles and restores the saved page',
    () async {
      store.failRead = true;
      await controller.load();
      controller.changePage(3);
      controller.rotate(levels.first, 45);
      controller.submit(levels.first);
      final revision = controller.playRevision;
      store.failRead = false;
      store.value = jsonEncode(
        ProgressSnapshot(lastLevelId: levels[1].id).toJson(),
      );
      await controller.load();
      expect(controller.currentIndex, 1);
      expect(controller.playRevision, greaterThan(revision));
      expect(controller.completedCount, 0);
      expect(controller.puzzle(levels.first).isComplete, isFalse);
    },
  );
  test('save parsing rejects inconsistent and negative counters', () {
    final data = const LevelProgress().toJson();
    expect(
      () => LevelProgress.fromJson({...data, 'attempts': -1}),
      throwsFormatException,
    );
    expect(
      () => LevelProgress.fromJson({...data, 'completions': 2}),
      throwsFormatException,
    );
    expect(
      () => LevelProgress.fromJson({...data, 'independentReviews': 1}),
      throwsFormatException,
    );
    expect(
      () => LevelProgress.fromJson({...data, 'attempts': 1.5}),
      throwsFormatException,
    );
  });
  test(
    'unknown level data survives save round trips for future migrations',
    () async {
      store.value = jsonEncode(
        ProgressSnapshot(
          levels: {'retired-level': const LevelProgress(attempts: 2)},
        ).toJson(),
      );
      await controller.load();
      controller.changePage(1);
      await controller.persist();
      expect(
        (await ProgressRepository(
          store,
        ).load()).forLevel('retired-level').attempts,
        2,
      );
    },
  );
  test(
    'catalog has unique IDs and valid topic references and initial states',
    () {
      expect(levels.map((l) => l.id).toSet().length, levels.length);
      for (final topic in topics.where((t) => t.isAvailable)) {
        for (final id in topic.levelIds) {
          expect(
            levels.any((l) => l.id == id && l.topicId == topic.id),
            isTrue,
          );
        }
      }
      for (final level in levels) {
        expect(
          (level.targetAngle - level.initialAngle).abs(),
          greaterThan(level.tolerance),
        );
      }
    },
  );
}
