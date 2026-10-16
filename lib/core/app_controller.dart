import 'package:flutter/foundation.dart';
import '../data/level_catalog.dart';
import '../data/progress_repository.dart';
import '../models/attempt_result.dart';
import '../models/level.dart';
import '../models/progress.dart';
import '../models/puzzle_state.dart';
import 'geometry/geometry.dart';
import 'geometry/scene.dart';

class AppController extends ChangeNotifier {
  AppController(this.repository);
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
      levels.where((l) => progress.forLevel(l.id).isMastered).length;
  int get totalAttempts =>
      progress.levels.values.fold(0, (sum, p) => sum + p.attempts);
  int get totalCorrect =>
      progress.levels.values.fold(0, (sum, p) => sum + p.completions);
  int get assistedCount =>
      levels.where((l) => progress.forLevel(l.id).isAssistedOnly).length;

  Future<void> load() async {
    isLoading = true;
    _emit();
    try {
      progress = await repository.load();
      final index = levels.indexWhere((l) => l.id == progress.lastLevelId);
      currentIndex = index < 0 ? 0 : index;
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
    _emit();
  }

  void selectTab(int value) {
    tab = value;
    _emit();
  }

  void openLevel(int index) {
    currentIndex = index;
    tab = 0;
    playRevision++;
    progress = progress.withLastLevel(levels[index].id);
    persist();
    _emit();
  }

  void changePage(int index) {
    currentIndex = index;
    progress = progress.withLastLevel(levels[index].id);
    persist();
    _emit();
  }

  String _key(Level level, bool review) =>
      '${review ? 'review' : 'play'}:${level.id}';
  PuzzleState puzzle(Level level, {bool review = false}) =>
      _puzzles[_key(level, review)] ?? PuzzleState.initial(level);

  void rotate(Level level, double angle, {bool review = false}) {
    if (!angle.isFinite ||
        level.kind != PuzzleKind.rotateRay ||
        puzzle(level, review: review).isComplete) {
      return;
    }
    final scene = puzzle(level, review: review).scene;
    updateGeometry(
      level,
      scene.rotateRay(scene.rays.firstWhere((r) => r.rotatable), angle),
      review: review,
    );
  }

  void updateGeometry(Level level, GeometryScene scene, {bool review = false}) {
    if (puzzle(level, review: review).isComplete ||
        level.kind == PuzzleKind.numericAnswer) {
      return;
    }
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
    if (level.kind != PuzzleKind.numericAnswer ||
        puzzle(level, review: review).isComplete) {
      return;
    }
    _puzzles[_key(level, review)] = puzzle(
      level,
      review: review,
    ).withAnswer(value);
    _emit();
  }

  void showHint(Level level, {bool review = false}) {
    if (puzzle(level, review: review).isComplete) return;
    _puzzles[_key(level, review)] = puzzle(level, review: review).withHint();
    _emit();
  }

  void restart(Level level, {bool review = false}) {
    _puzzles[_key(level, review)] = PuzzleState.initial(level);
    _emit();
  }

  AttemptResult submit(Level level, {bool review = false}) {
    final state = puzzle(level, review: review);
    if (state.isComplete) return state.result!;
    final check = level.validation.check(state.scene, answer: state.answer);
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
    persist();
    _emit();
    return result;
  }

  void startReview({String? levelId}) {
    final available = completedLevels;
    if (available.isEmpty) return;
    available.sort((a, b) {
      final ap = progress.forLevel(a.id);
      final bp = progress.forLevel(b.id);
      final mastery = (ap.isMastered ? 1 : 0).compareTo(bp.isMastered ? 1 : 0);
      return mastery != 0
          ? mastery
          : ap.independentReviews.compareTo(bp.independentReviews);
    });
    reviewLevel = levelId == null
        ? available.first
        : available.firstWhere((l) => l.id == levelId);
    _puzzles[_key(reviewLevel!, true)] = PuzzleState.initial(reviewLevel!);
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
