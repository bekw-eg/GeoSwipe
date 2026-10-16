import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../core/geometry/angle_math.dart';
import '../core/geometry/geometry.dart';
import '../core/geometry/scene.dart';
import '../core/theme.dart';
import 'geometry_viewport.dart';

class GeometryBoard extends StatefulWidget {
  const GeometryBoard({
    super.key,
    required this.scene,
    required this.onChanged,
    this.complete = false,
  });
  final GeometryScene scene;
  final ValueChanged<GeometryScene> onChanged;
  final bool complete;
  @override
  State<GeometryBoard> createState() => _GeometryBoardState();
}

class _GeometryBoardState extends State<GeometryBoard> {
  String? _selected;
  Offset _grabOffset = Offset.zero;

  List<String> get handles => [
    ...widget.scene.draggable,
    ...widget.scene.rays.where((r) => r.rotatable).map((r) => r.handle),
  ];

  bool _pick(Offset position, GeometryViewport viewport) {
    String? nearest;
    var distance = 32.0;
    for (final id in handles) {
      final next =
          (viewport.toScreen(widget.scene.points[id]!) - position).distance;
      if (next <= distance) {
        distance = next;
        nearest = id;
      }
    }
    _selected = nearest;
    if (nearest == null) return false;
    _grabOffset = position - viewport.toScreen(widget.scene.points[nearest]!);
    return true;
  }

  void _move(Offset position, GeometryViewport viewport) {
    final id = _selected;
    if (id == null || widget.complete) return;
    final scene = widget.scene;
    final target = position - _grabOffset;
    for (final ray in scene.rays.where((r) => r.rotatable && r.handle == id)) {
      final vector = target - viewport.toScreen(scene.points[ray.origin]!);
      // Screen-space dead zone prevents unstable rotation at the origin.
      if (vector.distance < 16) return;
      final angle = angleFromVector(vector.dx, -vector.dy);
      if (angle != null) widget.onChanged(scene.rotateRay(ray, angle));
      return;
    }
    final proposed = scene.bounds.clamp(viewport.toWorld(target));
    for (final ray in scene.rays.where((r) => r.rotatable)) {
      final length = Geometry.distance(
        ray.origin == id ? proposed : scene.points[ray.origin]!,
        ray.handle == id ? proposed : scene.points[ray.handle]!,
      );
      if (length == null || length <= Geometry.lengthEpsilon) return;
    }
    widget.onChanged(scene.withPoint(id, proposed));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      if (size.isEmpty) return const SizedBox.shrink();
      final viewport = GeometryViewport(size, widget.scene.bounds);
      return Semantics(
        label: handles.isEmpty
            ? 'Геометрическая схема задачи'
            : 'Геометрическое поле. Перетаскивай точки ${handles.join(', ')}.',
        child: RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: widget.complete
              ? {}
              : {
                  _HandlePanRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        _HandlePanRecognizer
                      >(_HandlePanRecognizer.new, (recognizer) {
                        recognizer.canStart = (p) => _pick(p, viewport);
                        recognizer.onStart = (d) =>
                            _move(d.localPosition, viewport);
                        recognizer.onUpdate = (d) =>
                            _move(d.localPosition, viewport);
                        recognizer.onEnd = (_) => _selected = null;
                        recognizer.onCancel = () => _selected = null;
                      }),
                },
          child: CustomPaint(
            size: size,
            painter: GeometryPainter(widget.scene, complete: widget.complete),
          ),
        ),
      );
    },
  );
}

/// Only handles join the gesture arena; other swipes reach the feed/scroll view.
class _HandlePanRecognizer extends PanGestureRecognizer {
  bool Function(Offset)? canStart;
  int? _activePointer;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _activePointer = event.pointer;
    super.addAllowedPointer(event);
    // A handle owns the gesture before the surrounding vertical scroll can win.
    resolve(GestureDisposition.accepted);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    super.didStopTrackingLastPointer(pointer);
    _activePointer = null;
  }

  @override
  bool isPointerAllowed(PointerEvent event) =>
      _activePointer == null &&
      (canStart?.call(event.localPosition) ?? false) &&
      super.isPointerAllowed(event);
}

class GeometryPainter extends CustomPainter {
  const GeometryPainter(this.scene, {this.complete = false});
  final GeometryScene scene;
  final bool complete;

  @override
  void paint(Canvas canvas, Size size) {
    final viewport = GeometryViewport(size, scene.bounds);
    final color = complete ? AppColors.mint : AppColors.violet;
    Offset point(String id) => viewport.toScreen(scene.points[id]!);
    final line = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final grid = Paint()..color = AppColors.line.withValues(alpha: .5);
    for (double x = 12; x < size.width; x += 28) {
      for (double y = 12; y < size.height; y += 28) {
        canvas.drawCircle(Offset(x, y), 1, grid);
      }
    }
    for (final t in scene.triangles) {
      final path = Path()
        ..moveTo(point(t.a).dx, point(t.a).dy)
        ..lineTo(point(t.b).dx, point(t.b).dy)
        ..lineTo(point(t.c).dx, point(t.c).dy)
        ..close();
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: .07));
      canvas.drawPath(path, line);
    }
    for (final segment in scene.segments) {
      final a = point(segment.start);
      final b = point(segment.end);
      canvas.drawLine(a, b, line);
      final length = Geometry.distance(
        scene.points[segment.start]!,
        scene.points[segment.end]!,
      );
      final label =
          segment.label ??
          (segment.showLength && length != null
              ? length.toStringAsFixed(2)
              : null);
      if (label != null) {
        final direction = b - a;
        final normal = direction.distance < 1
            ? const Offset(0, -1)
            : Offset(direction.dy, -direction.dx) / direction.distance;
        _text(canvas, size, label, (a + b) / 2 + normal * 15, AppColors.blue);
      }
    }
    for (final ray in scene.rays) {
      final a = point(ray.origin);
      final b = point(ray.handle);
      final direction = b - a;
      if (direction.distance < 1) continue;
      final unit = direction / direction.distance;
      final normal = Offset(-unit.dy, unit.dx);
      canvas.drawLine(
        a,
        b,
        line..color = ray.rotatable ? color : AppColors.blue,
      );
      canvas.drawLine(b, b - unit * 9 + normal * 4, line);
      canvas.drawLine(b, b - unit * 9 - normal * 4, line);
    }
    for (final arc in scene.arcs) {
      final o = scene.points[arc.vertex]!;
      final first = scene.points[arc.first]! - o;
      final second = scene.points[arc.second]! - o;
      final degrees = arc.directed
          ? Geometry.directedAngle(first, second)
          : Geometry.angleBetween(first, second);
      if (degrees == null) continue;
      final length = math.min(
        Geometry.magnitude(first)!,
        Geometry.magnitude(second)!,
      );
      final radius = math.min(36.0, length * viewport.scale * .32);
      final start = -math.atan2(first.y, first.x);
      var sweep = -degrees * math.pi / 180;
      if (!arc.directed && first.x * second.y - first.y * second.x < 0) {
        sweep = -sweep;
      }
      final center = point(arc.vertex);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        line
          ..color = color
          ..strokeWidth = 1.5,
      );
      if (arc.showDegrees) {
        final middle = start + sweep / 2;
        _text(
          canvas,
          size,
          '${degrees.toStringAsFixed(1)}°',
          center + Offset(math.cos(middle), math.sin(middle)) * (radius + 12),
          color,
        );
      }
    }
    final handles = {
      ...scene.draggable,
      ...scene.rays.where((r) => r.rotatable).map((r) => r.handle),
    };
    for (final entry in scene.points.entries) {
      final p = point(entry.key);
      final movable = handles.contains(entry.key);
      if (movable) {
        canvas.drawCircle(p, 18, Paint()..color = color.withValues(alpha: .12));
      }
      canvas.drawCircle(
        p,
        movable ? 8 : 4,
        Paint()..color = movable ? color : AppColors.text,
      );
      _text(canvas, size, entry.key, p + const Offset(16, 16), AppColors.text);
    }
    canvas.restore();
  }

  void _text(
    Canvas canvas,
    Size size,
    String text,
    Offset center,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    final position = Offset(
      (center.dx - painter.width / 2).clamp(
        0,
        math.max(0, size.width - painter.width),
      ),
      (center.dy - painter.height / 2).clamp(
        0,
        math.max(0, size.height - painter.height),
      ),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (position & painter.size).inflate(2),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.surface,
    );
    painter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(GeometryPainter oldDelegate) =>
      scene != oldDelegate.scene || complete != oldDelegate.complete;
}
