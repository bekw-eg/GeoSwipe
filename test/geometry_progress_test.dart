import 'package:flutter_test/flutter_test.dart';
import 'package:geoswipe/core/app_controller.dart';
import 'package:geoswipe/core/geometry/geometry.dart';
import 'package:geoswipe/data/level_catalog.dart';
import 'package:geoswipe/data/progress_repository.dart';
import 'support/memory_store.dart';

void main() {
  test(
    'new mechanics preserve assisted, independent and mastery states across storage and review',
    () async {
      final store = MemoryStore();
      final controller = AppController(ProgressRepository(store));
      await controller.load();
      final drag = levels.firstWhere((l) => l.id == 'triangle-right');
      final answer = levels.firstWhere((l) => l.id == 'pythagoras-3-4');
      controller.showHint(drag);
      controller.moveVertex(drag, 'C', const GeoPoint(0, 2));
      expect(controller.submit(drag).isCorrect, isTrue);
      controller.moveVertex(drag, 'C', const GeoPoint(2, 4));
      expect(controller.puzzle(drag).scene.points['C']!.x, 0);
      controller.answer(answer, '5');
      expect(controller.submit(answer).isCorrect, isTrue);
      controller.answer(answer, '4');
      controller.submit(answer);
      expect(controller.puzzle(answer).answer, '5');
      expect(controller.totalAttempts, 2);
      expect(controller.assistedCount, 1);
      expect(controller.masteredCount, 0);
      controller.startReview(levelId: answer.id);
      expect(controller.puzzle(answer, review: true).answer, isEmpty);
      controller.answer(answer, '5.00', review: true);
      expect(controller.submit(answer, review: true).isCorrect, isTrue);
      expect(controller.masteredCount, 1);
      controller.startReview(levelId: drag.id);
      expect(controller.puzzle(drag, review: true).scene.points['C']!.x, 2);
      controller.moveVertex(drag, 'C', const GeoPoint(3, -3), review: true);
      expect(controller.submit(drag, review: true).isCorrect, isTrue);
      expect(controller.progress.forLevel(drag.id).isMastered, isFalse);
      controller.openLevel(levels.indexOf(answer));
      await controller.persist();
      final restored = AppController(ProgressRepository(store));
      await restored.load();
      expect(restored.completedCount, 2);
      expect(restored.masteredCount, 1);
      expect(restored.totalAttempts, 4);
      expect(restored.currentIndex, levels.indexOf(answer));
      expect(restored.puzzle(answer).answer, isEmpty);
      expect(restored.puzzle(drag).scene.points['C']!.x, 2);
      restored.dispose();
      controller.dispose();
    },
  );
}
