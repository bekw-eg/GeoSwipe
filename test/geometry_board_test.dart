import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoswipe/core/geometry/geometry.dart';
import 'package:geoswipe/core/geometry/scene.dart';
import 'package:geoswipe/data/level_catalog.dart';
import 'package:geoswipe/widgets/geometry_board.dart';
import 'package:geoswipe/widgets/geometry_viewport.dart';

void main() {
  test(
    'viewport round trips coordinates and preserves distances on every aspect ratio',
    () {
      for (final size in [
        const Size(240, 160),
        const Size(720, 240),
        const Size(260, 600),
      ]) {
        final viewport = GeometryViewport(size, const GeoBounds(-1, -3, 7, 5));
        for (final point in [
          const GeoPoint(-1, -3),
          const GeoPoint(7, 5),
          const GeoPoint(2.4, 1.3),
        ]) {
          final back = viewport.toWorld(viewport.toScreen(point));
          expect(back.x, closeTo(point.x, 1e-9));
          expect(back.y, closeTo(point.y, 1e-9));
        }
        final o = viewport.toScreen(const GeoPoint(0, 0));
        expect(
          (viewport.toScreen(const GeoPoint(4, 0)) - o).distance,
          closeTo(4 * viewport.scale, 1e-9),
        );
        expect(
          (viewport.toScreen(const GeoPoint(0, 4)) - o).distance,
          closeTo(4 * viewport.scale, 1e-9),
        );
        expect(viewport.toScreen(const GeoPoint(0, 1)).dy, lessThan(o.dy));
      }
      expect(
        () => GeometryViewport(Size.zero, const GeoBounds(0, 0, 1, 1)),
        throwsArgumentError,
      );
    },
  );

  for (final size in [
    const Size(240, 160),
    const Size(720, 240),
    const Size(260, 600),
  ]) {
    testWidgets(
      'drag maps finger to mathematical point without jumping at $size',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var scene = levels
            .firstWhere((l) => l.id == 'triangle-right')
            .initialGeometry;
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox.fromSize(
                size: size,
                child: StatefulBuilder(
                  builder: (context, setState) => GeometryBoard(
                    scene: scene,
                    onChanged: (next) => setState(() => scene = next),
                  ),
                ),
              ),
            ),
          ),
        );
        final rect = tester.getRect(find.byType(GeometryBoard));
        final viewport = GeometryViewport(size, scene.bounds);
        const grab = Offset(5, -5);
        final start = rect.topLeft + viewport.toScreen(scene.points['C']!);
        final target = rect.topLeft + viewport.toScreen(const GeoPoint(0, 2));
        final gesture = await tester.startGesture(start + grab);
        await gesture.moveTo(target + grab);
        await tester.pump();
        await gesture.up();
        expect(scene.points['C']!.x, closeTo(0, 1e-8));
        expect(scene.points['C']!.y, closeTo(2, 1e-8));
        expect(
          Geometry.triangleAngles(scene.triangles.first.resolve(scene))!.first,
          closeTo(90, 1e-8),
        );
        expect(scene.points['A']!.x, 0);
        expect(scene.points['B']!.x, 6);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'all configured vertices can move and are clamped to world bounds',
    (tester) async {
      var scene = GeometryScene(
        bounds: const GeoBounds(-5, -5, 5, 5),
        points: const {
          'A': GeoPoint(-3, -3),
          'B': GeoPoint(3, -3),
          'C': GeoPoint(0, 3),
        },
        triangles: const [TriangleRef('A', 'B', 'C')],
        draggable: {'A', 'B', 'C'},
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: StatefulBuilder(
                builder: (context, setState) => GeometryBoard(
                  scene: scene,
                  onChanged: (next) => setState(() => scene = next),
                ),
              ),
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(GeometryBoard));
      final viewport = GeometryViewport(rect.size, scene.bounds);
      for (final id in ['A', 'B', 'C']) {
        final old = scene.points[id]!;
        final target = old + const GeoPoint(.8, .8);
        await tester.dragFrom(
          rect.topLeft + viewport.toScreen(old),
          viewport.toScreen(target) - viewport.toScreen(old),
        );
        await tester.pump();
        expect(scene.points[id]!.x, closeTo(target.x, 1e-8));
        expect(scene.points[id]!.y, closeTo(target.y, 1e-8));
      }
      final gesture = await tester.startGesture(
        rect.topLeft + viewport.toScreen(scene.points['C']!),
      );
      await gesture.moveBy(const Offset(1000, -1000));
      await tester.pump();
      await gesture.up();
      expect(scene.points['C']!.x, 5);
      expect(scene.points['C']!.y, 5);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'rotation handles seam, center dead zone, cancellation and completion lock',
    (tester) async {
      var scene = angleScene(15);
      var locked = false;
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 300,
              child: StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  return GeometryBoard(
                    scene: scene,
                    complete: locked,
                    onChanged: (next) => setState(() => scene = next),
                  );
                },
              ),
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(GeometryBoard));
      final viewport = GeometryViewport(rect.size, scene.bounds);
      final gesture = await tester.startGesture(
        rect.topLeft + viewport.toScreen(scene.points['B']!),
      );
      await gesture.moveTo(rect.center);
      await tester.pump();
      expect(
        Geometry.directedAngle(const GeoPoint(1, 0), scene.points['B']!),
        closeTo(15, 1e-9),
      );
      await gesture.moveTo(
        rect.topLeft + viewport.toScreen(Geometry.polar(359, 5)),
      );
      await tester.pump();
      expect(
        Geometry.directedAngle(const GeoPoint(1, 0), scene.points['B']!),
        closeTo(359, 1e-9),
      );
      final beforeSecondTouch = scene;
      final second = await tester.startGesture(
        rect.topLeft + viewport.toScreen(scene.points['B']!),
        pointer: 2,
      );
      await second.moveBy(const Offset(0, -50));
      await tester.pump();
      await second.up();
      expect(scene, same(beforeSecondTouch));
      await gesture.moveTo(
        rect.topLeft + viewport.toScreen(Geometry.polar(1, 5)),
      );
      await tester.pump();
      expect(
        Geometry.directedAngle(const GeoPoint(1, 0), scene.points['B']!),
        closeTo(1, 1e-9),
      );
      await gesture.cancel();
      rebuild(() => locked = true);
      await tester.pump();
      final before = scene;
      await tester.dragFrom(
        rect.topLeft + viewport.toScreen(scene.points['B']!),
        const Offset(0, -70),
      );
      await tester.pump();
      expect(scene, same(before));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dragging a shared ray origin cannot collapse its direction', (
    tester,
  ) async {
    var scene = GeometryScene(
      points: const {'O': GeoPoint(-2, 0), 'B': GeoPoint(2, 0)},
      rays: const [GeoRay('O', 'B')],
      draggable: {'O'},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: StatefulBuilder(
              builder: (context, setState) => GeometryBoard(
                scene: scene,
                onChanged: (next) => setState(() => scene = next),
              ),
            ),
          ),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(GeometryBoard));
    final viewport = GeometryViewport(rect.size, scene.bounds);
    final gesture = await tester.startGesture(
      rect.topLeft + viewport.toScreen(scene.points['O']!),
    );
    await gesture.moveTo(rect.topLeft + viewport.toScreen(scene.points['B']!));
    await tester.pump();
    expect(scene.points['O']!.x, -2);
    await gesture.moveTo(
      rect.topLeft + viewport.toScreen(const GeoPoint(-2, 1)),
    );
    await tester.pump();
    await gesture.up();
    expect(scene.points['O']!.y, closeTo(1, 1e-8));
    expect(tester.takeException(), isNull);
  });
}
