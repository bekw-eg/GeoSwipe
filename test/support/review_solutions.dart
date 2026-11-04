import 'dart:math' as math;
import 'package:geoswipe/core/app_controller.dart';
import 'package:geoswipe/core/geometry/geometry.dart';
import 'package:geoswipe/models/level.dart';

// Independent calculations for the generated parameter sets. No expected values
// are read from the constraints under test.
double reviewAnswer(Level level) {
  final n = level.variant;
  final a = 7.0 + n;
  final b = 11.0 + n;
  final k = 3.0 + n;
  final alpha = 22.0 + n % 23;
  return switch (level.id) {
    'angle-complement' => 90 - alpha,
    'angle-supplement' => 180 - (alpha + 80),
    'triangle-angle-sum' => 180 - alpha - (65 + n % 10),
    'triangle-base-angle' => (180 - (42 + 2 * (n % 18))) / 2,
    'triangle-exterior' => alpha + 65 + n % 10,
    'triangle-combined' => 2 * (115 + n % 14) - 180,
    'pythagoras-legs' => a + b,
    'pythagoras-squares' => a * a + b * b,
    'pythagoras-3-4' => math.sqrt(math.pow(5 * k, 2) + math.pow(12 * k, 2)),
    'pythagoras-missing-leg' || 'pythagoras-ladder' || 'pythagoras-combined' =>
      math.sqrt(math.pow(17 * k, 2) - math.pow(8 * k, 2)),
    'pythagoras-diagonal' => math.sqrt(a * a + b * b),
    'pythagoras-distance' => math.sqrt(math.pow(3 * k, 2) + math.pow(4 * k, 2)),
    'trig-sine' => b / math.sqrt(a * a + b * b),
    'trig-cosine' => a / math.sqrt(a * a + b * b),
    'trig-tangent' => b / a,
    'trig-length' => (18 + 2 * n) * math.sin(math.pi / 6),
    'trig-function' => a * math.tan(math.pi / 4),
    'trig-application' => a * math.tan(math.pi / 3),
    'trig-final' => math.sqrt(
      math.pow((30 + 2 * n) * math.cos(math.pi / 6), 2) +
          math.pow((30 + 2 * n) * math.sin(math.pi / 6) + 6 + n, 2),
    ),
    _ => throw ArgumentError(level.id),
  };
}

void solveReview(AppController controller) {
  final level = controller.reviewLevel!;
  switch (level.kind) {
    case PuzzleKind.numericAnswer:
      controller.answer(
        level,
        reviewAnswer(level).toStringAsFixed(2),
        review: true,
      );
    case PuzzleKind.rotateRay:
      final angle = switch (level.id) {
        'angle-45' => 48.0 + 2 * (level.variant % 12),
        'angle-90' => 90.0,
        'angle-135' => 135.0,
        'trig-standard-angle' =>
          math.acos([.3, .4, .7, .8][(level.variant - 1) % 4]) * 180 / math.pi,
        _ => throw ArgumentError(level.id),
      };
      controller.rotate(level, angle, review: true);
    case PuzzleKind.dragVertices:
      final scale = 1.15 + level.variant * .07;
      final c = switch (level.id) {
        'triangle-isosceles' => const GeoPoint(3, 4),
        'triangle-right' || 'pythagoras-construct' => const GeoPoint(3, 3),
        'trig-side-ratio' => const GeoPoint(0, 3),
        'trig-scale' => const GeoPoint(0, 6),
        _ => throw ArgumentError(level.id),
      };
      controller.moveVertex(level, 'C', c * scale, review: true);
  }
}
