import 'package:flutter/foundation.dart';
import '../data/level_catalog.dart';
import '../data/review_variants.dart';
import '../models/learning_progress.dart';
import '../data/progress_repository.dart';
import '../models/attempt_result.dart';
import '../models/level.dart';
import '../models/progress.dart';
import '../models/puzzle_state.dart';
import 'geometry/geometry.dart';
import 'geometry/scene.dart';

class AppController extends ChangeNotifier {
  AppController(this.repository, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final DateTime Function() clock;
  DateTime get now => clock().toUtc();
  bool _scheduledReview = false;
  bool get isScheduledReview => reviewLevel != null && _scheduledReview;
  final ProgressRepository repository;
  ProgressSnapshot progress = ProgressSnapshot();
  final Map<String, PuzzleState> _puzzles = {};
  Future<void> _writeQueue = Future.value();
  bool _disposed = false;
  bool isLoading = true;
  bool hasLoadError = false;
  bool hasSaveError = false;
  int tab = 0;
  int currentIndex = 0;
  int playRevision = 0;
  Level? reviewLevel;
  int reviewRevision = 0;

  List<Level> get completedLevels =>
      levels.where((l) => progress.forLevel(l.id).isCompleted).toList();
  int get completedCount => completedLevels.length;
  int get masteredCount =>
      levels.where((l) => skill(l).state == SkillState.confirmed).length;
  int get totalAttempts =>
      progress.levels.values.fold(0, (sum, p) => sum + p.attempts);
  int get totalCorrect =>
      progress.levels.values.fold(0, (sum, p) => sum + p.completions);
  int get assistedCount =>
      levels.where((l) => progress.forLevel(l.id).isAssistedOnly).length;

  SkillProgress skill(Level level) => progress.forSkill(level.skillId);
  int get independentCount => completedLevels
      .where((l) => progress.forLevel(l.id).independentCompletions > 0)
      .length;
  Map<String, int> get errorsByTopic => {
    for (final topic in topics)
      topic.id: levels
          .where((l) => l.topicId == topic.id)
          .fold(
            0,
            (sum, l) =>
                sum +
                progress.forLevel(l.id).attempts -
                progress.forLevel(l.id).completions,
          ),
  };
  List<Level> get dueLevels =>
      completedLevels.where((l) => skill(l).isDue(now)).toList()
        ..sort((a, b) => skill(a).dueAt!.compareTo(skill(b).dueAt!));
  void refreshTime() => _emit();

  void _started(Level level) {
    final before = skill(level);
    final after = before.started();
    if (identical(before, after)) return;
    progress = progress.copyWith(
      skills: {...progress.skills, level.skillId: after},
    );
    persist();
  }

  bool isUnlocked(int index) {
    if (index < 0 || index >= levels.length) return false;
    final level = levels[index];
    // A compatible completion from an older catalog always remains accessible.
    return progress.unlocked.contains(level.id) ||
        progress.forLevel(level.id).isCompleted ||
        level.prerequisiteIds.every((id) => progress.forLevel(id).isCompleted);
  }

  List<int> get unlockedIndices => [
    for (var i = 0; i < levels.length; i++)
      if (isUnlocked(i)) i,
  ];

  bool _canPlay(Level level, bool review) => review
      ? reviewLevel != null &&
            identical(level, reviewLevel) &&
            progress.forLevel(level.id).isCompleted
      : isUnlocked(levels.indexOf(level));

  Future<void> load() async {
    isLoading = true;
    _emit();
    try {
      progress = await repository.load();
      final migrated = {...progress.skills};
      for (final level in levels) {
        final old = progress.forLevel(level.id);
        if (!migrated.containsKey(level.skillId) && old.attempts > 0) {
          migrated[level.skillId] = SkillProgress(
            state: old.independentCompletions > 0
                ? SkillState.independent
                : old.isCompleted
                ? SkillState.assisted
                : SkillState.studying,
            dueAt: old.isCompleted ? now.add(const Duration(days: 1)) : null,
          );
        }
      }
      progress = progress.copyWith(
        skills: migrated,
        unlocked: {
          ...progress.unlocked,
          for (final i in unlockedIndices) levels[i].id,
        },
      );
      final index = levels.indexWhere((l) => l.id == progress.lastLevelId);
      currentIndex = isUnlocked(index) ? index : 0;
      // A successful retry restores a coherent session from the saved snapshot.
      _puzzles.clear();
      reviewLevel = null;
      playRevision++;
      hasLoadError = false;
    } catch (_) {
      // Never replace unreadable or future-version data with an empty save.
      hasLoadError = true;
    }
    isLoading = false;
    if (!hasLoadError) await persist();
    _emit();
  }

  void selectTab(int value) {
    tab = value;
    _emit();
  }

  void openLevel(int index) {
    if (!isUnlocked(index)) return;
    currentIndex = index;
    _started(levels[index]);
    tab = 0;
    playRevision++;
    progress = progress.withLastLevel(levels[index].id);
    persist();
    _emit();
  }

  void changePage(int index) {
    if (!isUnlocked(index)) return;
    currentIndex = index;
    _started(levels[index]);
    progress = progress.withLastLevel(levels[index].id);
    persist();
    _emit();
  }

  String _key(Level level, bool review) =>
      '${review ? 'review' : 'play'}:${level.id}';
  PuzzleState puzzle(Level level, {bool review = false}) =>
      _puzzles[_key(level, review)] ??
      PuzzleState(
        scene: level.initialGeometry,
        hintCount: progress.activeHints[_key(level, review)] ?? 0,
        hintUsed: (progress.activeHints[_key(level, review)] ?? 0) > 0,
      );

  void rotate(Level level, double angle, {bool review = false}) {
    if (!_canPlay(level, review) ||
        !angle.isFinite ||
        level.kind != PuzzleKind.rotateRay ||
        puzzle(level, review: review).isComplete) {
      return;
    }
    final scene = puzzle(level, review: review).scene;
    final ray = scene.rays.firstWhere((r) => r.rotatable);
    final fixed = scene.rays.where(
      (r) => !r.rotatable && r.origin == ray.origin,
    );
    final reference = fixed.isEmpty
        ? 0.0
        : Geometry.directedAngle(
            const GeoPoint(1, 0),
            scene.points[fixed.first.handle]! -
                scene.points[fixed.first.origin]!,
          )!;
    updateGeometry(
      level,
      scene.rotateRay(ray, reference + angle),
      review: review,
    );
  }

  void updateGeometry(Level level, GeometryScene scene, {bool review = false}) {
    if (!_canPlay(level, review) ||
        puzzle(level, review: review).isComplete ||
        level.kind == PuzzleKind.numericAnswer) {
      return;
    }
    _started(level);
    _puzzles[_key(level, review)] = puzzle(
      level,
      review: review,
    ).withScene(scene);
    _emit();
  }

  void moveVertex(
    Level level,
    String id,
    GeoPoint point, {
    bool review = false,
  }) {
    final state = puzzle(level, review: review);
    if (state.isComplete ||
        !point.isFinite ||
        !state.scene.draggable.contains(id)) {
      return;
    }
    updateGeometry(
      level,
      state.scene.withPoint(id, state.scene.bounds.clamp(point)),
      review: review,
    );
  }

  void answer(Level level, String value, {bool review = false}) {
    if (!_canPlay(level, review) ||
        level.kind != PuzzleKind.numericAnswer ||
        puzzle(level, review: review).isComplete) {
      return;
    }
    _started(level);
    _puzzles[_key(level, review)] = puzzle(
      level,
      review: review,
    ).withAnswer(value);
    _emit();
  }

  void showHint(Level level, {bool review = false}) {
    if (!_canPlay(level, review) ||
        puzzle(level, review: review).isComplete ||
        puzzle(level, review: review).hintCount >= level.hints.length) {
      return;
    }
    _started(level);
    final next = puzzle(level, review: review).withHint();
    _puzzles[_key(level, review)] = next;
    progress = progress.copyWith(
      activeHints: {
        ...progress.activeHints,
        _key(level, review): next.hintCount,
      },
    );
    persist();
    _emit();
  }

  void restart(Level level, {bool review = false}) {
    if (!_canPlay(level, review)) return;
    if (review && puzzle(level, review: true).isComplete) {
      startReview(levelId: level.id);
      return;
    }
    // Restarting an unfinished task resets input, never its assistance history.
    final hints = progress.activeHints[_key(level, review)] ?? 0;
    _puzzles[_key(level, review)] = PuzzleState(
      scene: level.initialGeometry,
      hintCount: hints,
      hintUsed: hints > 0,
    );
    _emit();
  }

  AttemptResult submit(Level level, {bool review = false}) {
    if (!_canPlay(level, review)) {
      return const AttemptResult(
        outcome: AttemptOutcome.incorrect,
        angle: 0,
        error: 0,
        feedback: 'Сначала реши предыдущий уровень.',
        hintUsed: false,
      );
    }
    final state = puzzle(level, review: review);
    if (state.isComplete) return state.result!;
    final check = level.validation.check(state.scene, answer: state.answer);
    final timestamp = now;
    final scheduled =
        review && _scheduledReview && skill(level).isDue(timestamp);
    final result = AttemptResult(
      outcome: check.isCorrect
          ? AttemptOutcome.correct
          : AttemptOutcome.incorrect,
      angle: state.angle,
      error: check.error,
      feedback: check.message,
      hintUsed: state.hintUsed,
    );
    _puzzles[_key(level, review)] = state.withResult(result);
    progress = progress.withLevel(
      level.id,
      progress
          .forLevel(level.id)
          .record(
            correct: result.isCorrect,
            hintUsed: state.hintUsed,
            isReview: review,
          ),
    );
    final activeHints = {...progress.activeHints};
    if (result.isCorrect) activeHints.remove(_key(level, review));
    progress = progress.copyWith(
      skills: {
        ...progress.skills,
        level.skillId: skill(level).record(
          correct: result.isCorrect,
          assisted: state.hintUsed,
          scheduledReview: scheduled,
          now: timestamp,
        ),
      },
      history: [
        ...progress.history,
        AttemptRecord(
          levelId: level.id,
          topicId: level.topicId,
          at: timestamp,
          correct: result.isCorrect,
          hintCount: state.hintCount,
          review: review,
          scheduledReview: scheduled,
          variant: level.variant,
          answer: state.answer,
        ),
      ],
      activeHints: activeHints,
      reviewVariants: {
        ...progress.reviewVariants,
        if (review && result.isCorrect) level.id: level.variant,
      },
      unlocked: {
        ...progress.unlocked,
        for (final i in unlockedIndices) levels[i].id,
      },
    );
    // An error/assisted solve invalidates eligibility for the rest of this session.
    if (review && (!result.isCorrect || state.hintUsed)) {
      _scheduledReview = false;
    }
    persist();
    _emit();
    return result;
  }

  void startReview({String? levelId}) {
    final available = completedLevels;
    if (available.isEmpty) return;
    available.sort((a, b) {
      final ad = skill(a).dueAt;
      final bd = skill(b).dueAt;
      if (ad == null) return bd == null ? a.id.compareTo(b.id) : 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });
    final matches = available.where((l) => l.id == levelId);
    if (levelId != null && matches.isEmpty) return;
    final base = levelId == null ? available.first : matches.first;
    reviewLevel = reviewVariant(base, progress.reviewVariants[base.id] ?? 0);
    _scheduledReview = skill(base).isDue(now);
    _puzzles.remove(_key(reviewLevel!, true));
    reviewRevision++;
    tab = 2;
    _emit();
  }

  void closeReview() {
    reviewLevel = null;
    _emit();
  }

  Future<void> persist() {
    if (hasLoadError || isLoading) return Future.value();
    final snapshot = progress;
    _writeQueue = _writeQueue.then((_) async {
      try {
        await repository.save(snapshot);
        hasSaveError = false;
      } catch (_) {
        hasSaveError = true;
      }
      _emit();
    });
    return _writeQueue;
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
