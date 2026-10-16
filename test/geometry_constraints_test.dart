import 'package:flutter_test/flutter_test.dart';
import 'package:geoswipe/core/geometry/constraints.dart';
import 'package:geoswipe/core/geometry/geometry.dart';
import 'package:geoswipe/core/geometry/scene.dart';
import 'package:geoswipe/data/level_catalog.dart';

void main() {
  test(
    'ray check accepts full turns and both inclusive tolerance boundaries',
    () {
      const constraint = AngleConstraint('A', 'O', 'B', target: 60);
      for (final angle in [58.0, 60.0, 62.0, 420.0, -300.0]) {
        expect(constraint.check(angleScene(angle)).isCorrect, isTrue);
      }
      for (final angle in [57.999, 62.001, 300.0]) {
        expect(constraint.check(angleScene(angle)).isCorrect, isFalse);
      }
      expect(
        const AngleConstraint(
          'A',
          'O',
          'B',
          target: 1,
        ).check(angleScene(359)).isCorrect,
        isTrue,
      );
    },
  );
  test('undefined angle and malformed constraint never pass', () {
    final collapsed = GeometryScene(
      points: const {
        'A': GeoPoint(1, 0),
        'O': GeoPoint(0, 0),
        'B': GeoPoint(0, 0),
      },
    );
    expect(
      const AngleConstraint(
        'A',
        'O',
        'B',
        target: 60,
      ).check(collapsed).isCorrect,
      isFalse,
    );
    expect(
      const AngleConstraint(
        'X',
        'O',
        'B',
        target: 60,
      ).check(angleScene(60)).isCorrect,
      isFalse,
    );
    for (final tolerance in [-1.0, 0.0, 180.0, double.nan]) {
      expect(
        AngleConstraint(
          'A',
          'O',
          'B',
          target: 60,
          tolerance: tolerance,
        ).check(angleScene(60)).isCorrect,
        isFalse,
      );
    }
  });
  test(
    'right triangle accepts the continuum of solutions at any vertex and reflection',
    () {
      final level = levels.firstWhere((l) => l.id == 'triangle-right');
      for (final c in [
        const GeoPoint(0, 2),
        const GeoPoint(6, 4),
        const GeoPoint(3, 3),
        const GeoPoint(3, -3),
        const GeoPoint(0, -1.5),
      ]) {
        expect(
          level.validation
              .check(level.initialGeometry.withPoint('C', c))
              .isCorrect,
          isTrue,
          reason: '${c.x},${c.y}',
        );
      }
      expect(level.validation.check(level.initialGeometry).isCorrect, isFalse);
      for (final c in [
        const GeoPoint(0, 0),
        const GeoPoint(6, 0),
        const GeoPoint(3, 0),
      ]) {
        final result = level.validation.check(
          level.initialGeometry.withPoint('C', c),
        );
        expect(result.isCorrect, isFalse);
        expect(result.message, contains('вырожден'));
      }
      final translated = GeometryScene(
        points: const {
          'A': GeoPoint(100, 200),
          'B': GeoPoint(100, 212),
          'C': GeoPoint(106, 206),
        },
      );
      expect(level.validation.check(translated).isCorrect, isTrue);
    },
  );
  test(
    'numeric checks accept decimal comma and rounding, reject invalid and non-finite input',
    () {
      const check = NumericAnswerConstraint(5);
      final scene = GeometryScene(points: const {});
      for (final value in ['5', ' 5,0 ', '4.99', '5.01', '5e0']) {
        expect(
          check.check(scene, answer: value).isCorrect,
          isTrue,
          reason: value,
        );
      }
      for (final value in [
        '',
        'abc',
        'NaN',
        'Infinity',
        '-Infinity',
        '1e999',
        '4.9899',
        '5,0101',
        '3,4,5',
      ]) {
        expect(
          check.check(scene, answer: value).isCorrect,
          isFalse,
          reason: value,
        );
      }
      expect(
        const NumericAnswerConstraint(
          double.nan,
        ).check(scene, answer: '5').isCorrect,
        isFalse,
      );
      expect(
        const NumericAnswerConstraint(
          5,
          absoluteTolerance: -1,
        ).check(scene, answer: '5').isCorrect,
        isFalse,
      );
      final all = AllConstraints([
        check,
        const NumericAnswerConstraint(5, absoluteTolerance: .1),
      ]);
      expect(all.check(scene, answer: '5').isCorrect, isTrue);
      expect(all.check(scene, answer: '4').isCorrect, isFalse);
      expect(() => AllConstraints([]), throwsArgumentError);
    },
  );
  test(
    'scene validates references and keeps caller-owned collections immutable',
    () {
      final points = {'A': const GeoPoint(0, 0), 'B': const GeoPoint(1, 1)};
      final segments = [const GeoSegment('A', 'B')];
      final scene = GeometryScene(
        points: points,
        segments: segments,
        draggable: {'B'},
      );
      points['B'] = const GeoPoint(5, 5);
      segments.clear();
      expect(scene.points['B']!.x, 1);
      expect(scene.segments, hasLength(1));
      expect(() => scene.points.clear(), throwsUnsupportedError);
      expect(
        () => scene.withPoint('X', const GeoPoint(1, 1)),
        throwsArgumentError,
      );
      expect(
        () => GeometryScene(
          points: const {},
          segments: const [GeoSegment('X', 'Y')],
        ),
        throwsArgumentError,
      );
      expect(
        () => GeometryScene(points: const {'A': GeoPoint(double.nan, 0)}),
        throwsArgumentError,
      );
      expect(
        () => GeometryScene(
          points: const {},
          bounds: const GeoBounds(1, 1, 0, 0),
        ),
        throwsArgumentError,
      );
      expect(
        () => GeometryScene(
          points: const {'A': GeoPoint(0, 0)},
          rays: const [GeoRay('A', 'A')],
        ),
        throwsArgumentError,
      );
      expect(
        () => GeometryScene(
          points: const {'A': GeoPoint(-1e308, 0), 'B': GeoPoint(1e308, 0)},
          rays: const [GeoRay('A', 'B')],
        ),
        throwsArgumentError,
      );
    },
  );
}
