import '../models/level.dart';
import '../models/math_topic.dart';

const levels = <Level>[
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
];

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
    ],
  ),
  MathTopic(
    id: 'triangles',
    title: 'Треугольники',
    description: 'Стороны, высоты и теорема Пифагора',
  ),
  MathTopic(
    id: 'trigonometry',
    title: 'Тригонометрия',
    description: 'Синус, косинус и единичная окружность',
  ),
];
