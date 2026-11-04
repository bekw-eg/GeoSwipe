import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoswipe/app.dart';
import 'package:geoswipe/core/app_controller.dart';
import 'package:geoswipe/data/level_catalog.dart';
import 'package:geoswipe/data/progress_repository.dart';
import 'package:geoswipe/models/level.dart';
import 'package:geoswipe/models/progress.dart';
import 'support/course_solutions.dart';
import 'package:geoswipe/core/learning_explanation.dart';
import 'support/memory_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  late AppController controller;
  final captureKey = GlobalKey();
  setUp(() async {
    controller = AppController(ProgressRepository(MemoryStore()));
    await controller.load();
  });
  tearDown(() => controller.dispose());

  Future<void> launch(
    WidgetTester tester, {
    Size size = const Size(390, 1000),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
          ),
          child: GeoSwipeApp(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pressCheck(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('check-answer')).first;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final boundary =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    boundary.markNeedsPaint();
    await tester.pump();
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/ui').create(recursive: true);
      await File(
        'build/ui/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
    'all 30 lessons hide solutions, accept answers and advance to the next task',
    (tester) async {
      await launch(tester);
      for (var i = 0; i < levels.length; i++) {
        final level = levels[i];
        expect(controller.currentIndex, i, reason: level.id);
        expect(find.text(level.title), findsOneWidget);
        expect(find.text(level.explanation), findsNothing);
        expect(find.text(level.instruction), findsOneWidget);
        await capture(tester, 'course-${(i + 1).toString().padLeft(2, '0')}');
        if (level.kind == PuzzleKind.numericAnswer) {
          final input = find.byKey(const ValueKey('numeric-answer')).first;
          await tester.ensureVisible(input);
          await tester.enterText(
            input,
            numericSolutions[level.id]!.toStringAsFixed(2).replaceAll('.', ','),
          );
        } else {
          enterSolution(controller, level);
          await tester.pumpAndSettle();
        }
        await pressCheck(tester);
        expect(controller.puzzle(level).isComplete, isTrue, reason: level.id);
        expect(
          find.text(learningExplanation(level, controller.puzzle(level))),
          findsOneWidget,
        );
        expect(controller.completedCount, i + 1);
        await pressCheck(tester);
        expect(tester.takeException(), isNull, reason: level.id);
      }
      expect(controller.tab, 1);
      controller.openLevel(0);
      await tester.pumpAndSettle();
      expect(find.text(levels.first.title), findsOneWidget);
      expect(controller.puzzle(levels.first).isComplete, isTrue);
      expect(controller.completedCount, 30);
    },
  );

  testWidgets('locked tasks cannot be opened by swiping or tapping the map', (
    tester,
  ) async {
    await launch(tester);
    final board = tester.getRect(
      find.byKey(const ValueKey('angle-board')).first,
    );
    await tester.dragFrom(
      Offset(board.left + 10, board.center.dy),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 0);
    controller.selectTab(1);
    await tester.pumpAndSettle();
    expect(find.text('Сначала: Поймай угол'), findsOneWidget);
    await tester.tap(find.text(levels[1].title));
    await tester.pumpAndSettle();
    expect(controller.tab, 1);
    expect(controller.currentIndex, 0);
    await capture(tester, 'course-map');
  });

  testWidgets('legacy completions keep global level numbers in a sparse feed', (
    tester,
  ) async {
    const done = LevelProgress(
      attempts: 1,
      completions: 1,
      independentCompletions: 1,
    );
    controller.progress = ProgressSnapshot(
      levels: {'triangle-right': done, 'pythagoras-3-4': done},
    );
    controller.openLevel(13);
    await launch(tester);
    expect(find.text('14 / 30'), findsOneWidget);
    final input = find.byKey(const ValueKey('numeric-answer')).first;
    await tester.ensureVisible(input);
    await tester.enterText(input, '5');
    await pressCheck(tester);
    await pressCheck(tester);
    expect(controller.currentIndex, 14);
    expect(find.text('Верни катет'), findsOneWidget);
    controller.openLevel(0);
    await tester.pumpAndSettle();
    expect(find.text('Поймай угол'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'hint button reveals successive hints without showing the explanation',
    (tester) async {
      await launch(tester);
      final level = levels.first;
      await tester.ensureVisible(find.text('Подсказка').first);
      await tester.tap(find.text('Подсказка').first);
      await tester.pumpAndSettle();
      expect(find.text(level.hints.first), findsOneWidget);
      expect(find.text(level.explanation), findsNothing);
      await tester.ensureVisible(find.text('Ещё подсказка').first);
      await tester.tap(find.text('Ещё подсказка').first);
      await tester.pumpAndSettle();
      expect(find.text(level.hints.take(2).join('\n')), findsOneWidget);
      await tester.ensureVisible(find.text('Ещё подсказка').first);
      await tester.tap(find.text('Ещё подсказка').first);
      await tester.pumpAndSettle();
      expect(find.text(level.hints.join('\n')), findsOneWidget);
      expect(find.text(level.explanation), findsNothing);
      enterSolution(controller, level);
      await tester.pumpAndSettle();
      await pressCheck(tester);
      expect(controller.assistedCount, 1);
      expect(find.text('Решено с подсказкой'), findsOneWidget);
    },
  );

  testWidgets(
    'every lesson keeps controls reachable on compact screens and large text',
    (tester) async {
      completeBefore(controller, levels.last.id);
      for (final (size, scale) in [
        (const Size(320, 568), 1.0),
        (const Size(360, 800), 1.8),
      ]) {
        await launch(tester, size: size, scale: scale);
        for (var i = 0; i < levels.length; i++) {
          controller.openLevel(i);
          await tester.pumpAndSettle();
          await pressCheck(tester);
          expect(
            tester.takeException(),
            isNull,
            reason: '${levels[i].id} $size $scale',
          );
        }
      }
    },
  );
}
