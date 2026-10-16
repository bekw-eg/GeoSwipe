import 'dart:math' as math;
import 'constraints.dart';
import 'geometry.dart';
import 'scene.dart';

/// Conditions on measured geometry, independent of handles or screen positions.
class ValidTriangleConstraint implements GeometryConstraint {
  const ValidTriangleConstraint(this.triangle);
  final TriangleRef triangle;
  @override
  GeometryCheck check(GeometryScene scene, {String answer = ''}) {
    final valid =
        [triangle.a, triangle.b, triangle.c].every(scene.points.containsKey) &&
        Geometry.isValidTriangle(triangle.resolve(scene));
    return GeometryCheck(
      valid,
      valid
          ? 'Треугольник невырожден.'
          : 'Раздвинь вершины: они не должны лежать на одной прямой.',
    );
  }
}

class SegmentRatioConstraint implements GeometryConstraint {
  const SegmentRatioConstraint(
    this.numerator,
    this.denominator, {
    required this.target,
    this.tolerance = .01,
  });
  final GeoSegment numerator;
  final GeoSegment denominator;
  final double target;
  final double tolerance;
  @override
  GeometryCheck check(GeometryScene scene, {String answer = ''}) {
    double? length(GeoSegment s) {
      final a = scene.points[s.start];
      final b = scene.points[s.end];
      return a == null || b == null ? null : Geometry.distance(a, b);
    }

    final a = length(numerator);
    final b = length(denominator);
    if (a == null ||
        b == null ||
        a <= Geometry.lengthEpsilon ||
        b <= Geometry.lengthEpsilon ||
        !target.isFinite ||
        target <= 0 ||
        !tolerance.isFinite ||
        tolerance < 0 ||
        tolerance >= target) {
      return const GeometryCheck(
        false,
        'Отношение не определено. Раздвинь точки.',
      );
    }
    final error = (a / b - target).abs();
    final correct = error.isFinite && error <= tolerance + 1e-9;
    return GeometryCheck(
      correct,
      correct
          ? 'Отношение сторон верно.'
          : 'Сравни длины ${numerator.start}${numerator.end} и '
                '${denominator.start}${denominator.end}.',
      error: error,
    );
  }
}

class EqualSegmentsConstraint implements GeometryConstraint {
  const EqualSegmentsConstraint(
    this.first,
    this.second, {
    this.tolerance = .05,
  });
  final GeoSegment first;
  final GeoSegment second;
  final double tolerance;
  @override
  GeometryCheck check(GeometryScene scene, {String answer = ''}) {
    if (![
      first.start,
      first.end,
      second.start,
      second.end,
    ].every(scene.points.containsKey)) {
      return const GeometryCheck(false, 'Не хватает концов отрезков.');
    }
    final a = Geometry.distance(
      scene.points[first.start]!,
      scene.points[first.end]!,
    );
    final b = Geometry.distance(
      scene.points[second.start]!,
      scene.points[second.end]!,
    );
    final error = a == null || b == null ? double.infinity : (a - b).abs();
    final correct =
        a != null &&
        b != null &&
        a > Geometry.lengthEpsilon &&
        b > Geometry.lengthEpsilon &&
        tolerance.isFinite &&
        tolerance >= 0 &&
        error <= tolerance + 1e-9;
    return GeometryCheck(
      correct,
      correct
          ? 'Стороны равны.'
          : 'Сделай ${first.start}${first.end} и ${second.start}${second.end} равными.',
      error: error,
    );
  }
}

class ObtuseAngleConstraint implements GeometryConstraint {
  const ObtuseAngleConstraint(this.first, this.vertex, this.second);
  final String first;
  final String vertex;
  final String second;
  @override
  GeometryCheck check(GeometryScene scene, {String answer = ''}) {
    if (![first, vertex, second].every(scene.points.containsKey)) {
      return const GeometryCheck(false, 'Не хватает точек угла.');
    }
    final angle = Geometry.angleBetween(
      scene.points[first]! - scene.points[vertex]!,
      scene.points[second]! - scene.points[vertex]!,
    );
    final correct = angle != null && angle > 90 + 1e-9 && angle < 180 - 1e-9;
    return GeometryCheck(
      correct,
      correct
          ? 'Тупой угол построен.'
          : 'Меньший угол должен быть строго больше 90° и меньше 180°.',
    );
  }
}

class CosineAngleConstraint implements GeometryConstraint {
  const CosineAngleConstraint(
    this.first,
    this.vertex,
    this.second, {
    required this.target,
    this.tolerance = .01,
  });
  final String first;
  final String vertex;
  final String second;
  final double target;
  final double tolerance;
  @override
  GeometryCheck check(GeometryScene scene, {String answer = ''}) {
    if (![first, vertex, second].every(scene.points.containsKey)) {
      return const GeometryCheck(false, 'Не хватает точек угла.');
    }
    final angle = Geometry.angleBetween(
      scene.points[first]! - scene.points[vertex]!,
      scene.points[second]! - scene.points[vertex]!,
    );
    if (angle == null ||
        angle <= 0 ||
        angle >= 90 ||
        !target.isFinite ||
        target <= 0 ||
        target >= 1 ||
        !tolerance.isFinite ||
        tolerance < 0 ||
        tolerance >= math.min(target, 1 - target)) {
      return const GeometryCheck(false, 'Построй острый угол между лучами.');
    }
    final error = (math.cos(angle * math.pi / 180) - target).abs();
    final correct = error <= tolerance + 1e-9;
    return GeometryCheck(
      correct,
      correct
          ? 'Косинус угла соответствует условию.'
          : 'Измени меньший угол α и проверь снова.',
      error: error,
    );
  }
}
