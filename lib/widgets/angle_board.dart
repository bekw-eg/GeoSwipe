import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../core/geometry/angle_math.dart';
import '../core/theme.dart';

class AngleBoard extends StatelessWidget {
  const AngleBoard({
    super.key,
    required this.angle,
    required this.onChanged,
    this.complete = false,
  });
  final double angle;
  final ValueChanged<double> onChanged;
  final bool complete;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final center = Offset(size.width / 2, size.height / 2);
      final radius = math.min(size.width, size.height) * .35;
      final radians = angle * math.pi / 180;
      final handle =
          center + Offset(math.cos(radians), -math.sin(radians)) * radius;
      void update(Offset position) {
        final vector = position - center;
        // A dead zone avoids unstable angles near the vertex.
        if (vector.distance < 16) return;
        final next = angleFromVector(vector.dx, -vector.dy);
        if (next != null) onChanged(next);
      }

      return Semantics(
        label:
            'Интерактивный угол. Перетаскивайте точку B или используйте ползунок ниже.',
        value: '${angle.toStringAsFixed(1)} градуса',
        child: RawGestureDetector(
          key: const ValueKey('angle-board'),
          gestures: complete
              ? {}
              : {
                  _RayPanRecognizer:
                      GestureRecognizerFactoryWithHandlers<_RayPanRecognizer>(
                        _RayPanRecognizer.new,
                        (recognizer) {
                          recognizer.canStart = (position) =>
                              (position - handle).distance <= 48;
                          recognizer.onStart = (details) =>
                              update(details.localPosition);
                          recognizer.onUpdate = (details) =>
                              update(details.localPosition);
                        },
                      ),
                },
          child: CustomPaint(
            painter: _AnglePainter(angle, complete),
            size: size,
          ),
        ),
      );
    },
  );
}

/// Lets PageView receive vertical swipes unless they start on the ray handle.
class _RayPanRecognizer extends PanGestureRecognizer {
  bool Function(Offset)? canStart;
  @override
  bool isPointerAllowed(PointerEvent event) =>
      (canStart?.call(event.localPosition) ?? false) &&
      super.isPointerAllowed(event);
}

class _AnglePainter extends CustomPainter {
  const _AnglePainter(this.angle, this.complete);
  final double angle;
  final bool complete;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .35;
    final radians = angle * math.pi / 180;
    final color = complete ? AppColors.mint : AppColors.violet;
    final grid = Paint()
      ..color = AppColors.line.withValues(alpha: .38)
      ..strokeWidth = .7;
    for (double x = center.dx % 28; x < size.width; x += 28) {
      for (double y = center.dy % 28; y < size.height; y += 28) {
        canvas.drawCircle(Offset(x, y), 1, grid);
      }
    }
    canvas.drawCircle(
      center,
      radius * 1.17,
      Paint()..color = color.withValues(alpha: .025),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    for (var i = 0; i < 72; i++) {
      final a = i * math.pi / 36;
      final direction = Offset(math.cos(a), -math.sin(a));
      canvas.drawLine(
        center + direction * (radius - (i % 18 == 0 ? 10 : 4)),
        center + direction * radius,
        grid..strokeWidth = 1,
      );
    }
    final arcRect = Rect.fromCircle(center: center, radius: radius * .47);
    canvas.drawArc(
      arcRect,
      0,
      -radians,
      true,
      Paint()..color = color.withValues(alpha: .12),
    );
    canvas.drawArc(
      arcRect,
      0,
      -radians,
      false,
      Paint()
        ..color = color.withValues(alpha: .75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final baseline = center + Offset(radius, 0);
    final endpoint =
        center + Offset(math.cos(radians), -math.sin(radians)) * radius;
    canvas.drawLine(
      center,
      baseline,
      Paint()
        ..color = AppColors.blue
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      center,
      endpoint,
      Paint()
        ..color = color.withValues(alpha: .1)
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      center,
      endpoint,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      endpoint,
      18,
      Paint()..color = color.withValues(alpha: .1),
    );
    canvas.drawCircle(endpoint, 9, Paint()..color = color);
    canvas.drawCircle(endpoint, 3, Paint()..color = AppColors.background);
    canvas.drawCircle(center, 5, Paint()..color = AppColors.text);
    canvas.drawCircle(baseline, 3, Paint()..color = AppColors.blue);
    _label(canvas, 'O', center + const Offset(-17, 10), AppColors.muted);
    _label(canvas, 'A', baseline + const Offset(10, 5), AppColors.blue);
    _label(
      canvas,
      'B',
      endpoint +
          Offset(math.cos(radians), -math.sin(radians)) * 25 +
          const Offset(-5, -7),
      color,
    );
    _label(
      canvas,
      '90°',
      center + Offset(-11, -radius - 23),
      AppColors.muted,
      small: true,
    );
    _label(
      canvas,
      '180°',
      center + Offset(-radius - 34, -6),
      AppColors.muted,
      small: true,
    );
    _label(
      canvas,
      '270°',
      center + Offset(-13, radius + 13),
      AppColors.muted,
      small: true,
    );
    if (angle > 20) {
      final labelPosition =
          center +
          Offset(math.cos(radians / 2), -math.sin(radians / 2)) * radius * .29;
      _label(canvas, 'α', labelPosition - const Offset(5, 8), color);
    }
  }

  void _label(
    Canvas canvas,
    String text,
    Offset offset,
    Color color, {
    bool small = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: small ? 10 : 13,
          color: color,
          fontWeight: small ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_AnglePainter oldDelegate) =>
      angle != oldDelegate.angle || complete != oldDelegate.complete;
}
