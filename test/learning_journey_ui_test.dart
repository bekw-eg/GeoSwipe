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
import 'package:geoswipe/models/learning_progress.dart';
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

  testWidgets(
    'new user → hints → save → restart → solve → restart → scheduled variant → statistics',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MemoryStore();
      var time = DateTime.utc(2026, 10, 16, 10);
      var app = AppController(ProgressRepository(store), clock: () => time);
      final key = GlobalKey();
      await app.load();
      Future<void> launch() async {
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: GeoSwipeApp(controller: app),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> tapText(String label) async {
        final finder = find.text(label).first;
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> check() async {
        final button = find.byKey(const ValueKey('check-answer')).first;
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      Future<void> restartApp() async {
        await app.persist();
        await tester.pumpWidget(const SizedBox.shrink());
        app.dispose();
        app = AppController(ProgressRepository(store), clock: () => time);
        await app.load();
        await launch();
      }

      Future<void> capture(String name) async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        boundary.markNeedsPaint();
        await tester.pump();
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/ui').create(recursive: true);
          await File(
            'build/ui/$name.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      await launch();
      expect(app.completedCount, 0);
      await tapText('Подсказка');
      await restartApp();
      expect(app.puzzle(levels.first).hintCount, 1);
      expect(find.text(levels.first.hints.first), findsOneWidget);
      await tapText('Ещё подсказка');
      await tapText('Ещё подсказка');
      expect(find.text(levels.first.explanation), findsNothing);
      expect(app.puzzle(levels.first).hintCount, 3);
      await capture('learning-hints');
      tester.widget<Slider>(find.byType(Slider).first).onChanged!(45);
      await tester.pumpAndSettle();
      await check();
      expect(app.skill(levels.first).state, SkillState.assisted);
      expect(find.text(levels.first.explanation), findsOneWidget);
      await restartApp();
      expect(app.completedCount, 1);
      expect(app.independentCount, 0);
      time = time.add(const Duration(days: 1));
      app.selectTab(2);
      await tester.pumpAndSettle();
      expect(find.textContaining('Пора повторить'), findsOneWidget);
      await tapText('Начать повторение');
      expect(app.reviewLevel!.targetAngle, 50);
      expect(app.reviewLevel!.variant, 1);
      await capture('learning-review');
      tester.widget<Slider>(find.byType(Slider).last).onChanged!(50);
      await tester.pumpAndSettle();
      await check();
      expect(app.skill(levels.first).state, SkillState.independent);
      expect(app.masteredCount, 0);
      expect(app.progress.history.map((a) => a.hintCount), [3, 0]);
      await restartApp();
      app.selectTab(3);
      await tester.pumpAndSettle();
      expect(find.text('Заданий без подсказок'), findsOneWidget);
      expect(find.text('Навыков освоено'), findsOneWidget);
      expect(find.text('Ошибки по темам'), findsOneWidget);
      expect(app.completedCount, 1);
      expect(app.independentCount, 1);
      expect(app.totalAttempts, 2);
      expect(app.dueLevels, isEmpty);
      await capture('learning-statistics');
      expect(tester.takeException(), isNull);
      await app.persist();
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
    },
  );
}
