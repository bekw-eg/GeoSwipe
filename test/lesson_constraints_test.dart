import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:geoswipe/core/geometry/constraints.dart';
import 'package:geoswipe/core/geometry/geometry.dart';
import 'package:geoswipe/core/geometry/lesson_constraints.dart';
import 'package:geoswipe/core/geometry/scene.dart';
import 'package:geoswipe/data/level_catalog.dart';

void main() {
  final scene = GeometryScene(
    points: const {
      'A': GeoPoint(0, 0),
      'B': GeoPoint(6, 0),
      'C': GeoPoint(0, 3),
    },
  );
  final empty = GeometryScene(points: const {});
  const ratio = SegmentRatioConstraint(
    GeoSegment('A', 'C'),
    GeoSegment('A', 'B'),
    target: .5,
  );
  const equal = EqualSegmentsConstraint(
    GeoSegment('A', 'C'),
    GeoSegment('B', 'C'),
  );
  const valid = ValidTriangleConstraint(TriangleRef('A', 'B', 'C'));
  const obtuse = ObtuseAngleConstraint('B', 'A', 'C');
  const cosine = CosineAngleConstraint('B', 'A', 'C', target: .5);
  for (final condition in <GeometryConstraint>[
    ratio,
    equal,
    valid,
    obtuse,
    cosine,
  ]) {
    test(
      '${condition.runtimeType} rejects missing points and coincident vertices',
      () {
        expect(condition.check(empty).isCorrect, isFalse);
        expect(
          condition.check(scene.withPoint('C', const GeoPoint(0, 0))).isCorrect,
          isFalse,
        );
      },
    );
  }

  test(
    'ratio boundaries are inclusive, zero denominator and invalid options fail',
    () {
      for (final value in [.49, .5, .51]) {
        expect(
          ratio.check(scene.withPoint('C', GeoPoint(0, 6 * value))).isCorrect,
          isTrue,
        );
      }
      for (final value in [.4899, .5101]) {
        expect(
          ratio.check(scene.withPoint('C', GeoPoint(0, 6 * value))).isCorrect,
          isFalse,
        );
      }
      expect(
        ratio.check(scene.withPoint('B', const GeoPoint(0, 0))).isCorrect,
        isFalse,
      );
      for (final value in [-1.0, double.nan, double.infinity, .5]) {
        expect(
          SegmentRatioConstraint(
            const GeoSegment('A', 'C'),
            const GeoSegment('A', 'B'),
            target: .5,
            tolerance: value,
          ).check(scene).isCorrect,
          isFalse,
        );
      }
      for (final target in [0.0, -1.0, double.nan, double.infinity]) {
        expect(
          SegmentRatioConstraint(
            const GeoSegment('A', 'C'),
            const GeoSegment('A', 'B'),
            target: target,
          ).check(scene).isCorrect,
          isFalse,
        );
      }
    },
  );

  test('equal lengths use the published absolute tolerance', () {
    final lengths = GeometryScene(
      points: const {
        'A': GeoPoint(0, 0),
        'B': GeoPoint(1, 0),
        'C': GeoPoint(0, 1),
        'D': GeoPoint(1.05, 1),
      },
    );
    const constraint = EqualSegmentsConstraint(
      GeoSegment('A', 'B'),
      GeoSegment('C', 'D'),
    );
    expect(constraint.check(lengths).isCorrect, isTrue);
    expect(
      constraint
          .check(lengths.withPoint('D', const GeoPoint(1.0501, 1)))
          .isCorrect,
      isFalse,
    );
    for (final tolerance in [-.1, double.nan, double.infinity]) {
      expect(
        EqualSegmentsConstraint(
          const GeoSegment('A', 'B'),
          const GeoSegment('C', 'D'),
          tolerance: tolerance,
        ).check(lengths).isCorrect,
        isFalse,
      );
    }
  });

  test(
    'cosine validates ratio tolerance and acute domain in either orientation',
    () {
      final base = angleScene(20);
      const constraint = CosineAngleConstraint('A', 'O', 'B', target: .5);
      for (final value in [.49, .5, .51]) {
        final angle = math.acos(value) * 180 / math.pi;
        for (final degrees in [angle, 360 - angle]) {
          expect(
            constraint.check(base.rotateRay(base.rays.last, degrees)).isCorrect,
            isTrue,
          );
        }
      }
      for (final angle in [0.0, 90.0, 120.0, 180.0]) {
        expect(
          constraint.check(base.rotateRay(base.rays.last, angle)).isCorrect,
          isFalse,
        );
      }
      for (final target in [0.0, 1.0, double.nan, double.infinity]) {
        expect(
          CosineAngleConstraint(
            'A',
            'O',
            'B',
            target: target,
          ).check(base).isCorrect,
          isFalse,
        );
      }
      for (final tolerance in [-1.0, .5, double.nan, double.infinity]) {
        expect(
          CosineAngleConstraint(
            'A',
            'O',
            'B',
            target: .5,
            tolerance: tolerance,
          ).check(base).isCorrect,
          isFalse,
        );
      }
    },
  );

  test(
    'constructions require every condition rather than the right angle alone',
    () {
      final level = levels.firstWhere((l) => l.id == 'pythagoras-construct');
      final initial = level.initialGeometry;
      expect(
        level.validation
            .check(initial.withPoint('C', const GeoPoint(0, 3)))
            .isCorrect,
        isFalse,
      );
      expect(
        level.validation
            .check(initial.withPoint('C', const GeoPoint(3, 4)))
            .isCorrect,
        isFalse,
      );
      expect(
        level.validation
            .check(initial.withPoint('C', const GeoPoint(3, 3)))
            .isCorrect,
        isTrue,
      );
      for (final id in ['trig-side-ratio', 'trig-scale']) {
        final trig = levels.firstWhere((l) => l.id == id);
        expect(
          trig.validation
              .check(trig.initialGeometry.withPoint('C', const GeoPoint(0, 1)))
              .isCorrect,
          isFalse,
        );
      }
    },
  );
}
