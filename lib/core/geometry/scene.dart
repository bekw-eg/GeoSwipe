import 'geometry.dart';

class GeoBounds {
  const GeoBounds(this.left, this.bottom, this.right, this.top);
  final double left;
  final double bottom;
  final double right;
  final double top;
  double get width => right - left;
  double get height => top - bottom;
  bool get isValid =>
      [left, bottom, right, top, width, height].every((v) => v.isFinite) &&
      width > 0 &&
      height > 0;
  GeoPoint clamp(GeoPoint p) =>
      GeoPoint(p.x.clamp(left, right), p.y.clamp(bottom, top));
}

class GeoSegment {
  const GeoSegment(this.start, this.end, {this.showLength = true, this.label});
  final String start;
  final String end;
  final bool showLength;
  final String? label;
}

class GeoRay {
  const GeoRay(this.origin, this.handle, {this.rotatable = true});
  final String origin;
  final String handle;
  final bool rotatable;
}

class TriangleRef {
  const TriangleRef(this.a, this.b, this.c);
  final String a;
  final String b;
  final String c;
  GeoTriangle resolve(GeometryScene scene) =>
      GeoTriangle(scene.points[a]!, scene.points[b]!, scene.points[c]!);
}

class AngleArc {
  const AngleArc(
    this.first,
    this.vertex,
    this.second, {
    this.directed = false,
    this.showDegrees = true,
  });
  final String first;
  final String vertex;
  final String second;
  final bool directed;
  final bool showDegrees;
}

/// Immutable scene. References share points, so connected objects move together.
class GeometryScene {
  GeometryScene({
    required Map<String, GeoPoint> points,
    this.bounds = const GeoBounds(-5, -5, 5, 5),
    List<GeoSegment> segments = const [],
    List<GeoRay> rays = const [],
    List<TriangleRef> triangles = const [],
    List<AngleArc> arcs = const [],
    Set<String> draggable = const {},
  }) : points = Map.unmodifiable(points),
       segments = List.unmodifiable(segments),
       rays = List.unmodifiable(rays),
       triangles = List.unmodifiable(triangles),
       arcs = List.unmodifiable(arcs),
       draggable = Set.unmodifiable(draggable) {
    final references = <String>[
      ...draggable,
      for (final s in segments) ...[s.start, s.end],
      for (final r in rays) ...[r.origin, r.handle],
      for (final t in triangles) ...[t.a, t.b, t.c],
      for (final a in arcs) ...[a.first, a.vertex, a.second],
    ];
    if (!bounds.isValid ||
        points.values.any((p) => !p.isFinite) ||
        references.any((id) => !points.containsKey(id))) {
      throw ArgumentError(
        'Scene needs finite points, valid bounds and references',
      );
    }
    if (rays.where((r) => r.rotatable).any((r) {
      final length = Geometry.distance(points[r.origin]!, points[r.handle]!);
      return length == null || length <= Geometry.lengthEpsilon;
    })) {
      throw ArgumentError('A rotating ray needs a finite nonzero direction');
    }
  }
  final Map<String, GeoPoint> points;
  final GeoBounds bounds;
  final List<GeoSegment> segments;
  final List<GeoRay> rays;
  final List<TriangleRef> triangles;
  final List<AngleArc> arcs;
  final Set<String> draggable;

  GeometryScene withPoint(String id, GeoPoint point) {
    if (!points.containsKey(id) || !point.isFinite) {
      throw ArgumentError('Unknown point or non-finite position');
    }
    return GeometryScene(
      points: {...points, id: point},
      bounds: bounds,
      segments: segments,
      rays: rays,
      triangles: triangles,
      arcs: arcs,
      draggable: draggable,
    );
  }

  GeometryScene rotateRay(GeoRay ray, double degrees) {
    if (!degrees.isFinite) throw ArgumentError.value(degrees);
    final origin = points[ray.origin]!;
    final length = Geometry.distance(origin, points[ray.handle]!)!;
    return withPoint(ray.handle, origin + Geometry.polar(degrees, length));
  }
}

GeometryScene angleScene(double degrees) => GeometryScene(
  points: {
    'O': const GeoPoint(0, 0),
    'A': const GeoPoint(5, 0),
    'B': Geometry.polar(degrees, 5),
  },
  rays: const [GeoRay('O', 'A', rotatable: false), GeoRay('O', 'B')],
  arcs: const [AngleArc('A', 'O', 'B', directed: true)],
);
