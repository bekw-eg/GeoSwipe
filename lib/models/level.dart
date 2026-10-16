enum PuzzleKind { rotateRay }

class Level {
  const Level({
    required this.id,
    required this.topicId,
    required this.title,
    required this.targetAngle,
    required this.initialAngle,
    required this.hint,
    required this.explanation,
    this.tolerance = 2,
    this.kind = PuzzleKind.rotateRay,
  }) : assert(targetAngle >= 0 && targetAngle < 360),
       assert(initialAngle >= 0 && initialAngle < 360),
       assert(tolerance > 0 && tolerance < 180);

  final String id;
  final String topicId;
  final String title;
  final PuzzleKind kind;
  final double targetAngle;
  final double initialAngle;
  final double tolerance;
  final String hint;
  final String explanation;
}
