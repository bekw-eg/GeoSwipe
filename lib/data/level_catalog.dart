import '../models/level.dart';
import '../models/math_topic.dart';
import '../core/geometry/constraints.dart';
import '../core/geometry/geometry.dart';
import '../core/geometry/scene.dart';

final levels = List<Level>.unmodifiable([
  Level(
    id: 'angle-45',
    topicId: 'angles',
    title: 'Поймай угол',
    targetAngle: 45,
    initialAngle: 15,
    hint:
        'Острый угол меньше прямого. Двигай луч против часовой стрелки от горизонтали.',
    explanation:
        '45° — половина прямого угла. Два таких угла вместе образуют 90°.',
  ),
  Level(
    id: 'angle-90',
    topicId: 'angles',
    title: 'Прямой поворот',
    targetAngle: 90,
    initialAngle: 30,
    hint:
        'Прямой угол — четверть полного оборота. Представь угол листа бумаги.',
    explanation: 'При 90° лучи перпендикулярны: горизонтальный и вертикальный.',
  ),
  Level(
    id: 'angle-135',
    topicId: 'angles',
    title: 'Шире прямого',
    targetAngle: 135,
    initialAngle: 60,
    hint: 'Тупой угол лежит между прямым углом и развёрнутым.',
    explanation:
        '135° = 90° + 45°. Это тупой угол: он больше 90°, но меньше 180°.',
  ),
  Level(
    id: 'angle-180',
    topicId: 'angles',
    title: 'На одной прямой',
    targetAngle: 180,
    initialAngle: 105,
    hint: 'Развёрнутый угол — половина полного оборота.',
    explanation:
        '180° — развёрнутый угол. Лучи направлены в противоположные стороны.',
  ),
  Level(
    id: 'angle-270',
    topicId: 'angles',
    title: 'Три четверти',
    targetAngle: 270,
    initialAngle: 195,
    hint: 'Продолжай поворот против часовой стрелки дальше половины оборота.',
    explanation:
        '270° = 3 × 90°. Луч направлен вниз после трёх четвертей оборота.',
  ),
  Level(
    id: 'angle-315',
    topicId: 'angles',
    title: 'Почти полный круг',
    targetAngle: 315,
    initialAngle: 240,
    hint:
        'Полный оборот равен 360°. Искомый угол находится в четвёртой четверти.',
    explanation: '315° = 360° − 45°. До полного оборота остаётся 45°.',
  ),
  const Level(
    id: 'angle-60',
    topicId: 'angles',
    title: 'Точный поворот',
    targetAngle: 60,
    initialAngle: 20,
    hint: '60° — треть развёрнутого угла. Начни с горизонтального луча.',
    explanation: '60° — шестая часть полного оборота: 360° / 6 = 60°.',
  ),
  Level(
    id: 'triangle-right',
    topicId: 'triangles',
    title: 'Создай прямой угол',
    kind: PuzzleKind.dragVertices,
    goalLabel: '90°',
    instruction:
        'Перемести C, чтобы треугольник ABC стал прямоугольным. Прямой угол может быть при любой вершине.',
    hint: 'У прямого угла стороны перпендикулярны. Основание AB горизонтально.',
    explanation:
        'В прямоугольном треугольнике один угол равен 90°. Сумма двух остальных равна 90°.',
    initialScene: GeometryScene(
      bounds: const GeoBounds(-1, -3, 7, 5),
      points: const {
        'A': GeoPoint(0, 0),
        'B': GeoPoint(6, 0),
        'C': GeoPoint(2, 4),
      },
      triangles: const [TriangleRef('A', 'B', 'C')],
      segments: const [
        GeoSegment('A', 'B'),
        GeoSegment('B', 'C'),
        GeoSegment('C', 'A'),
      ],
      arcs: const [
        AngleArc('B', 'A', 'C'),
        AngleArc('A', 'B', 'C'),
        AngleArc('A', 'C', 'B'),
      ],
      draggable: const {'C'},
    ),
    constraint: const RightTriangleConstraint(TriangleRef('A', 'B', 'C')),
  ),
  Level(
    id: 'pythagoras-3-4',
    topicId: 'triangles',
    title: 'Неизвестная гипотенуза',
    kind: PuzzleKind.numericAnswer,
    goalLabel: '3 и 4',
    answerLabel: 'Длина гипотенузы BC',
    instruction:
        'Катеты прямоугольного треугольника равны 3 и 4. Найди гипотенузу BC.',
    hint:
        'Квадрат гипотенузы равен сумме квадратов катетов. Затем извлеки квадратный корень.',
    explanation:
        'BC = √(3² + 4²) = √25 = 5. Гипотенуза лежит напротив прямого угла.',
    initialScene: GeometryScene(
      bounds: const GeoBounds(-1, -1, 5, 5),
      points: const {
        'A': GeoPoint(0, 0),
        'B': GeoPoint(4, 0),
        'C': GeoPoint(0, 3),
      },
      triangles: const [TriangleRef('A', 'B', 'C')],
      segments: const [
        GeoSegment('A', 'B', label: '4'),
        GeoSegment('C', 'A', label: '3'),
        GeoSegment('B', 'C', showLength: false, label: '?'),
      ],
      arcs: const [AngleArc('B', 'A', 'C')],
    ),
    constraint: NumericAnswerConstraint(Geometry.hypotenuse(3, 4)!),
  ),
]);

const topics = <MathTopic>[
  MathTopic(
    id: 'angles',
    title: 'Углы и повороты',
    description: 'От первого луча до полного оборота',
    levelIds: [
      'angle-45',
      'angle-90',
      'angle-135',
      'angle-180',
      'angle-270',
      'angle-315',
      'angle-60',
    ],
  ),
  MathTopic(
    id: 'triangles',
    title: 'Треугольники',
    description: 'Стороны, высоты и теорема Пифагора',
    levelIds: ['triangle-right', 'pythagoras-3-4'],
  ),
  MathTopic(
    id: 'trigonometry',
    title: 'Тригонометрия',
    description: 'Синус, косинус и единичная окружность',
  ),
];
