import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoswipe/app.dart';
import 'package:geoswipe/core/app_controller.dart';
import 'package:geoswipe/core/geometry/geometry.dart';
import 'package:geoswipe/data/level_catalog.dart';
import 'package:geoswipe/data/progress_repository.dart';
import 'package:geoswipe/widgets/geometry_viewport.dart';
import 'support/memory_store.dart';
import 'support/course_solutions.dart';

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
  int baseline = 0;
  final captureKey = GlobalKey();
  Future<void> launch(
    WidgetTester tester,
    String id, {
    Size size = const Size(390, 1000),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    controller = AppController(ProgressRepository(MemoryStore()));
    await controller.load();
    completeBefore(controller, id);
    baseline = controller.totalAttempts;
    controller.openLevel(levels.indexWhere((l) => l.id == id));
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

  Future<void> check(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('check-answer')).first;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    (captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary)
        .markNeedsPaint();
    await tester.pump();
    await tester.runAsync(() async {
      final image =
          await (captureKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/ui').create(recursive: true);
      await File(
        'build/ui/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  tearDown(() => controller.dispose());

  testWidgets('RotatePuzzle 60 degrees works through touch and retry', (
    tester,
  ) async {
    await launch(tester, 'trig-standard-angle');
    final level = levels.firstWhere((l) => l.id == 'trig-standard-angle');
    expect(find.text(level.explanation), findsNothing);
    await check(tester);
    expect(controller.puzzle(level).isComplete, isFalse);
    final board = find.byKey(const ValueKey('angle-board')).first;
    await tester.ensureVisible(board);
    await tester.pumpAndSettle();
    final rect = tester.getRect(board);
    final viewport = GeometryViewport(
      rect.size,
      controller.puzzle(level).scene.bounds,
    );
    await tester.dragFrom(
      rect.topLeft + viewport.toScreen(Geometry.polar(20, 5)),
      viewport.toScreen(Geometry.polar(60, 5)) -
          viewport.toScreen(Geometry.polar(20, 5)),
    );
    await tester.pumpAndSettle();
    await check(tester);
    expect(
      controller.puzzle(level).isComplete,
      isTrue,
      reason:
          'angle=${controller.puzzle(level).angle}, index=${controller.currentIndex}',
    );
    expect(controller.totalAttempts - baseline, 2);
    expect(find.text(level.explanation), findsOneWidget);
    await capture(tester, 'engine-rotate');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'DragPuzzle checks geometry and restores its initial scene on restart',
    (tester) async {
      await launch(tester, 'triangle-right');
      final level = levels.firstWhere((l) => l.id == 'triangle-right');
      expect(find.text(level.explanation), findsNothing);
      await capture(tester, 'engine-drag');
      await check(tester);
      expect(controller.puzzle(level).isComplete, isFalse);
      final board = find.byKey(const ValueKey('drag-board')).first;
      await tester.ensureVisible(board);
      await tester.pumpAndSettle();
      final rect = tester.getRect(board);
      final state = controller.puzzle(level);
      final viewport = GeometryViewport(rect.size, state.scene.bounds);
      final from = viewport.toScreen(state.scene.points['C']!);
      final to = viewport.toScreen(const GeoPoint(3, 3));
      await tester.dragFrom(rect.topLeft + from, to - from);
      await tester.pumpAndSettle();
      await check(tester);
      expect(controller.puzzle(level).isComplete, isTrue);
      expect(controller.completedCount, baseline + 1);
      await tester.ensureVisible(find.byTooltip('Начать заново').first);
      await tester.tap(find.byTooltip('Начать заново').first);
      await tester.pumpAndSettle();
      expect(controller.puzzle(level).isComplete, isFalse);
      expect(controller.puzzle(level).scene.points['C']!.x, 2);
      expect(controller.totalAttempts - baseline, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AnswerPuzzle hides solution, validates input, accepts comma and resets text',
    (tester) async {
      await launch(tester, 'pythagoras-3-4');
      final level = levels.firstWhere((l) => l.id == 'pythagoras-3-4');
      expect(find.text(level.explanation), findsNothing);
      final hidden = controller.puzzle(level).scene.segments.last;
      expect(hidden.showLength, isFalse);
      expect(hidden.label, '?');
      await capture(tester, 'engine-answer');
      await check(tester);
      expect(find.text('Введи конечное число, например 2,5.'), findsOneWidget);
      final input = find.byKey(const ValueKey('numeric-answer')).first;
      await tester.ensureVisible(input);
      await tester.enterText(input, '4');
      await check(tester);
      expect(controller.puzzle(level).isComplete, isFalse);
      expect(find.text(level.explanation), findsNothing);
      await tester.ensureVisible(input);
      await tester.enterText(input, '5,0');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(controller.puzzle(level).isComplete, isTrue);
      expect(controller.totalAttempts - baseline, 3);
      expect(find.text(level.explanation), findsOneWidget);
      await check(tester);
      expect(controller.currentIndex, levels.indexOf(level) + 1);
      controller.openLevel(levels.indexOf(level));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Начать заново').first);
      await tester.tap(find.byTooltip('Начать заново').first);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(input).controller!.text, isEmpty);
      expect(controller.totalAttempts - baseline, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'new mechanics keep controls reachable on compact, landscape and large text screens',
    (tester) async {
      for (final size in [
        const Size(320, 568),
        const Size(844, 390),
        const Size(360, 800),
      ]) {
        for (final id in ['triangle-right', 'pythagoras-3-4']) {
          await launch(tester, id, size: size);
          await check(tester);
          expect(controller.totalAttempts - baseline, 1);
          await tester.ensureVisible(find.byTooltip('Начать заново').first);
          await tester.tap(find.byTooltip('Начать заново').first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$id $size');
          await tester.pumpWidget(const SizedBox.shrink());
          controller.dispose();
        }
      }
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await launch(
        tester,
        'triangle-right',
        size: const Size(360, 800),
        scale: 1.8,
      );
      await check(tester);
      expect(tester.takeException(), isNull);
    },
  );
}
