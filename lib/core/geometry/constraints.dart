import 'angle_math.dart';
import 'geometry.dart';
import 'scene.dart';

class GeometryCheck {
  const GeometryCheck(this.isCorrect, this.message, {this.error = 0});
  final bool isCorrect;
  final String message;
  final double error;
}

/// Extend this interface to add a condition without changing UI or storage.
abstract interface class GeometryConstraint {
  GeometryCheck check(GeometryScene scene, {String answer = ''});
}

class AngleConstraint implements GeometryConstraint {
  const AngleConstraint(
    this.first,
    this.vertex,
    this.second, {
    required this.target,
    this.tolerance = 2,
    this.directed = true,
  });
  final String first;
  final String vertex;
  final String second;
  final double target;
  final double tolerance;
  final bool directed;

  @override
  GeometryCheck check(GeometryScene scene, {String answer = ''}) {
    final a = scene.points[first];
    final o = scene.points[vertex];
    final b = scene.points[second];
    final angle = a == null || o == null || b == null
        ? null
        : directed
        ? Geometry.directedAngle(a - o, b - o)
        : Geometry.angleBetween(a - o, b - o);
    if (angle == null ||
        !target.isFinite ||
        !tolerance.isFinite ||
        tolerance <= 0 ||
        tolerance >= 180 ||
        (!directed && (target < 0 || target > 180))) {
      return const GeometryCheck(false, 'Угол не определён. Раздвинь точки.');
    }
    final error = directed
        ? angularDistance(angle, target)
        : (angle - target).abs();
    final correct = error <= tolerance + 1e-9;
    return GeometryCheck(
      correct,
      correct
          ? 'Угол установлен верно.'
          : 'Отклонение ${error.toStringAsFixed(1)}°. Подстрой луч и проверь ещё раз.',
      error: error,
    );
  }
}

class RightTriangleConstraint implements GeometryConstraint {
  const RightTriangleConstraint(this.triangle, {this.toleranceDegrees = 2});
  final TriangleRef triangle;
  final double toleranceDegrees;
  @override
  GeometryCheck check(GeometryScene scene, {String answer = ''}) {
    if (![triangle.a, triangle.b, triangle.c].every(scene.points.containsKey)) {
      return const GeometryCheck(false, 'Не хватает вершин треугольника.');
    }
    final angles = Geometry.triangleAngles(triangle.resolve(scene));
    if (angles == null) {
      return const GeometryCheck(
        false,
        'Треугольник вырожден: раздвинь вершины и убери их с одной прямой.',
      );
    }
    final error = angles
        .map((a) => (a - 90).abs())
        .reduce((a, b) => a < b ? a : b);
    final valid =
        toleranceDegrees.isFinite &&
        toleranceDegrees >= 0 &&
        toleranceDegrees < 90;
    final correct = valid && error <= toleranceDegrees + 1e-9;
    return GeometryCheck(
      correct,
      correct
          ? 'Прямоугольный треугольник построен.'
          : 'Ближайший к прямому угол отличается на ${error.toStringAsFixed(1)}°. Продолжай двигать вершину.',
      error: error,
    );
  }
}

class NumericAnswerConstraint implements GeometryConstraint {
  const NumericAnswerConstraint(this.expected, {this.absoluteTolerance = .01});
  final double expected;
  final double absoluteTolerance;
  @override
  GeometryCheck check(GeometryScene scene, {String answer = ''}) {
    final value = double.tryParse(answer.trim().replaceAll(',', '.'));
    if (value == null || !value.isFinite) {
      return const GeometryCheck(false, 'Введи конечное число, например 2,5.');
    }
    if (!expected.isFinite ||
        !absoluteTolerance.isFinite ||
        absoluteTolerance < 0) {
      return const GeometryCheck(false, 'Некорректно задано условие задачи.');
    }
    final error = (value - expected).abs();
    final correct = error <= absoluteTolerance + 1e-9;
    return GeometryCheck(
      correct,
      correct
          ? 'Ответ верный.'
          : 'Пока неверно. Проверь вычисления и попробуй снова.',
      error: error,
    );
  }
}

class AllConstraints implements GeometryConstraint {
  AllConstraints(List<GeometryConstraint> conditions)
    : conditions = List.unmodifiable(conditions) {
    if (conditions.isEmpty) {
      throw ArgumentError('At least one condition is required');
    }
  }
  final List<GeometryConstraint> conditions;
  @override
  GeometryCheck check(GeometryScene scene, {String answer = ''}) {
    for (final condition in conditions) {
      final result = condition.check(scene, answer: answer);
      if (!result.isCorrect) return result;
    }
    return const GeometryCheck(true, 'Все условия выполнены.');
  }
}
