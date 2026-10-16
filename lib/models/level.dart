import '../core/geometry/constraints.dart';
import '../core/geometry/scene.dart';

enum PuzzleKind { rotateRay, dragVertices, numericAnswer }

enum LearningStage { explore, rule, practice, challenge }

class Level {
  const Level({
    required this.id,
    required this.topicId,
    required this.title,
    this.targetAngle = 0,
    this.initialAngle = 15,
    required this.hint,
    required this.explanation,
    this.tolerance = 2,
    this.kind = PuzzleKind.rotateRay,
    this.initialScene,
    this.constraint,
    this.instruction = 'Поверни луч до заданного угла',
    this.goalLabel,
    this.answerLabel = 'Численный ответ',
    this.stage = LearningStage.practice,
    this.knowledge = const [],
    this.prerequisiteIds = const [],
    this.extraHints = const [],
    this.accuracy,
    this.guidedHints,
    this.variant = 0,
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
  final GeometryScene? initialScene;
  final GeometryConstraint? constraint;
  final String instruction;
  final String? goalLabel;
  final String answerLabel;
  final LearningStage stage;
  final List<String> knowledge;
  final List<String> prerequisiteIds;
  final List<String> extraHints;
  final String? accuracy;
  final List<String>? guidedHints;
  final int variant;
  String get skillId => id;
  List<String> get hints => guidedHints ?? [hint, ...extraHints];
  String get stageLabel => switch (stage) {
    LearningStage.explore => 'Исследуй',
    LearningStage.rule => 'Открой правило',
    LearningStage.practice => 'Реши самостоятельно',
    LearningStage.challenge => 'Испытание',
  };
  GeometryScene get initialGeometry => initialScene ?? angleScene(initialAngle);
  GeometryConstraint get validation =>
      constraint ??
      AngleConstraint('A', 'O', 'B', target: targetAngle, tolerance: tolerance);
  String get goal => goalLabel ?? '${targetAngle.round()}°';
  String get toleranceDescription =>
      accuracy ??
      switch (validation) {
        AngleConstraint(:final tolerance, :final directed) =>
          directed
              ? 'Допуск ±$tolerance° · Отсчёт против часовой стрелки'
              : 'Допуск ±$tolerance° · Меньший угол между лучами',
        RightTriangleConstraint(:final toleranceDegrees) =>
          'Допуск прямого угла ±$toleranceDegrees° · Подходит любая вершина',
        NumericAnswerConstraint(:final absoluteTolerance) =>
          absoluteTolerance == 0
              ? 'Точное целое число · Можно использовать запятую'
              : 'Ответ числом · Допуск ±${absoluteTolerance.toString().replaceAll('.', ',')} · Можно использовать запятую',
        _ => 'Выполни все условия задачи',
      };
}
