import 'dart:math' as math;
import '../core/geometry/constraints.dart';
import '../core/geometry/geometry.dart';
import '../core/geometry/lesson_constraints.dart';
import '../core/geometry/scene.dart';
import '../models/level.dart';
import 'lesson_scenes.dart';

String mathNumber(num value) => value
    .toStringAsFixed(2)
    .replaceFirst(RegExp(r'\.?0+$'), '')
    .replaceAll('.', ',');

/// Reproducible variants: sequence is persisted, never taken from wall-clock time.
Level reviewVariant(Level base, int sequence) {
  final n = sequence + 1;
  final a = 7.0 + n; // Different from course and worked-example parameters.
  final b = 11.0 + n;
  final c = math.sqrt(a * a + b * b);
  final k = 3.0 + n;
  Level numeric(
    String question,
    double answer,
    String explanation,
    GeometryScene scene, {
    double tolerance = 0,
    String? label,
  }) => Level(
    id: base.id,
    topicId: base.topicId,
    title: base.title,
    variant: n,
    kind: PuzzleKind.numericAnswer,
    instruction: question,
    goalLabel: label ?? base.goalLabel,
    answerLabel: base.answerLabel,
    initialScene: scene,
    constraint: NumericAnswerConstraint(answer, absoluteTolerance: tolerance),
    hint: base.hint,
    guidedHints: base.hints,
    explanation: explanation,
  );
  GeometryScene right(double x, double y, Map<String, String> labels) =>
      rightScene(
        x,
        y,
        labels: labels,
        extraArcs: const [
          AngleArc('A', 'B', 'C', showDegrees: false, label: 'α'),
        ],
      );
  final angle = 22.0 + n % 23;
  switch (base.id) {
    case 'angle-complement':
      return numeric(
        'OA ⟂ OC, OB внутри угла AOC. AOB = $angle°. Найди BOC.',
        90 - angle,
        'BOC = 90° − AOB = 90° − $angle° = ${90 - angle}°.',
        _splitAngle(angle, 90),
      );
    case 'angle-supplement':
      final x = angle + 80;
      return numeric(
        'OA и OC — противоположные лучи. AOB = $x°. Найди BOC.',
        180 - x,
        'BOC = 180° − AOB = 180° − $x° = ${180 - x}°.',
        _splitAngle(x, 180),
      );
    case 'triangle-angle-sum':
      final y = 65.0 + n % 10;
      return numeric(
        'В ABC: A = $angle°, B = $y°. Найди C.',
        180 - angle - y,
        'C = 180° − A − B = 180° − $angle° − $y° = ${180 - angle - y}°.',
        triangleWithAngles(angle, y),
      );
    case 'triangle-base-angle':
      final top = 42.0 + 2 * (n % 18);
      final bottom = (180 - top) / 2;
      return numeric(
        'AC = BC; угол C = $top°. Найди угол A.',
        bottom,
        'A = B = (180° − C) / 2 = (180° − $top°) / 2 = $bottom°.',
        triangleScene(
          c: Geometry.polar(bottom, 3 / math.cos(bottom * math.pi / 180)),
          labels: const {'AC': 'AC = BC', 'BC': 'AC = BC'},
          arcs: [AngleArc('A', 'C', 'B', showDegrees: false, label: '$top°')],
        ),
      );
    case 'triangle-exterior':
      final y = 65.0 + n % 10;
      return numeric(
        'В ABC: A = $angle°, B = $y°. BC продолжена за C до D. Найди DCA.',
        angle + y,
        'DCA = A + B = $angle° + $y° = ${angle + y}°.',
        triangleWithAngles(angle, y, exterior: true),
      );
    case 'triangle-combined':
      final outer = 115.0 + n % 14;
      final inner = 180 - outer;
      return numeric(
        'AC = BC. AB продолжена за B до D; CBD = $outer°. Найди C.',
        180 - 2 * inner,
        'A = B = 180° − $outer° = $inner°. C = 180° − 2 × $inner° = ${180 - 2 * inner}°.',
        triangleWithAngles(
          inner,
          inner,
          equalSides: true,
          exteriorAtB: true,
          showBaseAngles: false,
        ),
      );
    case 'pythagoras-legs':
      return numeric(
        'В ABC: A = 90°, AB = $a, AC = $b, BC = ${mathNumber(c)} (округлено). Найди сумму катетов.',
        a + b,
        'Катеты AB и AC образуют прямой угол. AB + AC = $a + $b = ${a + b}.',
        right(a, b, {'AB': '$a', 'AC': '$b', 'BC': mathNumber(c)}),
      );
    case 'pythagoras-squares':
      return numeric(
        'Площади квадратов на катетах прямоугольного ABC равны ${a * a} и ${b * b}. Найди площадь квадрата на гипотенузе.',
        a * a + b * b,
        'c² = a² + b² = ${a * a} + ${b * b} = ${a * a + b * b}.',
        right(a, b, {
          'AB': 'a² = ${a * a}',
          'AC': 'b² = ${b * b}',
          'BC': 'c² = ?',
        }),
      );
    case 'pythagoras-3-4':
      return numeric(
        'A = 90°, катеты AB = ${5 * k}, AC = ${12 * k}. Найди BC.',
        13 * k,
        'BC = √(AB² + AC²) = √(${5 * k}² + ${12 * k}²) = ${13 * k}.',
        right(5 * k, 12 * k, {'AB': '${5 * k}', 'AC': '${12 * k}', 'BC': '?'}),
      );
    case 'pythagoras-missing-leg':
    case 'pythagoras-ladder':
      final ladder = base.id == 'pythagoras-ladder';
      return numeric(
        ladder
            ? 'Лестница BC = ${17 * k} м, основание в ${8 * k} м от стены AC. Стена перпендикулярна земле. Найди высоту AC.'
            : 'A = 90°, гипотенуза BC = ${17 * k}, катет AB = ${8 * k}. Найди AC.',
        15 * k,
        'AC = √(BC² − AB²) = √(${17 * k}² − ${8 * k}²) = ${15 * k}.',
        right(8 * k, 15 * k, {'AB': '${8 * k}', 'AC': '?', 'BC': '${17 * k}'}),
      );
    case 'pythagoras-diagonal':
      return numeric(
        'У прямоугольника стороны $a и $b. Найди диагональ до 0,01.',
        c,
        'd = √(a² + b²) = √($a² + $b²) ≈ ${mathNumber(c)}.',
        GeometryScene(
          points: {
            'A': const GeoPoint(0, 0),
            'B': GeoPoint(a, 0),
            'C': GeoPoint(a, b),
            'D': GeoPoint(0, b),
          },
          bounds: GeoBounds(-2, -2, a + 2, b + 2),
          segments: [
            GeoSegment('A', 'B', showLength: false, label: '$a'),
            GeoSegment('B', 'C', showLength: false, label: '$b'),
            const GeoSegment('C', 'D', showLength: false),
            const GeoSegment('D', 'A', showLength: false),
            const GeoSegment('A', 'C', showLength: false, label: '?'),
          ],
        ),
        tolerance: .005,
      );
    case 'pythagoras-distance':
      final x = 2.0 + n;
      return numeric(
        'Точки A = (−$x; −2), C = (${3 * k - x}; ${4 * k - 2}). Найди расстояние AC.',
        5 * k,
        'Δx = ${3 * k - x} − (−$x) = ${3 * k}; Δy = ${4 * k - 2} − (−2) = ${4 * k}. AC = √(${3 * k}² + ${4 * k}²) = ${5 * k}.',
        triangleScene(
          a: GeoPoint(-x, -2),
          b: GeoPoint(3 * k - x, -2),
          c: GeoPoint(3 * k - x, 4 * k - 2),
        ),
      );
    case 'pythagoras-combined':
      return numeric(
        'Равнобедренная крыша ABC: AC = BC = ${17 * k}, AB = ${16 * k}. Найди высоту CH к основанию.',
        15 * k,
        'AH = AB / 2 = ${8 * k}. CH = √(AC² − AH²) = √(${17 * k}² − ${8 * k}²) = ${15 * k}.',
        triangleScene(
          b: GeoPoint(16 * k, 0),
          c: GeoPoint(8 * k, 15 * k),
          labels: {'AB': '${16 * k}', 'AC': '${17 * k}', 'BC': '${17 * k}'},
        ),
      );
    case 'trig-sine':
    case 'trig-cosine':
    case 'trig-tangent':
      final (symbol, numerator, denominator) = switch (base.id) {
        'trig-sine' => ('sin', b, c),
        'trig-cosine' => ('cos', a, c),
        _ => ('tg', b, a),
      };
      // Exact hypotenuse is stated symbolically; its rounded label is never input data.
      final hyp = '√${a * a + b * b}';
      return numeric(
        'A = 90°, α при B. AB = $a, AC = $b, BC = $hyp. Найди $symbol α до 0,01.',
        numerator / denominator,
        '$symbol α = ${base.id == 'trig-cosine' ? 'AB' : 'AC'} / ${base.id == 'trig-tangent' ? 'AB' : 'BC'} = $numerator / ${base.id == 'trig-tangent' ? '$a' : hyp} ≈ ${mathNumber(numerator / denominator)}.',
        right(a, b, {'AB': '$a', 'AC': '$b', 'BC': hyp}),
        tolerance: .005,
      );
    case 'trig-length':
      final hyp = 18.0 + 2 * n;
      return numeric(
        'A = 90°, B = 30°, BC = $hyp. sin 30° = 1/2. Найди AC.',
        hyp / 2,
        'AC = BC × sin B = $hyp × 1/2 = ${hyp / 2}.',
        right(hyp * math.sqrt(3) / 2, hyp / 2, {'BC': '$hyp', 'AC': '?'}),
      );
    case 'trig-function':
      return numeric(
        'Башня AC перпендикулярна земле AB. AB = $a м, угол B = 45°, tg 45° = 1. Найди AC.',
        a,
        'AC = AB × tg B = $a × 1 = $a м.',
        right(a, a, {'AB': '$a м', 'AC': '?'}),
      );
    case 'trig-application':
      return numeric(
        'Столб AC перпендикулярен тени AB длиной $a м. Угол B = 60°, tg 60° = √3. Найди AC до 0,01 м.',
        a * math.sqrt(3),
        'AC = AB × tg B = $a × √3 ≈ ${mathNumber(a * math.sqrt(3))} м.',
        right(a, a * math.sqrt(3), {'AB': '$a м', 'AC': '?'}),
        tolerance: .005,
      );
    case 'trig-final':
      final r = 30.0 + 2 * n;
      final rise = 6.0 + n;
      final height = r / 2 + rise;
      final x = r * math.sqrt(3) / 2;
      final distance = math.sqrt(x * x + height * height);
      return numeric(
        'Дрон D в $r м от A под углом 30° к горизонтали AB. Он поднимается вертикально на $rise м до C. B — проекция D и C. Найди AC до 0,01 м. sin 30° = 1/2, cos 30° = √3/2.',
        distance,
        'AB = $r × √3/2; BD = $r / 2 = ${r / 2}. BC = ${r / 2} + $rise = $height. AC = √(($r × √3/2)² + $height²) ≈ ${mathNumber(distance)} м.',
        GeometryScene(
          points: {
            'A': const GeoPoint(0, 0),
            'B': GeoPoint(x, 0),
            'D': GeoPoint(x, r / 2),
            'C': GeoPoint(x, height),
          },
          bounds: GeoBounds(-3, -3, x + 3, height + 3),
          segments: [
            const GeoSegment('A', 'B', showLength: false),
            GeoSegment('A', 'D', showLength: false, label: '$r м'),
            GeoSegment('D', 'C', showLength: false, label: '$rise м'),
            const GeoSegment('B', 'D', showLength: false),
            const GeoSegment('A', 'C', showLength: false, label: '?'),
          ],
        ),
        tolerance: .005,
      );
    default:
      return _construction(base, n);
  }
}

GeometryScene _splitAngle(double known, double total) => GeometryScene(
  points: {
    'O': const GeoPoint(0, 0),
    'A': const GeoPoint(4, 0),
    'B': Geometry.polar(known, 4),
    'C': Geometry.polar(total, 4),
  },
  rays: const [
    GeoRay('O', 'A', rotatable: false),
    GeoRay('O', 'B', rotatable: false),
    GeoRay('O', 'C', rotatable: false),
  ],
  arcs: [
    AngleArc('A', 'O', 'B', showDegrees: false, label: '$known°'),
    const AngleArc('B', 'O', 'C', showDegrees: false, label: '?'),
  ],
);

Level _construction(Level base, int n) {
  var scene = base.initialGeometry;
  var target = base.targetAngle;
  var constraint = base.validation;
  var instruction = base.instruction;
  var goal = base.goal;
  var explanation = base.explanation;
  if (base.id == 'angle-45') {
    target = 48.0 + 2 * (n % 12);
    constraint = AngleConstraint('A', 'O', 'B', target: target);
    goal = '${mathNumber(target)}°';
    instruction =
        'Отсчитай от OA против часовой стрелки ${mathNumber(target)}°. Поверни OB.';
    explanation =
        'Доля оборота = α / 360° = $target / 360 ≈ ${mathNumber(target / 360)}. Угол острый: 0° < $target° < 90°.';
  }
  if (base.id == 'trig-standard-angle') {
    final cosine = [.3, .4, .7, .8][(n - 1) % 4];
    constraint = CosineAngleConstraint('A', 'O', 'B', target: cosine);
    target = math.acos(cosine) * 180 / math.pi;
    goal = 'cos α = ${mathNumber(cosine)}';
    instruction =
        'Поверни OB: косинус меньшего острого угла с OA должен быть ${mathNumber(cosine)}. Допускаются оба направления поворота.';
    explanation =
        'cos α = ${mathNumber(cosine)}, α = arccos(${mathNumber(cosine)}) ≈ ${mathNumber(target)}°. Зеркальное положение даёт такой же косинус.';
  }
  // Scaling changes the construction without changing equality, angles or ratios.
  final scale = 1.15 + n * .07;
  final direction = base.kind == PuzzleKind.rotateRay ? (25 + n * 19) % 360 : 0;
  final radians = direction * math.pi / 180;
  GeoPoint transform(GeoPoint p) => GeoPoint(
    (p.x * math.cos(radians) - p.y * math.sin(radians)) * scale,
    (p.x * math.sin(radians) + p.y * math.cos(radians)) * scale,
  );
  if (base.id == 'trig-scale') {
    instruction =
        'AB = ${mathNumber(8 * scale)}, α при B. Двигай C: '
        'построй прямой угол при A и AC / BC = 0,6. '
        'При изменении размера треугольника отношения сторон сохраняются.';
  }
  scene = GeometryScene(
    points: scene.points.map((id, p) => MapEntry(id, transform(p))),
    bounds: GeoBounds(
      scene.bounds.left * scale,
      scene.bounds.bottom * scale,
      scene.bounds.right * scale,
      scene.bounds.top * scale,
    ),
    segments: scene.segments,
    rays: scene.rays,
    triangles: scene.triangles,
    arcs: scene.arcs,
    draggable: scene.draggable,
    annotations: scene.annotations,
  );
  return Level(
    id: base.id,
    topicId: base.topicId,
    title: base.title,
    variant: n,
    kind: base.kind,
    initialScene: scene,
    constraint: constraint,
    targetAngle: target,
    instruction: instruction,
    goalLabel: goal,
    hint: base.hint,
    guidedHints: base.hints,
    explanation: explanation,
    accuracy: base.accuracy,
  );
}
