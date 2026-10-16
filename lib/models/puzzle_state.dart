import 'attempt_result.dart';

class PuzzleState {
  const PuzzleState({
    required this.angle,
    this.hintUsed = false,
    this.attempts = 0,
    this.result,
  });
  final double angle;
  final bool hintUsed;
  final int attempts;
  final AttemptResult? result;
  bool get isComplete => result?.isCorrect ?? false;

  PuzzleState withAngle(double value) =>
      PuzzleState(angle: value, hintUsed: hintUsed, attempts: attempts);
  PuzzleState withHint() => PuzzleState(
    angle: angle,
    hintUsed: true,
    attempts: attempts,
    result: result,
  );
  PuzzleState withResult(AttemptResult value) => PuzzleState(
    angle: angle,
    hintUsed: hintUsed,
    attempts: attempts + 1,
    result: value,
  );
}
