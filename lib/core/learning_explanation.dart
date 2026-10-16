import '../data/review_variants.dart';
import '../models/level.dart';
import '../models/puzzle_state.dart';
import 'geometry/geometry.dart';

/// Uses the player's accepted construction, including reflected solutions.
String learningExplanation(Level level, PuzzleState state) {
  if (!state.isComplete) return '';
  if (level.id == 'angle-135') {
    final p = state.scene.points;
    final angle = Geometry.angleBetween(p['A']! - p['O']!, p['B']! - p['O']!)!;
    return 'Условие тупого угла: 90° < α < 180°. '
        'В твоём построении α = ${mathNumber(angle)}°: '
        '90° < ${mathNumber(angle)}° < 180°. Зеркальное положение тоже подходит.';
  }
  if (level.kind != PuzzleKind.dragVertices ||
      !const {
        'triangle-isosceles',
        'triangle-right',
        'pythagoras-construct',
        'trig-side-ratio',
        'trig-scale',
      }.contains(level.id)) {
    return level.explanation;
  }
  final p = state.scene.points;
  final ab = Geometry.distance(p['A']!, p['B']!)!;
  final ac = Geometry.distance(p['A']!, p['C']!)!;
  final bc = Geometry.distance(p['B']!, p['C']!)!;
  final angles = Geometry.triangleAngles(
    GeoTriangle(p['A']!, p['B']!, p['C']!),
  )!;
  final lengths =
      'AB ≈ ${mathNumber(ab)}, AC ≈ ${mathNumber(ac)}, BC ≈ ${mathNumber(bc)}.';
  return switch (level.id) {
    'triangle-isosceles' =>
      'Правило: AC = BC ⇒ A = B. $lengths |AC − BC| ≈ ${mathNumber((ac - bc).abs())} ≤ 0,05. Равные стороны дают равные углы при основании: A ≈ ${mathNumber(angles[0])}°, B ≈ ${mathNumber(angles[1])}°.',
    'triangle-right' =>
      '$lengths Формула: A + B + C = 180°. Подстановка: ${mathNumber(angles[0])}° + ${mathNumber(angles[1])}° + ${mathNumber(angles[2])}° ≈ 180°. Один угол прямой; противоположная сторона — гипотенуза.',
    'pythagoras-construct' =>
      '$lengths Формула: AC² + BC² = AB². Подстановка: ${mathNumber(ac * ac)} + ${mathNumber(bc * bc)} ≈ ${mathNumber(ab * ab)}. Равные катеты: AC ≈ BC ≈ AB / √2; угол C ≈ ${mathNumber(angles[2])}°.',
    'trig-side-ratio' =>
      '$lengths Для α при B: tg α = AC / AB ≈ ${mathNumber(ac)} / ${mathNumber(ab)} ≈ ${mathNumber(ac / ab)}. Катеты образуют угол A ≈ ${mathNumber(angles[0])}°.',
    'trig-scale' =>
      '$lengths Для α при B: sin α = AC / BC ≈ ${mathNumber(ac)} / ${mathNumber(bc)} ≈ ${mathNumber(ac / bc)}. Масштабирование сохраняет отношение сторон и угол.',
    _ => level.explanation,
  };
}
