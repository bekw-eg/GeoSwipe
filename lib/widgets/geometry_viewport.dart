import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../core/geometry/geometry.dart';
import '../core/geometry/scene.dart';

/// A single isotropic transform for painting, hit testing and dragging.
/// Letterboxing preserves angles and lengths on any aspect ratio.
class GeometryViewport {
  GeometryViewport(this.size, this.bounds) {
    if (!bounds.isValid ||
        !size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      throw ArgumentError('Viewport needs finite positive dimensions');
    }
  }
  final Size size;
  final GeoBounds bounds;
  double get scale =>
      .7 * math.min(size.width / bounds.width, size.height / bounds.height);
  Offset toScreen(GeoPoint point) => Offset(
    size.width / 2 + (point.x - (bounds.left + bounds.width / 2)) * scale,
    size.height / 2 - (point.y - (bounds.bottom + bounds.height / 2)) * scale,
  );
  GeoPoint toWorld(Offset point) => GeoPoint(
    (point.dx - size.width / 2) / scale + bounds.left + bounds.width / 2,
    -(point.dy - size.height / 2) / scale + bounds.bottom + bounds.height / 2,
  );
}
