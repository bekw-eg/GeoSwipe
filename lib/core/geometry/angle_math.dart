import 'dart:math' as math;

/// Degrees are measured counterclockwise from the positive horizontal axis.
double normalizeDegrees(double degrees) {
  if (!degrees.isFinite) {
    throw ArgumentError.value(degrees, 'degrees', 'Must be finite');
  }
  return degrees % 360;
}

double angularDistance(double first, double second) {
  final difference = (normalizeDegrees(first) - normalizeDegrees(second)).abs();
  return math.min(difference, 360 - difference);
}

/// Null preserves the last ray for a zero-length or non-finite vector.
/// [dy] uses mathematical coordinates: positive means up.
double? angleFromVector(double dx, double dy) {
  if (!dx.isFinite || !dy.isFinite || dx * dx + dy * dy < 1e-12) return null;
  return normalizeDegrees(math.atan2(dy, dx) * 180 / math.pi);
}

bool isAngleCorrect(double actual, double target, double tolerance) {
  if (!actual.isFinite ||
      !target.isFinite ||
      !tolerance.isFinite ||
      tolerance <= 0 ||
      tolerance >= 180) {
    return false;
  }
  // Inclusive tolerance, stable at floating-point boundaries.
  return angularDistance(actual, target) <= tolerance + 1e-9;
}
