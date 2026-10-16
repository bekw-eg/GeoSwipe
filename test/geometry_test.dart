import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:geoswipe/core/geometry/geometry.dart';

void main() {
  const origin = GeoPoint(0, 0);
  const right = GeoTriangle(origin, GeoPoint(4, 0), GeoPoint(0, 3));

  test(
    'distance is translation invariant and avoids overflow when squaring',
    () {
      expect(Geometry.distance(origin, const GeoPoint(3, 4)), 5);
      expect(
        Geometry.distance(const GeoPoint(-10, 20), const GeoPoint(-7, 24)),
        5,
      );
      expect(Geometry.distance(origin, origin), 0);
      expect(
        Geometry.distance(origin, const GeoPoint(3e200, 4e200)),
        closeTo(5e200, 1e185),
      );
      expect(Geometry.distance(origin, const GeoPoint(double.nan, 1)), isNull);
      expect(
        Geometry.distance(const GeoPoint(-1e308, 0), const GeoPoint(1e308, 0)),
        isNull,
      );
    },
  );
  test(
    'vector angles cover parallel, opposite, reflex and undefined cases',
    () {
      expect(
        Geometry.angleBetween(const GeoPoint(1, 0), const GeoPoint(0, 1)),
        90,
      );
      expect(
        Geometry.angleBetween(const GeoPoint(1, 0), const GeoPoint(-1, 0)),
        180,
      );
      expect(
        Geometry.angleBetween(const GeoPoint(1, 1), const GeoPoint(2, 2)),
        0,
      );
      expect(
        Geometry.directedAngle(const GeoPoint(1, 0), const GeoPoint(0, -1)),
        270,
      );
      expect(
        Geometry.angleBetween(const GeoPoint(1, 0), const GeoPoint(0, -1)),
        90,
      );
      expect(
        Geometry.angleBetween(
          const GeoPoint(1e200, 0),
          const GeoPoint(0, 1e200),
        ),
        90,
      );
      for (final vector in [
        origin,
        const GeoPoint(1e-12, 0),
        const GeoPoint(double.infinity, 0),
        const GeoPoint(0, double.nan),
      ]) {
        expect(Geometry.angleBetween(vector, const GeoPoint(1, 0)), isNull);
        expect(Geometry.directedAngle(vector, const GeoPoint(1, 0)), isNull);
        expect(Geometry.isRightAngle(vector, const GeoPoint(1, 0)), isFalse);
      }
    },
  );
  test(
    'triangle angles sum to 180 and area survives reflection and scaling',
    () {
      final angles = Geometry.triangleAngles(right)!;
      expect(angles[0], 90);
      expect(angles.reduce((a, b) => a + b), closeTo(180, 1e-9));
      expect(angles[1], closeTo(36.86989765, 1e-7));
      expect(Geometry.triangleArea(right), 6);
      const reflected = GeoTriangle(
        GeoPoint(10, 20),
        GeoPoint(2, 20),
        GeoPoint(10, 26),
      );
      expect(Geometry.triangleArea(reflected), 24);
      const equilateral = GeoTriangle(
        origin,
        GeoPoint(2, 0),
        GeoPoint(1, 1.7320508075688772),
      );
      for (final angle in Geometry.triangleAngles(equilateral)!) {
        expect(angle, closeTo(60, 1e-9));
      }
    },
  );
  test(
    'duplicate, collinear, near collinear and invalid triangles are explicit',
    () {
      for (final triangle in [
        const GeoTriangle(origin, origin, GeoPoint(1, 1)),
        const GeoTriangle(origin, GeoPoint(1, 1), GeoPoint(2, 2)),
        const GeoTriangle(origin, GeoPoint(1, 0), GeoPoint(2, 1e-12)),
        const GeoTriangle(origin, GeoPoint(1e-12, 0), GeoPoint(0, 1e-12)),
        const GeoTriangle(origin, GeoPoint(double.nan, 0), GeoPoint(0, 3)),
        const GeoTriangle(origin, GeoPoint(double.infinity, 0), GeoPoint(0, 3)),
      ]) {
        expect(Geometry.isValidTriangle(triangle), isFalse);
        expect(Geometry.triangleArea(triangle), isNull);
        expect(Geometry.triangleAngles(triangle), isNull);
        expect(Geometry.areSimilar(right, triangle), isFalse);
        expect(Geometry.rightTriangleTrig(triangle, 1), isNull);
      }
    },
  );
  test('right angle checks have inclusive configurable degree tolerances', () {
    expect(
      Geometry.isRightAngle(
        const GeoPoint(1, 0),
        Geometry.polar(92, 1),
        toleranceDegrees: 2,
      ),
      isTrue,
    );
    expect(
      Geometry.isRightAngle(
        const GeoPoint(1, 0),
        Geometry.polar(92.001, 1),
        toleranceDegrees: 2,
      ),
      isFalse,
    );
    for (final tolerance in [-1.0, 90.0, double.nan, double.infinity]) {
      expect(
        Geometry.isRightAngle(
          const GeoPoint(1, 0),
          const GeoPoint(0, 1),
          toleranceDegrees: tolerance,
        ),
        isFalse,
      );
    }
  });
  test(
    'Pythagoras computes either missing side and rejects invalid lengths',
    () {
      expect(Geometry.hypotenuse(3, 4), 5);
      expect(Geometry.missingLeg(5, 3), closeTo(4, 1e-12));
      expect(Geometry.isPythagorean(5, 3, 4), isTrue);
      expect(Geometry.isPythagorean(3, 4, 6), isFalse);
      expect(Geometry.isPythagorean(1, 1, 2), isFalse);
      expect(Geometry.isPythagorean(0, 3, 3), isFalse);
      expect(Geometry.isPythagorean(3e200, 4e200, 5e200), isTrue);
      expect(
        Geometry.isPythagorean(3, 4, 5, relativeTolerance: double.nan),
        isFalse,
      );
      for (final bad in [0.0, -1.0, double.nan, double.infinity]) {
        expect(Geometry.hypotenuse(bad, 4), isNull);
        expect(Geometry.hypotenuse(3, bad), isNull);
        expect(Geometry.missingLeg(5, bad), isNull);
      }
      expect(Geometry.missingLeg(3, 4), isNull);
      expect(Geometry.missingLeg(3, 3), isNull);
      expect(Geometry.missingLeg(double.infinity, 3), isNull);
    },
  );
  test(
    'SSS similarity ignores vertex order, reflection, position and size',
    () {
      const scaled = GeoTriangle(
        GeoPoint(10, 26),
        GeoPoint(2, 20),
        GeoPoint(10, 20),
      );
      expect(Geometry.areSimilar(right, scaled), isTrue);
      expect(
        Geometry.areSimilar(
          right,
          const GeoTriangle(origin, GeoPoint(4, 0), GeoPoint(0, 4)),
        ),
        isFalse,
      );
      expect(
        Geometry.areSimilar(right, scaled, relativeTolerance: -1),
        isFalse,
      );
    },
  );
  test(
    'sin cos tan refer to the requested acute vertex and reject undefined input',
    () {
      final atB = Geometry.rightTriangleTrig(right, 1)!;
      expect(atB.sin, closeTo(3 / 5, 1e-12));
      expect(atB.cos, closeTo(4 / 5, 1e-12));
      expect(atB.tan, closeTo(3 / 4, 1e-12));
      expect(atB.sin * atB.sin + atB.cos * atB.cos, closeTo(1, 1e-12));
      final atC = Geometry.rightTriangleTrig(right, 2)!;
      expect(atC.sin, closeTo(4 / 5, 1e-12));
      expect(atC.tan, closeTo(4 / 3, 1e-12));
      for (final vertex in [-1, 0, 3]) {
        expect(Geometry.rightTriangleTrig(right, vertex), isNull);
      }
      expect(
        Geometry.rightTriangleTrig(
          GeoTriangle(origin, const GeoPoint(2, 0), GeoPoint(1, math.sqrt(3))),
          1,
        ),
        isNull,
      );
    },
  );
}
