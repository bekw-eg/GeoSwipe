enum SkillState {
  notStudied('Не изучен'),
  studying('Изучается'),
  assisted('Решается с подсказками'),
  independent('Решается самостоятельно'),
  confirmed('Подтверждён повторением');

  const SkillState(this.label);
  final String label;
}

class SkillProgress {
  const SkillProgress({
    this.state = SkillState.notStudied,
    this.reviewStage = 0,
    this.dueAt,
  });
  final SkillState state;
  // 0: wait 1 day, 1: wait 3 days, 2: wait 7 days, 3: maintenance.
  final int reviewStage;
  final DateTime? dueAt;
  bool isDue(DateTime now) => dueAt != null && !now.isBefore(dueAt!);
  SkillProgress started() => state == SkillState.notStudied
      ? const SkillProgress(state: SkillState.studying)
      : this;

  SkillProgress record({
    required bool correct,
    required bool assisted,
    required bool scheduledReview,
    required DateTime now,
  }) {
    if (!correct) {
      final stage = (reviewStage - 1).clamp(0, 2);
      return SkillProgress(
        state: SkillState.studying,
        reviewStage: stage,
        dueAt: dueAt == null ? null : now.add(intervals[stage]),
      );
    }
    if (assisted) {
      return SkillProgress(
        state: SkillState.assisted,
        dueAt: now.add(intervals[0]),
      );
    }
    final hasIndependent =
        state == SkillState.independent || state == SkillState.confirmed;
    if (scheduledReview && hasIndependent) {
      final stage = (reviewStage + 1).clamp(0, 3);
      return SkillProgress(
        state: stage == 3 ? SkillState.confirmed : SkillState.independent,
        reviewStage: stage,
        dueAt: now.add(intervals[stage]),
      );
    }
    return SkillProgress(
      state: state == SkillState.confirmed
          ? SkillState.confirmed
          : SkillState.independent,
      reviewStage: reviewStage,
      // Early practice cannot postpone or accelerate an existing review.
      dueAt: hasIndependent
          ? dueAt ?? now.add(intervals[reviewStage])
          : now.add(intervals[reviewStage]),
    );
  }

  static const intervals = [
    Duration(days: 1),
    Duration(days: 3),
    Duration(days: 7),
    Duration(days: 7),
  ];
  Map<String, Object?> toJson() => {
    'state': state.name,
    'reviewStage': reviewStage,
    'dueAt': dueAt?.toUtc().toIso8601String(),
  };
  factory SkillProgress.fromJson(Map<String, dynamic> json) {
    final stage = json['reviewStage'];
    final state = SkillState.values.where((s) => s.name == json['state']);
    if (stage is! int || stage < 0 || stage > 3 || state.isEmpty) {
      throw const FormatException('Invalid skill');
    }
    final due = json['dueAt'];
    if ((due != null && due is! String) ||
        (state.single == SkillState.notStudied &&
            (due != null || stage != 0)) ||
        (state.single == SkillState.assisted && stage != 0) ||
        (state.single == SkillState.confirmed && stage != 3) ||
        (state.single != SkillState.confirmed && stage == 3) ||
        (due == null &&
            (stage > 0 ||
                state.single == SkillState.assisted ||
                state.single == SkillState.independent))) {
      throw const FormatException('Inconsistent skill');
    }
    return SkillProgress(
      state: state.single,
      reviewStage: stage,
      dueAt: due == null ? null : DateTime.parse(due as String).toUtc(),
    );
  }
}

class AttemptRecord {
  const AttemptRecord({
    required this.levelId,
    required this.topicId,
    required this.at,
    required this.correct,
    required this.hintCount,
    required this.review,
    required this.scheduledReview,
    required this.variant,
    required this.answer,
  });
  final String levelId;
  final String topicId;
  final DateTime at;
  final bool correct;
  final int hintCount;
  final bool review;
  final bool scheduledReview;
  final int variant;
  final String answer;

  Map<String, Object?> toJson() => {
    'levelId': levelId,
    'topicId': topicId,
    'at': at.toUtc().toIso8601String(),
    'correct': correct,
    'hintCount': hintCount,
    'review': review,
    'scheduledReview': scheduledReview,
    'variant': variant,
    'answer': answer,
  };
  factory AttemptRecord.fromJson(Map<String, dynamic> json) {
    if (json['at'] is! String ||
        json['levelId'] is! String ||
        json['topicId'] is! String ||
        json['correct'] is! bool ||
        json['review'] is! bool ||
        json['scheduledReview'] is! bool ||
        json['hintCount'] is! int ||
        (json['hintCount'] as int) < 0 ||
        (json['hintCount'] as int) > 3 ||
        json['variant'] is! int ||
        (json['variant'] as int) < 0 ||
        json['answer'] is! String ||
        (json['scheduledReview'] == true && json['review'] != true) ||
        (json['review'] == true && json['variant'] == 0) ||
        (json['review'] == false && json['variant'] != 0)) {
      throw const FormatException('Invalid attempt');
    }
    return AttemptRecord(
      levelId: json['levelId'] as String,
      topicId: json['topicId'] as String,
      at: DateTime.parse(json['at'] as String).toUtc(),
      correct: json['correct'] as bool,
      hintCount: json['hintCount'] as int,
      review: json['review'] as bool,
      scheduledReview: json['scheduledReview'] as bool,
      variant: json['variant'] as int,
      answer: json['answer'] as String,
    );
  }
}
