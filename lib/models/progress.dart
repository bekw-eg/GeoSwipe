class LevelProgress {
  const LevelProgress({
    this.attempts = 0,
    this.completions = 0,
    this.assistedCompletions = 0,
    this.independentCompletions = 0,
    this.independentReviews = 0,
  });
  final int attempts;
  final int completions;
  final int assistedCompletions;
  final int independentCompletions;
  final int independentReviews;
  bool get isCompleted => completions > 0;
  bool get isMastered => independentCompletions >= 2 && independentReviews > 0;
  bool get isAssistedOnly => isCompleted && independentCompletions == 0;

  LevelProgress record({
    required bool correct,
    required bool hintUsed,
    required bool isReview,
  }) => LevelProgress(
    attempts: attempts + 1,
    completions: completions + (correct ? 1 : 0),
    assistedCompletions: assistedCompletions + (correct && hintUsed ? 1 : 0),
    independentCompletions:
        independentCompletions + (correct && !hintUsed ? 1 : 0),
    independentReviews:
        independentReviews + (correct && !hintUsed && isReview ? 1 : 0),
  );

  Map<String, Object> toJson() => {
    'attempts': attempts,
    'completions': completions,
    'assistedCompletions': assistedCompletions,
    'independentCompletions': independentCompletions,
    'independentReviews': independentReviews,
  };

  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    int count(String key) {
      final value = json[key];
      if (value is! int || value < 0) {
        throw const FormatException('Invalid counter');
      }
      return value;
    }

    final result = LevelProgress(
      attempts: count('attempts'),
      completions: count('completions'),
      assistedCompletions: count('assistedCompletions'),
      independentCompletions: count('independentCompletions'),
      independentReviews: count('independentReviews'),
    );
    if (result.completions > result.attempts ||
        result.assistedCompletions + result.independentCompletions !=
            result.completions ||
        result.independentReviews > result.independentCompletions) {
      throw const FormatException('Inconsistent counters');
    }
    return result;
  }
}

class ProgressSnapshot {
  ProgressSnapshot({
    Map<String, LevelProgress> levels = const {},
    this.lastLevelId,
  }) : levels = Map.unmodifiable(levels);
  final Map<String, LevelProgress> levels;
  final String? lastLevelId;
  LevelProgress forLevel(String id) => levels[id] ?? const LevelProgress();
  ProgressSnapshot withLevel(String id, LevelProgress progress) =>
      ProgressSnapshot(levels: {...levels, id: progress}, lastLevelId: id);
  ProgressSnapshot withLastLevel(String id) =>
      ProgressSnapshot(levels: levels, lastLevelId: id);

  Map<String, Object?> toJson() => {
    'version': 1,
    'lastLevelId': lastLevelId,
    'levels': levels.map((id, progress) => MapEntry(id, progress.toJson())),
  };

  factory ProgressSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported save version');
    }
    final raw = json['levels'];
    final lastId = json['lastLevelId'];
    if (raw is! Map<String, dynamic> || (lastId != null && lastId is! String)) {
      throw const FormatException('Invalid save structure');
    }
    final levels = <String, LevelProgress>{};
    for (final entry in raw.entries) {
      if (entry.value is! Map<String, dynamic>) {
        throw const FormatException('Invalid level progress');
      }
      levels[entry.key] = LevelProgress.fromJson(
        entry.value as Map<String, dynamic>,
      );
    }
    return ProgressSnapshot(levels: levels, lastLevelId: lastId as String?);
  }
}
