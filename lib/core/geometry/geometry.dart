import 'dart:math' as math;

/// Mathematical coordinates: x points right, y points up. No Flutter types.
class GeoPoint {
  const GeoPoint(this.x, this.y);
  final double x;
  final double y;
  bool get isFinite => x.isFinite && y.isFinite;
  GeoPoint operator -(GeoPoint other) => GeoPoint(x - other.x, y - other.y);
  GeoPoint operator +(GeoPoint other) => GeoPoint(x + other.x, y + other.y);
  GeoPoint operator *(double factor) => GeoPoint(x * factor, y * factor);
}

class GeoTriangle {
  const GeoTriangle(this.a, this.b, this.c);
  final GeoPoint a;
  final GeoPoint b;
  final GeoPoint c;
  List<GeoPoint> get vertices => [a, b, c];
}

class TrigRatios {
  const TrigRatios(this.sin, this.cos, this.tan);
  final double sin;
  final double cos;
  final double tan;
}

/// Undefined/non-finite configurations return null (predicates return false).
/// Lengths <= 1e-9 and normalized double areas <= 1e-10 are degenerate.
abstract final class Geometry {
  static const lengthEpsilon = 1e-9;
  static const shapeEpsilon = 1e-10;

  static double? _finite(double value) => value.isFinite ? value : null;

  // Scaling avoids overflow from squaring large, otherwise finite lengths.
  static double? magnitude(GeoPoint vector) {
    if (!vector.isFinite) return null;
    final scale = math.max(vector.x.abs(), vector.y.abs());
    if (scale == 0) return 0;
    final x = vector.x / scale;
    final y = vector.y / scale;
    return _finite(scale * math.sqrt(x * x + y * y));
  }

  static double? distance(GeoPoint a, GeoPoint b) => magnitude(b - a);

  static GeoPoint? _unit(GeoPoint vector) {
    final length = magnitude(vector);
    if (length == null || length <= lengthEpsilon) return null;
    return GeoPoint(vector.x / length, vector.y / length);
  }

  /// Smaller angle in [0, 180], stable near parallel/antiparallel vectors.
  static double? angleBetween(GeoPoint first, GeoPoint second) {
    final u = _unit(first);
    final v = _unit(second);
    if (u == null || v == null) return null;
    return math.atan2((u.x * v.y - u.y * v.x).abs(), u.x * v.x + u.y * v.y) *
        180 /
        math.pi;
  }

  /// Counterclockwise angle in [0, 360), including reflex angles.
  static double? directedAngle(GeoPoint first, GeoPoint second) {
    final u = _unit(first);
    final v = _unit(second);
    if (u == null || v == null) return null;
    return (math.atan2(u.x * v.y - u.y * v.x, u.x * v.x + u.y * v.y) *
            180 /
            math.pi) %
        360;
  }

  static GeoPoint polar(double degrees, double length) => GeoPoint(
    math.cos((degrees % 360) * math.pi / 180) * length,
    math.sin((degrees % 360) * math.pi / 180) * length,
  );

  static bool isValidTriangle(GeoTriangle triangle) {
    final u = triangle.b - triangle.a;
    final v = triangle.c - triangle.a;
    final sides = [
      magnitude(u),
      magnitude(v),
      distance(triangle.b, triangle.c),
    ];
    if (sides.any((s) => s == null || s <= lengthEpsilon)) return false;
    final scale = sides.cast<double>().reduce(math.max);
    final cross = (u.x / scale) * (v.y / scale) - (u.y / scale) * (v.x / scale);
    return cross.abs() > shapeEpsilon;
  }

  static List<double>? triangleAngles(GeoTriangle triangle) {
    if (!isValidTriangle(triangle)) return null;
    final p = triangle.vertices;
    return List.generate(
      3,
      (i) => angleBetween(p[(i + 1) % 3] - p[i], p[(i + 2) % 3] - p[i])!,
    );
  }

  static bool isRightAngle(
    GeoPoint first,
    GeoPoint second, {
    double toleranceDegrees = 1e-6,
  }) {
    if (!toleranceDegrees.isFinite ||
        toleranceDegrees < 0 ||
        toleranceDegrees >= 90) {
      return false;
    }
    final angle = angleBetween(first, second);
    return angle != null && (angle - 90).abs() <= toleranceDegrees + 1e-9;
  }

  static double? triangleArea(GeoTriangle triangle) {
    if (!isValidTriangle(triangle)) return null;
    final u = triangle.b - triangle.a;
    final v = triangle.c - triangle.a;
    final scale = math.max(magnitude(u)!, magnitude(v)!);
    final normalized =
        ((u.x / scale) * (v.y / scale) - (u.y / scale) * (v.x / scale)).abs();
    return _finite((normalized * scale / 2) * scale);
  }

  static double? hypotenuse(double a, double b) {
    if (!a.isFinite ||
        !b.isFinite ||
        a <= lengthEpsilon ||
        b <= lengthEpsilon) {
      return null;
    }
    return magnitude(GeoPoint(a, b));
  }

  static double? missingLeg(double hypotenuse, double leg) {
    if (!hypotenuse.isFinite ||
        !leg.isFinite ||
        leg <= lengthEpsilon ||
        hypotenuse <= leg) {
      return null;
    }
    final ratio = leg / hypotenuse;
    return _finite(hypotenuse * math.sqrt((1 - ratio) * (1 + ratio)));
  }

  static bool isPythagorean(
    double a,
    double b,
    double c, {
    double relativeTolerance = 1e-6,
  }) {
    if (!_validTolerance(relativeTolerance)) return false;
    final sides = [a, b, c]..sort();
    if (sides.any((s) => !s.isFinite || s <= lengthEpsilon)) return false;
    final x = sides[0] / sides[2];
    final y = sides[1] / sides[2];
    if (x + y <= 1 + shapeEpsilon) return false;
    return (x * x + y * y - 1).abs() <= relativeTolerance + 1e-12;
  }

  /// SSS similarity, independent of vertex ordering, translation or reflection.
  static bool areSimilar(
    GeoTriangle first,
    GeoTriangle second, {
    double relativeTolerance = 1e-6,
  }) {
    if (!_validTolerance(relativeTolerance) ||
        !isValidTriangle(first) ||
        !isValidTriangle(second)) {
      return false;
    }
    List<double> normalized(GeoTriangle t) {
      final sides = [
        distance(t.a, t.b)!,
        distance(t.b, t.c)!,
        distance(t.c, t.a)!,
      ]..sort();
      return sides.map((s) => s / sides.last).toList();
    }

    final a = normalized(first);
    final b = normalized(second);
    return List.generate(
      3,
      (i) =>
          (a[i] - b[i]).abs() <=
          relativeTolerance * math.max(a[i], b[i]) + 1e-12,
    ).every((v) => v);
  }

  static bool _validTolerance(double value) =>
      value.isFinite && value >= 0 && value < 1;

  /// Ratios at an acute vertex (0=A, 1=B, 2=C) of a right triangle.
  /// The right-angle vertex, non-right and degenerate triangles return null.
  static TrigRatios? rightTriangleTrig(GeoTriangle triangle, int vertex) {
    if (vertex < 0 || vertex > 2) return null;
    final angles = triangleAngles(triangle);
    if (angles == null) return null;
    final right = angles.indexWhere((a) => (a - 90).abs() <= 1e-6);
    if (right < 0 || right == vertex) return null;
    final p = triangle.vertices;
    final other = 3 - right - vertex;
    final opposite = distance(p[right], p[other])!;
    final adjacent = distance(p[right], p[vertex])!;
    final hyp = distance(p[vertex], p[other])!;
    final tangent = opposite / adjacent;
    if (!tangent.isFinite) return null;
    return TrigRatios(opposite / hyp, adjacent / hyp, tangent);
  }
}
