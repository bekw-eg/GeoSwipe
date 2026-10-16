import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:geoswipe/core/geometry/constraints.dart';
import 'package:geoswipe/core/geometry/geometry.dart';
import 'package:geoswipe/core/geometry/scene.dart';
import 'package:geoswipe/data/level_catalog.dart';
import 'package:geoswipe/models/level.dart';
import 'support/course_solutions.dart';

void main() {
  test(
    '30 complete lessons, three progressive chapters, no missing prerequisites',
    () {
      expect(levels.length, 30);
      expect(levels.map((l) => l.id).toSet().length, 30);
      expect(topics.length, 3);
      expect(topics.expand((t) => t.levelIds), levels.map((l) => l.id));
      for (final topic in topics) {
        final chapter = levels.where((l) => l.topicId == topic.id).toList();
        expect(chapter.length, 10);
        expect(chapter.first.stage, LearningStage.explore);
        expect(chapter.last.stage, LearningStage.challenge);
        expect(chapter.any((l) => l.kind == PuzzleKind.dragVertices), isTrue);
        expect(chapter.any((l) => l.stage == LearningStage.rule), isTrue);
      }
      expect(levels.map((l) => l.kind).toSet(), PuzzleKind.values.toSet());
      for (var i = 0; i < levels.length; i++) {
        final level = levels[i];
        expect(level.prerequisiteIds, i == 0 ? isEmpty : [levels[i - 1].id]);
        for (final text in [
          level.title,
          level.instruction,
          level.explanation,
          level.goal,
          level.answerLabel,
          ...level.hints,
          ...level.knowledge,
        ]) {
          expect(text.trim(), isNotEmpty, reason: level.id);
        }
        expect(level.knowledge, isNotEmpty);
      }
    },
  );

  for (final level in levels) {
    group(level.id, () {
      test(
        'initial configuration is valid, visible, unsolved and actionable',
        () {
          final scene = level.initialGeometry;
          expect(scene.bounds.isValid, isTrue);
          for (final p in scene.points.values) {
            expect(p.isFinite, isTrue);
            expect(
              p.x,
              inInclusiveRange(scene.bounds.left, scene.bounds.right),
            );
            expect(
              p.y,
              inInclusiveRange(scene.bounds.bottom, scene.bounds.top),
            );
          }
          for (final t in scene.triangles) {
            expect(Geometry.isValidTriangle(t.resolve(scene)), isTrue);
          }
          for (final s in scene.segments) {
            expect(
              Geometry.distance(scene.points[s.start]!, scene.points[s.end]!),
              greaterThan(0),
            );
            // Every literal length agrees with the drawn geometric configuration.
            final literal = double.tryParse(
              (s.label ?? '').replaceAll(' м', ''),
            );
            if (literal != null) {
              expect(
                Geometry.distance(scene.points[s.start]!, scene.points[s.end]!),
                closeTo(literal, 1e-8),
              );
            }
          }
          for (final arc in scene.arcs) {
            final angle = Geometry.angleBetween(
              scene.points[arc.first]! - scene.points[arc.vertex]!,
              scene.points[arc.second]! - scene.points[arc.vertex]!,
            );
            expect(angle, isNotNull);
            final literal = double.tryParse(
              (arc.label ?? '').replaceAll('°', ''),
            );
            if (literal != null) expect(angle, closeTo(literal, 1e-8));
          }
          expect(level.validation.check(scene).isCorrect, isFalse);
          switch (level.kind) {
            case PuzzleKind.rotateRay:
              expect(scene.rays.where((r) => r.rotatable).length, 1);
            case PuzzleKind.dragVertices:
              expect(scene.draggable, contains('C'));
            case PuzzleKind.numericAnswer:
              expect(scene.draggable, isEmpty);
              expect(scene.rays.any((r) => r.rotatable), isFalse);
              expect(
                scene.segments.every((s) => !s.showLength || s.label != null),
                isTrue,
                reason: 'Do not display computed unknown lengths',
              );
              expect(
                scene.arcs.every((a) => !a.showDegrees),
                isTrue,
                reason: 'Do not display computed unknown angles',
              );
          }
        },
      );

      test('independently computed solution passes and a wrong answer fails', () {
        final scene = solvedScene(level);
        final answer = numericSolutions[level.id]?.toStringAsFixed(2) ?? '';
        expect(level.validation.check(scene, answer: answer).isCorrect, isTrue);
        if (level.kind == PuzzleKind.numericAnswer) {
          expect(
            level.validation
                .check(scene, answer: answer.replaceAll('.', ','))
                .isCorrect,
            isTrue,
          );
          final expected = numericSolutions[level.id]!;
          for (final bad in [
            '',
            'NaN',
            'Infinity',
            'abc',
            '-1',
            '${expected + 1}',
            '${expected * expected + 99}',
          ]) {
            expect(
              level.validation.check(scene, answer: bad).isCorrect,
              isFalse,
              reason: bad,
            );
          }
          final constraint = level.validation as NumericAnswerConstraint;
          expect(constraint.expected, closeTo(expected, 1e-8));
          for (final sign in [-1, 1]) {
            expect(
              constraint
                  .check(
                    scene,
                    answer: '${expected + sign * constraint.absoluteTolerance}',
                  )
                  .isCorrect,
              isTrue,
            );
            expect(
              constraint
                  .check(
                    scene,
                    answer:
                        '${expected + sign * (constraint.absoluteTolerance + .0001)}',
                  )
                  .isCorrect,
              isFalse,
            );
          }
          if (constraint.absoluteTolerance > 0) {
            expect(level.instruction, contains('0,01'));
            expect(level.instruction, contains('0,005'));
          }
        }
      });

      if (level.kind == PuzzleKind.dragVertices) {
        test(
          'reflection, other positions and rigid transforms pass; degeneracy fails',
          () {
            final scene = solvedScene(level);
            final c = scene.points['C']!;
            expect(
              level.validation
                  .check(scene.withPoint('C', GeoPoint(c.x, -c.y)))
                  .isCorrect,
              isTrue,
            );
            final transformed = GeometryScene(
              points: scene.points.map(
                (id, p) => MapEntry(id, GeoPoint(-p.y + 17, p.x - 8)),
              ),
              triangles: scene.triangles,
              segments: scene.segments,
              arcs: scene.arcs,
            );
            expect(level.validation.check(transformed).isCorrect, isTrue);
            for (final invalid in [
              scene.points['A']!,
              scene.points['B']!,
              const GeoPoint(3, 0),
            ]) {
              expect(
                level.validation.check(scene.withPoint('C', invalid)).isCorrect,
                isFalse,
              );
            }
          },
        );
      }
    });
  }

  test(
    'every mathematically distinct right vertex and isosceles height is accepted',
    () {
      final right = levels.firstWhere((l) => l.id == 'triangle-right');
      for (final c in [
        const GeoPoint(0, 3),
        const GeoPoint(6, 2),
        const GeoPoint(3, 3),
        const GeoPoint(3, -3),
        GeoPoint(1, math.sqrt(5)),
      ]) {
        expect(
          right.validation
              .check(right.initialGeometry.withPoint('C', c))
              .isCorrect,
          isTrue,
        );
      }
      final iso = levels.firstWhere((l) => l.id == 'triangle-isosceles');
      for (final height in [-4.5, -2.0, 1.0, 4.0]) {
        expect(
          iso.validation
              .check(iso.initialGeometry.withPoint('C', GeoPoint(3, height)))
              .isCorrect,
          isTrue,
        );
      }
    },
  );

  test(
    'obtuse and cosine constructions accept both ray orientations and reject boundaries',
    () {
      final obtuse = levels.firstWhere((l) => l.id == 'angle-135');
      for (final angle in [90.01, 100.0, 135.0, 179.99, 225.0, 260.0]) {
        final s = obtuse.initialGeometry;
        expect(
          obtuse.validation.check(s.rotateRay(s.rays.last, angle)).isCorrect,
          isTrue,
        );
      }
      for (final angle in [0.0, 90.0, 180.0, 270.0]) {
        final s = obtuse.initialGeometry;
        expect(
          obtuse.validation.check(s.rotateRay(s.rays.last, angle)).isCorrect,
          isFalse,
        );
      }
      final cosine = levels.firstWhere((l) => l.id == 'trig-standard-angle');
      for (final angle in [60.0, 300.0]) {
        final s = cosine.initialGeometry;
        expect(
          cosine.validation.check(s.rotateRay(s.rays.last, angle)).isCorrect,
          isTrue,
        );
      }
    },
  );

  test(
    'Pythagorean squares really are external squares with the stated areas',
    () {
      final scene = levels
          .firstWhere((l) => l.id == 'pythagoras-squares')
          .initialGeometry;
      for (final (start, end, area, first, second) in [
        ('B', 'A', 9, 'E', 'F'),
        ('A', 'C', 16, 'G', 'H'),
        ('C', 'B', 25, 'I', 'J'),
      ]) {
        final a = scene.points[start]!;
        final b = scene.points[end]!;
        final c = scene.points[second]!;
        final d = scene.points[first]!;
        expect(Geometry.isRightAngle(b - a, d - a), isTrue);
        expect(
          Geometry.distance(a, b),
          closeTo(Geometry.distance(a, d)!, 1e-9),
        );
        expect(
          Geometry.distance(b, c),
          closeTo(Geometry.distance(a, b)!, 1e-9),
        );
        expect(math.pow(Geometry.distance(a, b)!, 2), closeTo(area, 1e-9));
      }
    },
  );
}
