import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/app_controller.dart';
import '../../core/theme.dart';
import '../../models/level.dart';
import '../../widgets/angle_board.dart';
import '../../widgets/common.dart';

class PuzzleCard extends StatelessWidget {
  const PuzzleCard({
    super.key,
    required this.controller,
    required this.level,
    required this.number,
    required this.total,
    required this.onNext,
    this.review = false,
  });
  final AppController controller;
  final Level level;
  final int number;
  final int total;
  final VoidCallback onNext;
  final bool review;

  @override
  Widget build(BuildContext context) {
    final state = controller.puzzle(level, review: review);
    final complete = state.isComplete;
    final progress = controller.progress.forLevel(level.id);
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
        final boardHeight = (constraints.maxHeight - 450).clamp(140.0, 330.0);
        return SingleChildScrollView(
          physics:
              constraints.maxHeight < 590 ||
                  largeText ||
                  state.hintUsed ||
                  state.result != null
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Tag(
                    review ? 'ЗАКРЕПЛЯЕМ' : 'УГЛЫ И ПОВОРОТЫ',
                    icon: Icons.auto_awesome_outlined,
                  ),
                  const Spacer(),
                  Text(
                    '${number.toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Text(
                level.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Поверни луч до заданного угла',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: AppColors.surface,
                  border: Border.all(
                    color: complete
                        ? AppColors.mint.withValues(alpha: .45)
                        : AppColors.line,
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ЦЕЛЬ',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 9,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                '${level.targetAngle.round()}°',
                                style: const TextStyle(
                                  fontSize: 35,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                  letterSpacing: -1.5,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Tag(
                            complete ? 'Получилось' : 'Двигай точку B',
                            icon: complete
                                ? Icons.check
                                : Icons.touch_app_outlined,
                            color: complete ? AppColors.mint : AppColors.violet,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: boardHeight,
                      child: AngleBoard(
                        angle: state.angle,
                        complete: complete,
                        onChanged: (value) =>
                            controller.rotate(level, value, review: review),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          const Text(
                            'ТВОЙ УГОЛ',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 9,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${state.angle.toStringAsFixed(1)}°',
                            key: const ValueKey('current-angle'),
                            style: const TextStyle(
                              color: AppColors.violet,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Slider(
                        key: const ValueKey('angle-slider'),
                        value: math.min(state.angle, 359.9),
                        min: 0,
                        max: 359.9,
                        divisions: 3599,
                        semanticFormatterCallback: (value) =>
                            '${value.toStringAsFixed(1)} градуса',
                        onChanged: complete
                            ? null
                            : (value) => controller.rotate(
                                level,
                                value,
                                review: review,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (state.hintUsed && !complete) ...[
                _Feedback(
                  icon: Icons.lightbulb_outline,
                  color: AppColors.warning,
                  title: 'Небольшая подсказка',
                  text: level.hint,
                ),
                const SizedBox(height: 12),
              ],
              if (state.result != null) ...[
                Semantics(
                  liveRegion: true,
                  child: _Feedback(
                    icon: complete
                        ? Icons.check_circle_outline
                        : Icons.explore_outlined,
                    color: complete ? AppColors.mint : AppColors.warning,
                    title: complete
                        ? (state.hintUsed
                              ? 'Решено с подсказкой'
                              : progress.isMastered
                              ? 'Навык закреплён!'
                              : 'Отличный поворот!')
                        : 'Ещё немного',
                    text: complete
                        ? level.explanation
                        : 'Отклонение ${state.result!.error.toStringAsFixed(1)}°. Подстрой луч и проверь ещё раз.',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('check-answer'),
                  onPressed: complete
                      ? onNext
                      : () => controller.submit(level, review: review),
                  icon: Icon(
                    complete ? Icons.arrow_upward_rounded : Icons.check_rounded,
                    size: 19,
                  ),
                  label: Text(
                    complete
                        ? (review
                              ? 'К повторению'
                              : number == total
                              ? 'К карте обучения'
                              : 'Следующий уровень')
                        : 'Проверить',
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: complete || state.hintUsed
                        ? null
                        : () => controller.showHint(level, review: review),
                    icon: const Icon(Icons.lightbulb_outline, size: 16),
                    label: const Text('Подсказка'),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => controller.restart(level, review: review),
                    tooltip: 'Начать заново',
                    icon: const Icon(Icons.restart_alt, size: 20),
                  ),
                ],
              ),
              Center(
                child: Text(
                  'Допуск ±${level.tolerance.round()}° · Отсчёт против часовой стрелки',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ),
              if (!review)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.keyboard_double_arrow_up,
                        size: 15,
                        color: AppColors.muted,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Листай вверх — открывай новое',
                        style: TextStyle(color: AppColors.muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
