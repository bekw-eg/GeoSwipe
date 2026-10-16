import '../core/geometry/angle_math.dart';
import '../core/geometry/scene.dart';
import 'attempt_result.dart';
import 'level.dart';

class PuzzleState {
  const PuzzleState({
    required this.scene,
    this.answer = '',
    this.hintUsed = false,
    this.attempts = 0,
    this.result,
  });
  factory PuzzleState.initial(Level level) =>
      PuzzleState(scene: level.initialGeometry);
  final GeometryScene scene;
  final String answer;
  double get angle {
    final rays = scene.rays.where((r) => r.rotatable);
    if (rays.isEmpty) return 0;
    final ray = rays.first;
    final vector = scene.points[ray.handle]! - scene.points[ray.origin]!;
    return angleFromVector(vector.x, vector.y) ?? 0;
  }

  final bool hintUsed;
  final int attempts;
  final AttemptResult? result;
  bool get isComplete => result?.isCorrect ?? false;

  PuzzleState withScene(GeometryScene value) => PuzzleState(
    scene: value,
    answer: answer,
    hintUsed: hintUsed,
    attempts: attempts,
  );
  PuzzleState withAnswer(String value) => PuzzleState(
    scene: scene,
    answer: value,
    hintUsed: hintUsed,
    attempts: attempts,
  );
  PuzzleState withHint() => PuzzleState(
    scene: scene,
    answer: answer,
    hintUsed: true,
    attempts: attempts,
    result: result,
  );
  PuzzleState withResult(AttemptResult value) => PuzzleState(
    scene: scene,
    answer: answer,
    hintUsed: hintUsed,
    attempts: attempts + 1,
    result: value,
  );
}
