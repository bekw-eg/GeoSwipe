import 'lesson_help.dart';
import 'dart:math' as math;
import '../models/level.dart';
import '../models/math_topic.dart';
import '../core/geometry/constraints.dart';
import '../core/geometry/lesson_constraints.dart';
import '../core/geometry/geometry.dart';
import '../core/geometry/scene.dart';
import 'lesson_scenes.dart';

// Retain earlier IDs only for compatible tasks; retired IDs remain in saves.
final levels = List<Level>.unmodifiable([
  Level(
    id: 'angle-45',
    guidedHints: lessonHints['angle-45'],
    topicId: 'angles',
    title: 'Поймай угол',
    stage: LearningStage.explore,
    targetAngle: 45,
    initialAngle: 15,
    knowledge: ['Луч и вершина угла'],
    instruction:
        'Двигай B и наблюдай показания угла. Построй AOB = 45° против часовой стрелки от OA. Это острый угол.',
    hint: 'Измеряем поворот от OA к OB. Острый угол меньше 90°.',
    extraHints: ['Представь половину прямого угла.'],
    explanation:
        'α = 90° / 2 = 45° — половина прямого угла. Это острый угол: 0° < 45° < 90°.',
  ),
  Level(
    id: 'angle-90',
    guidedHints: lessonHints['angle-90'],
    topicId: 'angles',
    title: 'Прямой поворот',
    stage: LearningStage.rule,
    targetAngle: 90,
    initialAngle: 30,
    prerequisiteIds: ['angle-45'],
    knowledge: ['Измерение угла в градусах'],
    instruction:
        'Прямой угол равен четверти оборота. Поверни OB против часовой стрелки, чтобы OA и OB стали перпендикулярны.',
    hint: 'Полный оборот — 360°. Раздели его на четыре равные части.',
    explanation: '360° / 4 = 90°. Стороны прямого угла перпендикулярны.',
  ),
  Level(
    id: 'angle-135',
    guidedHints: lessonHints['angle-135'],
    topicId: 'angles',
    title: 'Шире прямого',
    stage: LearningStage.explore,
    targetAngle: 135,
    initialAngle: 60,
    prerequisiteIds: ['angle-90'],
    knowledge: ['Острый и прямой углы'],
    goalLabel: 'Тупой угол',
    instruction:
        'Построй любой тупой угол. Проверяется меньший угол между OA и OB: строго больше 90° и меньше 180°.',
    constraint: ObtuseAngleConstraint('A', 'O', 'B'),
    accuracy: '90° < меньший угол < 180° · Любое положение луча',
    hint: 'Раздвинь лучи шире прямого угла, но не выстраивай на одной прямой.',
    explanation:
        'Тупой угол строго больше 90° и меньше 180°. Подходят все такие углы, в том числе зеркальные положения луча.',
  ),
  Level(
    id: 'angle-complement',
    guidedHints: lessonHints['angle-complement'],
    topicId: 'angles',
    title: 'Дополни до прямого',
    stage: LearningStage.rule,
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['angle-135'],
    knowledge: const ['Прямой угол равен 90°'],
    goalLabel: 'Угол BOC',
    answerLabel: 'Угол BOC, в градусах',
    instruction:
        'OA и OC перпендикулярны. Луч OB внутри прямого угла; AOB = 35°. Найди BOC. Введи целое число градусов.',
    initialScene: complementaryScene(),
    constraint: const NumericAnswerConstraint(55, absoluteTolerance: 0),
    hint: 'Углы, дополняющие друг друга до прямого, в сумме дают 90°.',
    explanation:
        'AOB + BOC = 90°, поэтому BOC = 90° − 35° = 55°. Эти углы дополняют друг друга до 90°.',
  ),
  Level(
    id: 'angle-supplement',
    guidedHints: lessonHints['angle-supplement'],
    topicId: 'angles',
    title: 'Смежные углы',
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['angle-complement'],
    knowledge: const ['Развёрнутый угол равен 180°', 'Вычитание углов'],
    goalLabel: 'Угол BOC',
    answerLabel: 'Угол BOC, в градусах',
    instruction:
        'A, O, C лежат на одной прямой, O между A и C. AOB = 125°. Найди смежный BOC. Ответ — целое число градусов.',
    initialScene: supplementaryScene(),
    constraint: const NumericAnswerConstraint(55, absoluteTolerance: 0),
    hint:
        'Общая сторона — OB, а OA и OC — противоположные лучи. Сумма смежных углов — 180°.',
    explanation:
        'BOC = 180° − 125° = 55°. Смежные углы образуют развёрнутый угол; их сумма — 180°.',
  ),
  Level(
    id: 'triangle-angle-sum',
    guidedHints: lessonHints['triangle-angle-sum'],
    topicId: 'angles',
    title: 'Третий угол',
    stage: LearningStage.rule,
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['angle-supplement'],
    knowledge: const [
      'Внутренние углы треугольника',
      'Сложение и вычитание углов',
    ],
    goalLabel: 'Угол C',
    answerLabel: 'Угол C, в градусах',
    instruction:
        'В ABC угол A = 50°, B = 60°. Сумма внутренних углов треугольника — 180°. Найди C в целых градусах.',
    initialScene: triangleWithAngles(50, 60),
    constraint: const NumericAnswerConstraint(70, absoluteTolerance: 0),
    hint: 'Сложи известные углы. Оставшаяся до 180° часть — третий угол.',
    explanation:
        'C = 180° − (50° + 60°) = 70°. Правило работает для любого невырожденного треугольника.',
  ),
  Level(
    id: 'triangle-isosceles',
    guidedHints: lessonHints['triangle-isosceles'],
    topicId: 'angles',
    title: 'Равные стороны',
    stage: LearningStage.explore,
    kind: PuzzleKind.dragVertices,
    prerequisiteIds: const ['triangle-angle-sum'],
    knowledge: const ['Длина отрезка', 'Невырожденный треугольник'],
    goalLabel: 'AC = BC',
    instruction:
        'Двигай C и сравнивай длины AC и BC. Построй равнобедренный треугольник с основанием AB. Вершины не должны лежать на одной прямой.',
    initialScene: triangleScene(
      draggable: const {'C'},
      measured: true,
      bounds: const GeoBounds(-1, -5, 7, 5),
      arcs: const [AngleArc('B', 'A', 'C'), AngleArc('A', 'B', 'C')],
    ),
    constraint: AllConstraints(const [
      ValidTriangleConstraint(abc),
      EqualSegmentsConstraint(GeoSegment('A', 'C'), GeoSegment('B', 'C')),
    ]),
    accuracy: '|AC − BC| ≤ 0,05 · Невырожденный треугольник',
    hint:
        'Ищи точки на одинаковом расстоянии от A и B. Можно двигаться по обе стороны от основания.',
    explanation:
        'Точки серединного перпендикуляра к AB равноудалены от A и B. При AC = BC углы при основании A и B тоже равны.',
  ),
  Level(
    id: 'triangle-base-angle',
    guidedHints: lessonHints['triangle-base-angle'],
    topicId: 'angles',
    title: 'Углы при основании',
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['triangle-isosceles'],
    knowledge: const [
      'Равные стороны — равные противолежащие углы',
      'Сумма углов треугольника',
    ],
    goalLabel: 'Угол A',
    answerLabel: 'Угол A, в градусах',
    instruction:
        'В ABC стороны AC = BC, угол при вершине C = 40°. Найди угол при основании A. Ответ — целое число градусов.',
    initialScene: triangleScene(
      c: Geometry.polar(70, 3 / math.cos(70 * math.pi / 180)),
      labels: const {'AC': 'AC = BC', 'BC': 'AC = BC'},
      arcs: const [
        AngleArc('B', 'A', 'C', showDegrees: false, label: '?'),
        AngleArc('A', 'C', 'B', showDegrees: false, label: '40°'),
      ],
    ),
    constraint: const NumericAnswerConstraint(70, absoluteTolerance: 0),
    hint: 'Вычти угол C из 180°. Оставшиеся два угла равны.',
    explanation:
        'A = B = (180° − 40°) / 2 = 70°. Равные углы лежат напротив равных сторон.',
  ),
  Level(
    id: 'triangle-exterior',
    guidedHints: lessonHints['triangle-exterior'],
    topicId: 'angles',
    title: 'Снаружи треугольника',
    stage: LearningStage.rule,
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['triangle-base-angle'],
    knowledge: const ['Смежные углы', 'Сумма внутренних углов треугольника'],
    goalLabel: 'Угол DCA',
    answerLabel: 'Внешний угол DCA, в градусах',
    instruction:
        'В ABC угол A = 50°, B = 60°. BC продолжена за C до D. Найди внешний угол DCA в целых градусах.',
    initialScene: triangleWithAngles(50, 60, exterior: true),
    constraint: const NumericAnswerConstraint(110, absoluteTolerance: 0),
    hint:
        'Внешний угол смежен с C. Он также равен сумме двух внутренних углов, не смежных с ним.',
    explanation:
        'C = 70°, DCA = 180° − 70° = 110°. Другой путь: внешний угол равен A + B = 50° + 60°.',
  ),
  Level(
    id: 'triangle-combined',
    guidedHints: lessonHints['triangle-combined'],
    topicId: 'angles',
    title: 'Две идеи вместе',
    stage: LearningStage.challenge,
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['triangle-exterior'],
    knowledge: const [
      'Углы равнобедренного треугольника',
      'Внешний и смежный углы',
    ],
    goalLabel: 'Угол C',
    answerLabel: 'Угол при вершине C, в градусах',
    instruction:
        'AC = BC. AB продолжена за B до D; внешний угол CBD = 130°. Найди C в целых градусах.',
    initialScene: triangleWithAngles(
      50,
      50,
      equalSides: true,
      exteriorAtB: true,
      showBaseAngles: false,
    ),
    constraint: const NumericAnswerConstraint(80, absoluteTolerance: 0),
    hint:
        'Найди внутренний B из смежного внешнего. Затем используй равенство углов при основании.',
    explanation:
        'B = 180° − 130° = 50°, A = B = 50°. Тогда C = 180° − 50° − 50° = 80°.',
  ),
  Level(
    id: 'triangle-right',
    guidedHints: lessonHints['triangle-right'],
    topicId: 'pythagoras',
    title: 'Создай прямой угол',
    stage: LearningStage.explore,
    kind: PuzzleKind.dragVertices,
    prerequisiteIds: const ['triangle-combined'],
    knowledge: const ['Перпендикулярные стороны', 'Прямой угол'],
    goalLabel: '90°',
    instruction:
        'Перемести C, чтобы ABC стал прямоугольным. Прямой угол может быть при любой вершине.',
    initialScene: triangleScene(
      draggable: const {'C'},
      measured: true,
      bounds: const GeoBounds(-1, -3, 7, 5),
      arcs: const [
        AngleArc('B', 'A', 'C'),
        AngleArc('A', 'B', 'C'),
        AngleArc('A', 'C', 'B'),
      ],
    ),
    constraint: const RightTriangleConstraint(abc),
    hint:
        'Сделай стороны перпендикулярными. При горизонтальном AB можно поставить C над A или B; есть и другие решения.',
    explanation:
        'В прямоугольном треугольнике один угол равен 90°. Образующие его стороны — катеты, противоположная сторона — гипотенуза.',
  ),
  Level(
    id: 'pythagoras-legs',
    guidedHints: lessonHints['pythagoras-legs'],
    topicId: 'pythagoras',
    title: 'Узнай катеты',
    stage: LearningStage.rule,
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['triangle-right'],
    knowledge: const ['Катеты и гипотенуза', 'Сумма длин'],
    goalLabel: 'Катеты',
    answerLabel: 'Сумма длин катетов',
    instruction:
        'В ABC прямой угол при A; AB = 8, AC = 6, BC = 10. Найди сумму длин двух катетов. Ответ — целое число.',
    initialScene: rightScene(
      8,
      6,
      labels: const {'AB': '8', 'AC': '6', 'BC': '10'},
    ),
    constraint: const NumericAnswerConstraint(14, absoluteTolerance: 0),
    hint:
        'Гипотенуза лежит напротив прямого угла. Складывай стороны, которые этот угол образуют.',
    explanation:
        'Катеты AB и AC образуют прямой угол при A. Их сумма 8 + 6 = 14. BC = 10 — гипотенуза.',
  ),
  Level(
    id: 'pythagoras-squares',
    guidedHints: lessonHints['pythagoras-squares'],
    topicId: 'pythagoras',
    title: 'Квадраты на сторонах',
    stage: LearningStage.rule,
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['pythagoras-legs'],
    knowledge: const ['Площадь квадрата', 'Катеты и гипотенуза'],
    goalLabel: 'Площадь',
    answerLabel: 'Площадь квадрата на BC',
    instruction:
        'На сторонах прямоугольного ABC построены квадраты. Площади квадратов на катетах — 9 и 16. Площадь квадрата на гипотенузе равна их сумме. Найди её целым числом.',
    initialScene: pythagoreanSquares(),
    constraint: const NumericAnswerConstraint(25, absoluteTolerance: 0),
    hint:
        'Площадь квадрата со стороной a — a². Складываются площади, а не длины сторон.',
    explanation:
        'S = 9 + 16 = 25. Это теорема Пифагора: a² + b² = c², где c — гипотенуза.',
  ),
  Level(
    id: 'pythagoras-3-4',
    guidedHints: lessonHints['pythagoras-3-4'],
    topicId: 'pythagoras',
    title: 'Неизвестная гипотенуза',
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['pythagoras-squares'],
    knowledge: const ['Теорема Пифагора', 'Квадратный корень'],
    goalLabel: 'BC',
    answerLabel: 'Длина гипотенузы BC',
    instruction:
        'В ABC прямой угол при A, катеты AB = 4 и AC = 3. Найди BC. Введи целое число.',
    initialScene: rightScene(
      4,
      3,
      labels: const {'AB': '4', 'AC': '3', 'BC': '?'},
    ),
    constraint: const NumericAnswerConstraint(5, absoluteTolerance: 0),
    hint: 'Сложи квадраты катетов, затем извлеки квадратный корень.',
    explanation:
        'BC = √(3² + 4²) = √25 = 5. Складываются квадраты, а не сами катеты.',
  ),
  Level(
    id: 'pythagoras-missing-leg',
    guidedHints: lessonHints['pythagoras-missing-leg'],
    topicId: 'pythagoras',
    title: 'Верни катет',
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['pythagoras-3-4'],
    knowledge: const ['Теорема Пифагора', 'Вычитание квадратов'],
    goalLabel: 'AC',
    answerLabel: 'Длина катета AC',
    instruction:
        'Прямой угол при A. Гипотенуза BC = 13, катет AB = 5. Найди AC. Ответ — целое число.',
    initialScene: rightScene(
      5,
      12,
      labels: const {'AB': '5', 'AC': '?', 'BC': '13'},
    ),
    constraint: const NumericAnswerConstraint(12, absoluteTolerance: 0),
    hint:
        'Из квадрата гипотенузы вычти квадрат известного катета. Затем извлеки корень.',
    explanation:
        'AC² = 13² − 5² = 144, значит AC = 12. Длина положительна, отрицательный корень не подходит.',
  ),
  Level(
    id: 'pythagoras-construct',
    guidedHints: lessonHints['pythagoras-construct'],
    topicId: 'pythagoras',
    title: 'Прямой и равнобедренный',
    stage: LearningStage.explore,
    kind: PuzzleKind.dragVertices,
    prerequisiteIds: const ['pythagoras-missing-leg'],
    knowledge: const [
      'Прямоугольный треугольник',
      'Равнобедренный треугольник',
    ],
    goalLabel: 'Угол C = 90°',
    instruction:
        'Построй ABC с прямым углом именно при C и равными катетами AC = BC. Двигай C; подходят положения с любой стороны AB.',
    initialScene: triangleScene(
      draggable: const {'C'},
      measured: true,
      bounds: const GeoBounds(-1, -5, 7, 5),
      arcs: const [AngleArc('A', 'C', 'B')],
    ),
    constraint: AllConstraints(const [
      ValidTriangleConstraint(abc),
      AngleConstraint('A', 'C', 'B', target: 90, directed: false, tolerance: 1),
      EqualSegmentsConstraint(GeoSegment('A', 'C'), GeoSegment('B', 'C')),
    ]),
    accuracy: 'Угол C = 90° ±1° · |AC − BC| ≤ 0,05 · Треугольник невырожден',
    hint:
        'Равные катеты помещают C на серединный перпендикуляр к AB. Меняй высоту, следя за углом C.',
    explanation:
        'Углы при основании равны 45°. При AB = 6 каждый катет равен 6 / √2 = 3√2. Отражение относительно AB тоже подходит.',
  ),
  Level(
    id: 'pythagoras-diagonal',
    guidedHints: lessonHints['pythagoras-diagonal'],
    topicId: 'pythagoras',
    title: 'Диагональ экрана',
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['pythagoras-construct'],
    knowledge: const [
      'Прямоугольник',
      'Теорема Пифагора',
      'Округление до сотых',
    ],
    goalLabel: 'AC',
    answerLabel: 'Диагональ AC, до 0,01',
    instruction:
        'ABCD — прямоугольник со сторонами 7 и 5. Найди AC. Округли до 0,01; допуск ±0,005.',
    initialScene: rectangleScene(),
    constraint: NumericAnswerConstraint(math.sqrt(74), absoluteTolerance: .005),
    hint: 'Диагональ делит прямоугольник на два прямоугольных треугольника.',
    explanation:
        'AC = √(7² + 5²) = √74 ≈ 8,60. Округляем только окончательный результат.',
  ),
  Level(
    id: 'pythagoras-distance',
    guidedHints: lessonHints['pythagoras-distance'],
    topicId: 'pythagoras',
    title: 'Напрямик по карте',
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['pythagoras-diagonal'],
    knowledge: const [
      'Координаты точки',
      'Разности координат',
      'Теорема Пифагора',
    ],
    goalLabel: 'AC',
    answerLabel: 'Расстояние AC',
    instruction:
        'Даны A(−2; −1) и C(4; 7), единицы по осям одинаковы. Найди расстояние напрямик AC. Ответ — целое число.',
    initialScene: triangleScene(
      a: const GeoPoint(-2, -1),
      b: const GeoPoint(4, -1),
      c: const GeoPoint(4, 7),
      labels: const {'AC': '?'},
      arcs: const [AngleArc('A', 'B', 'C', showDegrees: false, label: '90°')],
    ),
    constraint: const NumericAnswerConstraint(10, absoluteTolerance: 0),
    hint:
        'Горизонтальный и вертикальный пути — катеты. Вычисли разности координат, включая отрицательные.',
    explanation: 'Δx = 4 − (−2) = 6, Δy = 7 − (−1) = 8. AC = √(6² + 8²) = 10.',
  ),
  Level(
    id: 'pythagoras-ladder',
    guidedHints: lessonHints['pythagoras-ladder'],
    topicId: 'pythagoras',
    title: 'Лестница у стены',
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['pythagoras-distance'],
    knowledge: const ['Гипотенуза в прикладной задаче', 'Поиск катета'],
    goalLabel: 'Высота',
    answerLabel: 'Высота AC, в метрах',
    instruction:
        'Стена AC перпендикулярна земле AB. Лестница BC длиной 10 м стоит основанием B в 6 м от стены. На какой высоте C её верх? Ответ — целое число метров.',
    initialScene: rightScene(
      6,
      8,
      labels: const {'AB': '6 м', 'AC': '?', 'BC': '10 м'},
    ),
    constraint: const NumericAnswerConstraint(8, absoluteTolerance: 0),
    hint: 'Лестница — гипотенуза. Высоту ищем как неизвестный катет.',
    explanation:
        'AC = √(10² − 6²) = √64 = 8 м. Гипотенуза уже известна, поэтому квадраты вычитаются.',
  ),
  Level(
    id: 'pythagoras-combined',
    guidedHints: lessonHints['pythagoras-combined'],
    topicId: 'pythagoras',
    title: 'Высота крыши',
    stage: LearningStage.challenge,
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['pythagoras-ladder'],
    knowledge: const ['Высота равнобедренного треугольника', 'Поиск катета'],
    goalLabel: 'CH',
    answerLabel: 'Высота CH',
    instruction:
        'Сечение крыши — равнобедренный ABC: AC = BC = 13, AB = 10. CH — высота к AB. Найди CH. Ответ — целое число.',
    initialScene: isoscelesHeight(),
    constraint: const NumericAnswerConstraint(12, absoluteTolerance: 0),
    hint:
        'Высота к основанию равнобедренного треугольника делит основание пополам. Используй полученный прямоугольный треугольник.',
    explanation:
        'AH = HB = 5. В ACH гипотенуза AC = 13, поэтому CH = √(13² − 5²) = 12.',
  ),
  Level(
    id: 'trig-side-ratio',
    guidedHints: lessonHints['trig-side-ratio'],
    topicId: 'trigonometry',
    title: 'Стороны относительно угла',
    stage: LearningStage.explore,
    kind: PuzzleKind.dragVertices,
    prerequisiteIds: const ['pythagoras-combined'],
    knowledge: const ['Катеты и гипотенуза', 'Отношение чисел'],
    goalLabel: 'AC / AB',
    instruction:
        'Для α при B катет AC — противолежащий, AB — прилежащий. Двигай C: сделай A прямым и AC / AB = 0,5. BC — гипотенуза.',
    initialScene: triangleScene(
      c: const GeoPoint(1, 4),
      draggable: const {'C'},
      measured: true,
      bounds: const GeoBounds(-2, -5, 8, 5),
      arcs: const [AngleArc('B', 'A', 'C'), AngleArc('A', 'B', 'C')],
    ),
    constraint: AllConstraints(const [
      ValidTriangleConstraint(abc),
      AngleConstraint('B', 'A', 'C', target: 90, directed: false, tolerance: 1),
      SegmentRatioConstraint(
        GeoSegment('A', 'C'),
        GeoSegment('A', 'B'),
        target: .5,
      ),
    ]),
    accuracy: 'Угол A = 90° ±1° · AC / AB = 0,5 ±0,01 · Треугольник невырожден',
    hint:
        'Поставь AC перпендикулярно AB. Сделай противолежащий катет вдвое короче прилежащего.',
    explanation:
        'Катеты называются относительно выбранного угла. Для α = B противолежащий — AC, прилежащий — AB. Их отношение 0,5; отражение не меняет отношение.',
  ),
  Level(
    id: 'trig-sine',
    guidedHints: lessonHints['trig-sine'],
    topicId: 'trigonometry',
    title: 'Первый синус',
    stage: LearningStage.rule,
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['trig-side-ratio'],
    knowledge: const ['Противолежащий катет', 'Гипотенуза', 'Деление длин'],
    goalLabel: 'sin α',
    answerLabel: 'sin α, до 0,01',
    instruction:
        'A = 90°, α при B. AC = 3, AB = 4, BC = 5. Синус — противолежащий катет / гипотенуза. Найди sin α до 0,01; допуск ±0,005.',
    initialScene: rightScene(
      4,
      3,
      labels: const {'AB': '4', 'AC': '3', 'BC': '5'},
      extraArcs: const [
        AngleArc('A', 'B', 'C', showDegrees: false, label: 'α'),
      ],
    ),
    constraint: const NumericAnswerConstraint(.6, absoluteTolerance: .005),
    hint: 'Для угла B числитель — AC, знаменатель — BC.',
    explanation:
        'sin α = AC / BC = 3 / 5 = 0,60. Синус острого угла положителен и меньше 1.',
  ),
  Level(
    id: 'trig-cosine',
    guidedHints: lessonHints['trig-cosine'],
    topicId: 'trigonometry',
    title: 'Первый косинус',
    stage: LearningStage.rule,
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['trig-sine'],
    knowledge: const ['Прилежащий катет', 'Гипотенуза'],
    goalLabel: 'cos α',
    answerLabel: 'cos α, до 0,01',
    instruction:
        'A = 90°, α при B; AB = 4, AC = 3, BC = 5. Косинус — прилежащий катет / гипотенуза. Найди cos α до 0,01; допуск ±0,005.',
    initialScene: rightScene(
      4,
      3,
      labels: const {'AB': '4', 'AC': '3', 'BC': '5'},
      extraArcs: const [
        AngleArc('A', 'B', 'C', showDegrees: false, label: 'α'),
      ],
    ),
    constraint: const NumericAnswerConstraint(.8, absoluteTolerance: .005),
    hint: 'Прилежащий катет касается α, но не является гипотенузой.',
    explanation:
        'cos α = AB / BC = 4 / 5 = 0,80. Прилежащий катет определяется выбранным углом.',
  ),
  Level(
    id: 'trig-tangent',
    guidedHints: lessonHints['trig-tangent'],
    topicId: 'trigonometry',
    title: 'Первый тангенс',
    stage: LearningStage.rule,
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['trig-cosine'],
    knowledge: const ['Противолежащий и прилежащий катеты'],
    goalLabel: 'tg α',
    answerLabel: 'tg α, до 0,01',
    instruction:
        'A = 90°, α при B; AC = 3, AB = 4. Тангенс — противолежащий катет / прилежащий. Найди tg α до 0,01; допуск ±0,005.',
    initialScene: rightScene(
      4,
      3,
      labels: const {'AB': '4', 'AC': '3'},
      extraArcs: const [
        AngleArc('A', 'B', 'C', showDegrees: false, label: 'α'),
      ],
    ),
    constraint: const NumericAnswerConstraint(.75, absoluteTolerance: .005),
    hint: 'Гипотенуза в определении тангенса не участвует.',
    explanation:
        'tg α = AC / AB = 3 / 4 = 0,75. Тангенс, в отличие от синуса и косинуса, может быть больше 1.',
  ),
  Level(
    id: 'trig-scale',
    guidedHints: lessonHints['trig-scale'],
    topicId: 'trigonometry',
    title: 'Сохрани синус',
    stage: LearningStage.explore,
    kind: PuzzleKind.dragVertices,
    prerequisiteIds: const ['trig-tangent'],
    knowledge: const [
      'Определение синуса',
      'Отношения сторон подобных треугольников',
    ],
    goalLabel: 'sin α = 0,6',
    instruction:
        'AB = 8, α при B. Двигай C: построй прямой угол при A и AC / BC = 0,6. Сравни с первым синусом: важны отношения, а не размер.',
    initialScene: triangleScene(
      b: const GeoPoint(8, 0),
      c: const GeoPoint(2, 5),
      draggable: const {'C'},
      measured: true,
      bounds: const GeoBounds(-1, -7, 9, 7),
      arcs: const [AngleArc('B', 'A', 'C'), AngleArc('A', 'B', 'C')],
    ),
    constraint: AllConstraints(const [
      ValidTriangleConstraint(abc),
      AngleConstraint('B', 'A', 'C', target: 90, directed: false, tolerance: 1),
      SegmentRatioConstraint(
        GeoSegment('A', 'C'),
        GeoSegment('B', 'C'),
        target: .6,
      ),
    ]),
    accuracy: 'Угол A = 90° ±1° · AC / BC = 0,6 ±0,01 · Треугольник невырожден',
    hint:
        'Удвоение всех сторон сохраняет отношения. Ищи C над A или под A, затем подстрой длину.',
    explanation:
        'Подходят катеты 8 и 6 с гипотенузой 10: sin α = 6 / 10 = 0,6. Это удвоенный треугольник 3–4–5. Отражение тоже подходит.',
  ),
  Level(
    id: 'trig-standard-angle',
    guidedHints: lessonHints['trig-standard-angle'],
    topicId: 'trigonometry',
    title: 'Угол по косинусу',
    stage: LearningStage.explore,
    targetAngle: 60,
    initialAngle: 20,
    prerequisiteIds: ['trig-scale'],
    knowledge: ['Косинус острого угла'],
    goalLabel: 'cos α = 0,5',
    instruction:
        'Поверни OB так, чтобы косинус меньшего угла α между OA и OB был 0,5. Угол α острый; поворот можно делать в обе стороны.',
    constraint: CosineAngleConstraint('A', 'O', 'B', target: .5),
    accuracy: 'cos α = 0,5 ±0,01 · 0° < меньший угол α < 90°',
    hint:
        'Представь половину равностороннего треугольника. Сравни прилежащий катет и гипотенузу.',
    explanation:
        'cos 60° = 1/2. Меньший угол равен 60° при повороте как на 60°, так и на 300°. Оба положения принимаются.',
  ),
  Level(
    id: 'trig-length',
    guidedHints: lessonHints['trig-length'],
    topicId: 'trigonometry',
    title: 'Катет напротив 30°',
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['trig-standard-angle'],
    knowledge: const ['Синус', 'Умножение длины на отношение'],
    goalLabel: 'AC',
    answerLabel: 'Длина AC',
    instruction:
        'В ABC угол A = 90°, B = 30°, BC = 10. Известно: sin 30° = 1/2. Найди катет AC. Ответ — целое число.',
    initialScene: rightScene(
      5 * math.sqrt(3),
      5,
      labels: const {'AC': '?', 'BC': '10'},
      extraArcs: const [
        AngleArc('A', 'B', 'C', showDegrees: false, label: '30°'),
      ],
    ),
    constraint: const NumericAnswerConstraint(5, absoluteTolerance: 0),
    hint: 'Из sin B = AC / BC вырази AC: умножь обе части на BC.',
    explanation:
        'AC = BC × sin 30° = 10 × 1/2 = 5. Напротив угла 30° катет равен половине гипотенузы.',
  ),
  Level(
    id: 'trig-function',
    guidedHints: lessonHints['trig-function'],
    topicId: 'trigonometry',
    title: 'Выбери отношение',
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['trig-length'],
    knowledge: const ['Синус, косинус и тангенс', 'Стандартный угол 45°'],
    goalLabel: 'Высота',
    answerLabel: 'Высота AC, в метрах',
    instruction:
        'A — основание башни AC, AB = 12 м по горизонтали. Из B вершина C видна под углом 45°. sin 45° = cos 45° = √2/2, tg 45° = 1. Выбери отношение для двух катетов и вычисли высоту целым числом метров.',
    initialScene: rightScene(
      12,
      12,
      labels: const {'AB': '12 м', 'AC': '?'},
      extraArcs: const [
        AngleArc('A', 'B', 'C', showDegrees: false, label: '45°'),
      ],
    ),
    constraint: const NumericAnswerConstraint(12, absoluteTolerance: 0),
    hint:
        'Известен прилежащий катет, нужен противолежащий. Их связывает тангенс.',
    explanation:
        'Выбираем tg B = AC / AB. Тогда AC = 12 × tg 45° = 12 м. Можно также получить отношение sin B / cos B.',
  ),
  Level(
    id: 'trig-application',
    guidedHints: lessonHints['trig-application'],
    topicId: 'trigonometry',
    title: 'Высота по тени',
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['trig-function'],
    knowledge: const ['Тангенс', 'Стандартный угол 60°', 'Округление до сотых'],
    goalLabel: 'Высота',
    answerLabel: 'Высота AC, до 0,01 м',
    instruction:
        'Вертикальный столб AC отбрасывает на горизонтальную землю тень AB = 6 м. Луч BC образует с землёй при B угол 60°. tg 60° = √3. Найди высоту до 0,01 м; допуск ±0,005 м.',
    initialScene: rightScene(
      6,
      6 * math.sqrt(3),
      labels: const {'AB': '6 м', 'AC': '?'},
      extraArcs: const [
        AngleArc('A', 'B', 'C', showDegrees: false, label: '60°'),
      ],
    ),
    constraint: NumericAnswerConstraint(
      6 * math.sqrt(3),
      absoluteTolerance: .005,
    ),
    hint:
        'Высота — противолежащий катет, тень — прилежащий. Не округляй корень до последнего действия.',
    explanation:
        'AC = AB × tg 60° = 6√3 ≈ 10,39 м. При угле больше 45° высота больше тени.',
  ),
  Level(
    id: 'trig-final',
    guidedHints: lessonHints['trig-final'],
    topicId: 'trigonometry',
    title: 'Полёт дрона',
    stage: LearningStage.challenge,
    kind: PuzzleKind.numericAnswer,
    prerequisiteIds: const ['trig-application'],
    knowledge: const [
      'Синус и косинус 30°',
      'Теорема Пифагора',
      'Расчёт в несколько шагов',
    ],
    goalLabel: 'AC',
    answerLabel: 'Расстояние AC, до 0,01 м',
    instruction:
        'Дрон D в 26 м по прямой от A под углом 30° к горизонтали AB. Он поднимается вертикально на 5 м до C; B — общая проекция D и C. Найди новое AC. sin 30° = 1/2, cos 30° = √3/2. Округли до 0,01 м; допуск ±0,005 м.',
    initialScene: finalFlight(),
    constraint: NumericAnswerConstraint(
      math.sqrt(831),
      absoluteTolerance: .005,
    ),
    hint:
        'Найди исходную высоту и горизонтальную проекцию. Увеличь только высоту, затем примени теорему Пифагора.',
    extraHints: const [
      'BD = AD × sin 30°, AB = AD × cos 30°. Новая высота BC = BD + 5.',
    ],
    explanation:
        'BD = 13 м; AB = 13√3 м. Новая высота BC = 18 м. AC = √((13√3)² + 18²) = √831 ≈ 28,83 м.',
  ),
]);

final topics = List<MathTopic>.unmodifiable([
  MathTopic(
    id: 'angles',
    title: 'Углы и треугольники',
    description: 'От поворота луча до свойств треугольника',
    levelIds: List.unmodifiable(levels.take(10).map((l) => l.id)),
  ),
  MathTopic(
    id: 'pythagoras',
    title: 'Пифагор и длины',
    description: 'От прямого угла до расстояний и конструкций',
    levelIds: List.unmodifiable(levels.skip(10).take(10).map((l) => l.id)),
  ),
  MathTopic(
    id: 'trigonometry',
    title: 'Тригонометрия',
    description: 'От отношений сторон до полёта дрона',
    levelIds: List.unmodifiable(levels.skip(20).map((l) => l.id)),
  ),
]);
