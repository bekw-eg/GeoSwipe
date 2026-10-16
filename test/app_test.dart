import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoswipe/app.dart';
import 'package:geoswipe/core/app_controller.dart';
import 'package:geoswipe/data/level_catalog.dart';
import 'package:geoswipe/data/progress_repository.dart';
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
    Size size = const Size(390, 844),
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

  Future<void> tab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final repaint =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    repaint.markNeedsPaint();
    await tester.pump();
    await tester.runAsync(() async {
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/ui').create(recursive: true);
      await File(
        'build/ui/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('all four screens work with honest initial states', (
    tester,
  ) async {
    await launch(tester);
    expect(find.text('Поймай угол'), findsOneWidget);
    expect(find.text(levels.first.explanation), findsNothing);
    await capture(tester, '01-play');
    await tab(tester, 'Карта обучения');
    expect(find.text('Первые открытия'), findsOneWidget);
    await capture(tester, '02-learning');
    await tab(tester, 'Повторение');
    expect(find.text('Здесь появятся твои задачи'), findsOneWidget);
    await capture(tester, '03-review');
    await tab(tester, 'Профиль');
    expect(find.text('Всего проверок'), findsOneWidget);
    await capture(tester, '04-profile');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'dragging the actual ray checks a real answer and enables review',
    (tester) async {
      await launch(tester);
      final rect = tester.getRect(
        find.byKey(const ValueKey('angle-board')).first,
      );
      final radius = math.min(rect.width, rect.height) * .35;
      final start =
          rect.center +
          Offset(math.cos(math.pi / 12), -math.sin(math.pi / 12)) * radius;
      final end =
          rect.center +
          Offset(math.cos(math.pi / 4), -math.sin(math.pi / 4)) * radius;
      final gesture = await tester.startGesture(start);
      await gesture.moveTo(end, timeStamp: const Duration(milliseconds: 100));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.puzzle(levels.first).angle, closeTo(45, .1));
      await tester.tap(find.byKey(const ValueKey('check-answer')).first);
      await tester.pumpAndSettle();
      expect(controller.completedCount, 1);
      expect(find.text(levels.first.explanation), findsOneWidget);
      await capture(tester, '05-completed');
      await tab(tester, 'Повторение');
      await tester.tap(find.text('Начать повторение'));
      await tester.pumpAndSettle();
      expect(controller.reviewLevel, levels.first);
      expect(controller.puzzle(levels.first, review: true).isComplete, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('swipe outside the handle changes levels instead of rotating', (
    tester,
  ) async {
    await launch(tester);
    final rect = tester.getRect(
      find.byKey(const ValueKey('angle-board')).first,
    );
    await tester.dragFrom(
      Offset(rect.left + 20, rect.center.dy),
      const Offset(0, -480),
    );
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 1);
    expect(find.text('Прямой поворот'), findsOneWidget);
    expect(
      controller.puzzle(levels.first).angle,
      closeTo(levels.first.initialAngle, 1e-9),
    );
  });
  testWidgets(
    'map opens the selected level and bottom navigation preserves state',
    (tester) async {
      await launch(tester);
      await tab(tester, 'Карта обучения');
      await tester.tap(find.text('Шире прямого'));
      await tester.pumpAndSettle();
      expect(controller.currentIndex, 2);
      expect(find.text('135°'), findsOneWidget);
      await tab(tester, 'Профиль');
      await tab(tester, 'Играть');
      expect(find.text('135°'), findsOneWidget);
    },
  );
  testWidgets('wrong answer, hint and restart provide meaningful feedback', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.text('Подсказка').first);
    await tester.pumpAndSettle();
    expect(find.text(levels.first.hint), findsOneWidget);
    expect(find.text(levels.first.explanation), findsNothing);
    await tester.ensureVisible(
      find.byKey(const ValueKey('check-answer')).first,
    );
    await tester.tap(find.byKey(const ValueKey('check-answer')).first);
    await tester.pumpAndSettle();
    expect(find.text('Ещё немного'), findsOneWidget);
    expect(controller.totalAttempts, 1);
    await tester.ensureVisible(find.byTooltip('Начать заново').first);
    await tester.tap(find.byTooltip('Начать заново').first);
    await tester.pumpAndSettle();
    expect(controller.puzzle(levels.first).hintUsed, isFalse);
    expect(controller.totalAttempts, 1);
  });
  testWidgets('slider responds to touch independently of the diagram', (
    tester,
  ) async {
    await launch(tester);
    final slider = find.byKey(const ValueKey('angle-slider')).first;
    final rect = tester.getRect(slider);
    await tester.tapAt(Offset(rect.center.dx, rect.center.dy));
    await tester.pumpAndSettle();
    expect(controller.puzzle(levels.first).angle, closeTo(180, 3));
    expect(tester.takeException(), isNull);
  });
  testWidgets('compact phone and landscape keep controls reachable', (
    tester,
  ) async {
    for (final size in [const Size(320, 568), const Size(844, 390)]) {
      await launch(tester, size: size);
      await tester.ensureVisible(
        find.byKey(const ValueKey('check-answer')).first,
      );
      await tester.tap(find.byKey(const ValueKey('check-answer')).first);
      await tester.pumpAndSettle();
      expect(find.text('Ещё немного'), findsOneWidget);
      for (final label in [
        'Карта обучения',
        'Повторение',
        'Профиль',
        'Играть',
      ]) {
        await tab(tester, label);
        expect(tester.takeException(), isNull, reason: '$size $label');
      }
    }
  });
  testWidgets('large accessibility text has no layout errors on every screen', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await launch(tester, size: const Size(360, 800), scale: 1.8);
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.text('Поймай угол')),
      ).scale(10),
      18,
    );
    for (final label in ['Карта обучения', 'Повторение', 'Профиль', 'Играть']) {
      await tab(tester, label);
      expect(tester.takeException(), isNull, reason: label);
    }
  });
}
