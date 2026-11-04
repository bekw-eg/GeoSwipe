import 'learning_progress.dart';

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
    Map<String, SkillProgress> skills = const {},
    List<AttemptRecord> history = const [],
    Map<String, int> activeHints = const {},
    Map<String, int> reviewVariants = const {},
    Set<String> unlocked = const {},
  }) : levels = Map.unmodifiable(levels),
       skills = Map.unmodifiable(skills),
       history = List.unmodifiable(history),
       activeHints = Map.unmodifiable(activeHints),
       reviewVariants = Map.unmodifiable(reviewVariants),
       unlocked = Set.unmodifiable(unlocked);
  final Map<String, LevelProgress> levels;
  final String? lastLevelId;
  final Map<String, SkillProgress> skills;
  final List<AttemptRecord> history;
  final Map<String, int> activeHints;
  final Map<String, int> reviewVariants;
  final Set<String> unlocked;
  LevelProgress forLevel(String id) => levels[id] ?? const LevelProgress();
  SkillProgress forSkill(String id) => skills[id] ?? const SkillProgress();
  ProgressSnapshot copyWith({
    Map<String, LevelProgress>? levels,
    String? lastLevelId,
    Map<String, SkillProgress>? skills,
    List<AttemptRecord>? history,
    Map<String, int>? activeHints,
    Map<String, int>? reviewVariants,
    Set<String>? unlocked,
  }) => ProgressSnapshot(
    levels: levels ?? this.levels,
    lastLevelId: lastLevelId ?? this.lastLevelId,
    skills: skills ?? this.skills,
    history: history ?? this.history,
    activeHints: activeHints ?? this.activeHints,
    reviewVariants: reviewVariants ?? this.reviewVariants,
    unlocked: unlocked ?? this.unlocked,
  );
  ProgressSnapshot withLevel(String id, LevelProgress progress) =>
      copyWith(levels: {...levels, id: progress}, lastLevelId: id);
  ProgressSnapshot withLastLevel(String id) => copyWith(lastLevelId: id);

  Map<String, Object?> toJson() => {
    'version': 2,
    'lastLevelId': lastLevelId,
    'levels': levels.map((id, progress) => MapEntry(id, progress.toJson())),
    'skills': skills.map((id, progress) => MapEntry(id, progress.toJson())),
    'history': history.map((a) => a.toJson()).toList(),
    'activeHints': activeHints,
    'reviewVariants': reviewVariants,
    'unlocked': unlocked.toList(),
  };

  factory ProgressSnapshot.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version != 1 && version != 2) {
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
    if (version == 1) {
      // Dates and individual attempts were never stored by v1. Do not invent them.
      return ProgressSnapshot(levels: levels, lastLevelId: lastId as String?);
    }
    Map<String, int> counts(String key, {int? max}) {
      final raw = json[key];
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Invalid saved counters');
      }
      return raw.map((id, value) {
        if (value is! int || value < 0 || (max != null && value > max)) {
          throw const FormatException('Invalid saved counter');
        }
        return MapEntry(id, value);
      });
    }

    final skills = json['skills'];
    final history = json['history'];
    final unlocked = json['unlocked'];
    if (skills is! Map<String, dynamic> ||
        history is! List ||
        unlocked is! List ||
        unlocked.any((id) => id is! String)) {
      throw const FormatException('Invalid learning data');
    }
    return ProgressSnapshot(
      levels: levels,
      lastLevelId: lastId as String?,
      skills: skills.map(
        (id, value) =>
            MapEntry(id, SkillProgress.fromJson(value as Map<String, dynamic>)),
      ),
      history: history
          .map((a) => AttemptRecord.fromJson(a as Map<String, dynamic>))
          .toList(),
      activeHints: counts('activeHints', max: 3),
      reviewVariants: counts('reviewVariants'),
      unlocked: unlocked.cast<String>().toSet(),
    );
  }
}
