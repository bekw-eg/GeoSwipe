import 'dart:math' as math;
import '../core/geometry/geometry.dart';
import '../core/geometry/scene.dart';

const abc = TriangleRef('A', 'B', 'C');

GeometryScene triangleScene({
  GeoPoint a = const GeoPoint(0, 0),
  GeoPoint b = const GeoPoint(6, 0),
  GeoPoint c = const GeoPoint(2, 4),
  Set<String> draggable = const {},
  bool measured = false,
  Map<String, String> labels = const {},
  List<AngleArc> arcs = const [],
  GeoBounds? bounds,
}) {
  final points = {'A': a, 'B': b, 'C': c};
  final xs = points.values.map((p) => p.x);
  final ys = points.values.map((p) => p.y);
  return GeometryScene(
    points: points,
    bounds:
        bounds ??
        GeoBounds(
          xs.reduce(math.min) - 2,
          ys.reduce(math.min) - 2,
          xs.reduce(math.max) + 2,
          ys.reduce(math.max) + 2,
        ),
    triangles: const [abc],
    segments: [
      GeoSegment('A', 'B', showLength: measured, label: labels['AB']),
      GeoSegment('C', 'A', showLength: measured, label: labels['AC']),
      GeoSegment('B', 'C', showLength: measured, label: labels['BC']),
    ],
    arcs: arcs,
    draggable: draggable,
  );
}

GeometryScene triangleWithAngles(
  double a,
  double b, {
  bool equalSides = false,
  bool exterior = false,
  bool exteriorAtB = false,
  bool showBaseAngles = true,
}) {
  final ar = a * math.pi / 180;
  final br = b * math.pi / 180;
  final ac = 6 * math.sin(br) / math.sin(ar + br);
  final scene = triangleScene(
    c: Geometry.polar(a, ac),
    labels: equalSides ? const {'AC': 'AC = BC', 'BC': 'AC = BC'} : const {},
    arcs: [
      AngleArc(
        'B',
        'A',
        'C',
        showDegrees: false,
        label: showBaseAngles ? '$a°' : null,
      ),
      AngleArc(
        'A',
        'B',
        'C',
        showDegrees: false,
        label: showBaseAngles ? '$b°' : null,
      ),
      const AngleArc('A', 'C', 'B', showDegrees: false, label: '?'),
    ],
  );
  if (!exterior && !exteriorAtB) return scene;
  final c = scene.points['C']!;
  return GeometryScene(
    points: {
      ...scene.points,
      'D': exteriorAtB
          ? const GeoPoint(8, 0)
          : c + (c - scene.points['B']!) * .5,
    },
    bounds: GeoBounds(-2, -2, 10, math.max(c.y * 1.5 + 2, 5)),
    triangles: scene.triangles,
    segments: [
      ...scene.segments,
      GeoSegment(exteriorAtB ? 'B' : 'C', 'D', showLength: false),
    ],
    arcs: [
      ...scene.arcs,
      exteriorAtB
          ? AngleArc('D', 'B', 'C', showDegrees: false, label: '${180 - b}°')
          : const AngleArc('D', 'C', 'A', showDegrees: false, label: '?'),
    ],
  );
}

GeometryScene rightScene(
  double adjacent,
  double opposite, {
  Map<String, String> labels = const {},
  List<AngleArc> extraArcs = const [],
}) => triangleScene(
  b: GeoPoint(adjacent, 0),
  c: GeoPoint(0, opposite),
  labels: labels,
  arcs: [
    const AngleArc('B', 'A', 'C', showDegrees: false, label: '90°'),
    ...extraArcs,
  ],
);

GeometryScene complementaryScene() => GeometryScene(
  points: {
    'O': const GeoPoint(0, 0),
    'A': const GeoPoint(5, 0),
    'B': Geometry.polar(35, 5),
    'C': const GeoPoint(0, 5),
  },
  bounds: const GeoBounds(-1, -1, 6, 6),
  rays: const [
    GeoRay('O', 'A', rotatable: false),
    GeoRay('O', 'B', rotatable: false),
    GeoRay('O', 'C', rotatable: false),
  ],
  arcs: const [
    AngleArc('A', 'O', 'B', showDegrees: false, label: '35°'),
    AngleArc('B', 'O', 'C', showDegrees: false, label: '?'),
  ],
);

GeometryScene supplementaryScene() => GeometryScene(
  points: {
    'O': const GeoPoint(0, 0),
    'A': const GeoPoint(5, 0),
    'B': Geometry.polar(125, 5),
    'C': const GeoPoint(-5, 0),
  },
  bounds: const GeoBounds(-6, -1, 6, 6),
  rays: const [
    GeoRay('O', 'A', rotatable: false),
    GeoRay('O', 'B', rotatable: false),
    GeoRay('O', 'C', rotatable: false),
  ],
  arcs: const [
    AngleArc('A', 'O', 'B', showDegrees: false, label: '125°'),
    AngleArc('B', 'O', 'C', showDegrees: false, label: '?'),
  ],
);

GeometryScene pythagoreanSquares() {
  final scene = rightScene(3, 4);
  final points = {...scene.points};
  final segments = [...scene.segments];
  final annotations = <GeoAnnotation>[];
  for (final (start, end, area, first, second) in [
    ('B', 'A', '9', 'E', 'F'),
    ('A', 'C', '16', 'G', 'H'),
    ('C', 'B', '?', 'I', 'J'),
  ]) {
    final a = points[start]!;
    final b = points[end]!;
    final d = b - a;
    final offset = GeoPoint(-d.y, d.x);
    points[first] = a + offset;
    points[second] = b + offset;
    segments.addAll([
      GeoSegment(start, first, showLength: false),
      GeoSegment(first, second, showLength: false),
      GeoSegment(second, end, showLength: false),
    ]);
    annotations.add(GeoAnnotation((a + b + offset) * .5, 'S = $area'));
  }
  return GeometryScene(
    points: points,
    bounds: const GeoBounds(-5, -4, 8, 8),
    triangles: scene.triangles,
    segments: segments,
    arcs: scene.arcs,
    annotations: annotations,
  );
}

GeometryScene rectangleScene() => GeometryScene(
  points: const {
    'A': GeoPoint(0, 0),
    'B': GeoPoint(7, 0),
    'C': GeoPoint(7, 5),
    'D': GeoPoint(0, 5),
  },
  bounds: const GeoBounds(-2, -2, 9, 7),
  segments: const [
    GeoSegment('A', 'B', label: '7'),
    GeoSegment('B', 'C', label: '5'),
    GeoSegment('C', 'D', showLength: false),
    GeoSegment('D', 'A', showLength: false),
    GeoSegment('A', 'C', showLength: false, label: '?'),
  ],
  arcs: const [AngleArc('A', 'B', 'C', showDegrees: false, label: '90°')],
);

GeometryScene isoscelesHeight() => GeometryScene(
  points: const {
    'A': GeoPoint(-5, 0),
    'B': GeoPoint(5, 0),
    'C': GeoPoint(0, 12),
    'H': GeoPoint(0, 0),
  },
  bounds: const GeoBounds(-7, -2, 7, 14),
  triangles: const [abc],
  segments: const [
    GeoSegment('A', 'B', label: '10'),
    GeoSegment('A', 'C', label: '13'),
    GeoSegment('B', 'C', label: '13'),
    GeoSegment('C', 'H', showLength: false, label: '?'),
  ],
  arcs: const [AngleArc('B', 'H', 'C', showDegrees: false, label: '90°')],
);

GeometryScene finalFlight() {
  final x = 13 * math.sqrt(3);
  return GeometryScene(
    points: {
      'A': const GeoPoint(0, 0),
      'B': GeoPoint(x, 0),
      'C': GeoPoint(x, 18),
      'D': GeoPoint(x, 13),
    },
    bounds: GeoBounds(-3, -3, x + 4, 22),
    triangles: const [abc, TriangleRef('A', 'B', 'D')],
    segments: const [
      GeoSegment('A', 'B', showLength: false),
      GeoSegment('B', 'C', showLength: false),
      GeoSegment('A', 'D', label: '26 м'),
      GeoSegment('D', 'C', label: '5 м'),
      GeoSegment('A', 'C', showLength: false, label: '?'),
    ],
    arcs: const [
      AngleArc('B', 'A', 'D', showDegrees: false, label: '30°'),
      AngleArc('A', 'B', 'C', showDegrees: false, label: '90°'),
    ],
  );
}
