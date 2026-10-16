import 'package:flutter_test/flutter_test.dart';
import 'package:geoswipe/core/geometry/angle_math.dart';

void main() {
  test('normalizes full turns and negative angles', () {
    expect(normalizeDegrees(720), 0);
    expect(normalizeDegrees(-45), 315);
    expect(normalizeDegrees(405), 45);
  });
  test('rejects non-finite normalization', () {
    for (final value in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(() => normalizeDegrees(value), throwsArgumentError);
    }
  });
  test('uses circular distance across the full-turn seam', () {
    expect(angularDistance(359, 1), 2);
    expect(angularDistance(-1, 361), 2);
    expect(angularDistance(0, 180), 180);
    expect(angularDistance(315, 45), 90);
  });
  test('accepts every angle inside the inclusive tolerance', () {
    for (final value in [43.0, 44.2, 45.0, 46.8, 47.0, 405.0, -315.0]) {
      expect(isAngleCorrect(value, 45, 2), isTrue, reason: '$value');
    }
    expect(isAngleCorrect(42.999, 45, 2), isFalse);
    expect(isAngleCorrect(47.001, 45, 2), isFalse);
    expect(isAngleCorrect(359, 1, 2), isTrue);
  });
  test('rejects invalid answers, targets and tolerances', () {
    expect(isAngleCorrect(double.nan, 45, 2), isFalse);
    expect(isAngleCorrect(45, double.infinity, 2), isFalse);
    for (final tolerance in [0.0, -2.0, 180.0, double.nan, double.infinity]) {
      expect(isAngleCorrect(45, 45, tolerance), isFalse);
    }
  });
  test('calculates all four quadrants in mathematical coordinates', () {
    expect(angleFromVector(1, 0), 0);
    expect(angleFromVector(0, 1), 90);
    expect(angleFromVector(-1, 0), 180);
    expect(angleFromVector(0, -1), 270);
    expect(angleFromVector(1, 1), closeTo(45, 1e-9));
    expect(angleFromVector(-1, -1), closeTo(225, 1e-9));
  });
  test('explicitly handles undefined zero-length directions', () {
    expect(angleFromVector(0, 0), isNull);
    expect(angleFromVector(1e-9, 0), isNull);
    expect(angleFromVector(double.nan, 1), isNull);
    expect(angleFromVector(1, double.infinity), isNull);
  });
}
