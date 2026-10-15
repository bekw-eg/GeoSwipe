import 'package:flutter/material.dart';
import '../../core/app_controller.dart';
import '../../core/theme.dart';
import '../../data/level_catalog.dart';
import '../../models/progress.dart';
import '../../widgets/common.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
    children: [
      const ScreenHeading(
        eyebrow: 'Твой маршрут',
        title: 'Карта обучения',
        subtitle: 'Понимай через действие. В своём темпе.',
      ),
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.route_outlined,
                  color: AppColors.mint,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Твой прогресс',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${controller.completedCount} / ${levels.length}',
                  style: const TextStyle(color: AppColors.mint),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ProgressLine(value: controller.completedCount / levels.length),
            const SizedBox(height: 10),
            Text(
              'Освоено самостоятельно: ${controller.masteredCount}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
      const SizedBox(height: 30),
      Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Tag('ГЛАВА 01', color: AppColors.blue),
          Text(
            'Первые открытия',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(topics.first.title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      Text(
        topics.first.description,
        style: const TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 17),
      for (var i = 0; i < levels.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: _LevelTile(
            index: i,
            progress: controller.progress.forLevel(levels[i].id),
            onTap: () => controller.openLevel(i),
          ),
        ),
      const SizedBox(height: 22),
      for (var i = 1; i < topics.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SurfaceCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  i == 1 ? Icons.change_history : Icons.waves,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ГЛАВА 0${i + 1}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 9,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        topics[i].title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topics[i].description,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Tag('Уровней пока нет', color: AppColors.muted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.index,
    required this.progress,
    required this.onTap,
  });
  final int index;
  final LevelProgress progress;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = progress.isMastered
        ? AppColors.mint
        : progress.isAssistedOnly
        ? AppColors.warning
        : AppColors.violet;
    final status = progress.isMastered
        ? 'Освоено'
        : progress.isAssistedOnly
        ? 'С подсказкой'
        : progress.isCompleted
        ? 'Решено · закрепи в повторении'
        : 'Можно начать';
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: progress.isCompleted
                    ? Icon(
                        progress.isMastered
                            ? Icons.verified_outlined
                            : Icons.check,
                        color: color,
                        size: 22,
                      )
                    : Text(
                        '${index + 1}'.padLeft(2, '0'),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      levels[index].title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status,
                      style: TextStyle(
                        color: progress.isCompleted ? color : AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
