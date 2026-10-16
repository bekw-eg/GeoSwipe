import 'dart:math' as math;
import 'package:geoswipe/core/app_controller.dart';
import 'package:geoswipe/core/geometry/geometry.dart';
import 'package:geoswipe/core/geometry/scene.dart';
import 'package:geoswipe/data/level_catalog.dart';
import 'package:geoswipe/models/level.dart';

// Independent worked solutions, deliberately not read from constraint.expected.
final numericSolutions = <String, double>{
  'angle-complement': 90 - 35,
  'angle-supplement': 180 - 125,
  'triangle-angle-sum': 180 - 50 - 60,
  'triangle-base-angle': (180 - 40) / 2,
  'triangle-exterior': 50 + 60,
  'triangle-combined': 180 - 2 * (180 - 130),
  'pythagoras-legs': 8 + 6,
  'pythagoras-squares': 9 + 16,
  'pythagoras-3-4': math.sqrt(3 * 3 + 4 * 4),
  'pythagoras-missing-leg': math.sqrt(13 * 13 - 5 * 5),
  'pythagoras-diagonal': math.sqrt(7 * 7 + 5 * 5),
  'pythagoras-distance': math.sqrt(
    math.pow(4 - (-2), 2) + math.pow(7 - (-1), 2),
  ),
  'pythagoras-ladder': math.sqrt(10 * 10 - 6 * 6),
  'pythagoras-combined': math.sqrt(13 * 13 - math.pow(10 / 2, 2)),
  'trig-sine': 3 / 5,
  'trig-cosine': 4 / 5,
  'trig-tangent': 3 / 4,
  'trig-length': 10 * math.sin(math.pi / 6),
  'trig-function': 12 * math.tan(math.pi / 4),
  'trig-application': 6 * math.tan(math.pi / 3),
  'trig-final': math.sqrt(
    math.pow(26 * math.cos(math.pi / 6), 2) +
        math.pow(26 * math.sin(math.pi / 6) + 5, 2),
  ),
};

final vertexSolutions = <String, GeoPoint>{
  'triangle-isosceles': const GeoPoint(3, 4),
  'triangle-right': const GeoPoint(3, 3),
  'pythagoras-construct': const GeoPoint(3, 3),
  'trig-side-ratio': const GeoPoint(0, 3),
  'trig-scale': const GeoPoint(0, 6),
};

const raySolutions = <String, double>{
  'angle-45': 45,
  'angle-90': 90,
  'angle-135': 135,
  'trig-standard-angle': 60,
};

GeometryScene solvedScene(Level level) {
  final scene = level.initialGeometry;
  if (vertexSolutions.containsKey(level.id)) {
    return scene.withPoint('C', vertexSolutions[level.id]!);
  }
  if (raySolutions.containsKey(level.id)) {
    return scene.rotateRay(
      scene.rays.firstWhere((r) => r.rotatable),
      raySolutions[level.id]!,
    );
  }
  return scene;
}

void enterSolution(
  AppController controller,
  Level level, {
  bool review = false,
}) {
  switch (level.kind) {
    case PuzzleKind.rotateRay:
      controller.rotate(level, raySolutions[level.id]!, review: review);
    case PuzzleKind.dragVertices:
      controller.moveVertex(
        level,
        'C',
        vertexSolutions[level.id]!,
        review: review,
      );
    case PuzzleKind.numericAnswer:
      final value = numericSolutions[level.id]!;
      controller.answer(
        level,
        value.toStringAsFixed(2).replaceAll('.', ','),
        review: review,
      );
  }
}

void completeBefore(AppController controller, String id) {
  for (final level in levels.takeWhile((l) => l.id != id)) {
    if (!controller.progress.forLevel(level.id).isCompleted) {
      enterSolution(controller, level);
      controller.submit(level);
    }
  }
}
