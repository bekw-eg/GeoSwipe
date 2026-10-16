import 'package:flutter/material.dart';
import '../core/geometry/angle_math.dart';
import '../core/geometry/scene.dart';
import 'geometry_board.dart';

/// Compatibility wrapper for existing angle-only callers.
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
  Widget build(BuildContext context) => GeometryBoard(
    key: const ValueKey('angle-board'),
    scene: angleScene(angle),
    complete: complete,
    onChanged: (scene) {
      final vector = scene.points['B']! - scene.points['O']!;
      final value = angleFromVector(vector.x, vector.y);
      if (value != null) onChanged(value);
    },
  );
}
