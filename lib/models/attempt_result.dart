enum AttemptOutcome { correct, incorrect }

class AttemptResult {
  const AttemptResult({
    required this.outcome,
    required this.angle,
    required this.error,
    required this.hintUsed,
  });
  final AttemptOutcome outcome;
  final double angle;
  final double error;
  final bool hintUsed;
  bool get isCorrect => outcome == AttemptOutcome.correct;
}
