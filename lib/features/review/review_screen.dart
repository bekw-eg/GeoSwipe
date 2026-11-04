import 'package:flutter/material.dart';
import '../../core/app_controller.dart';
import '../../core/theme.dart';
import '../../data/level_catalog.dart';
import '../../models/learning_progress.dart';
import '../../widgets/common.dart';
import '../play/puzzle_card.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key, required this.controller});
  final AppController controller;
  String _dueLabel(String id) {
    final skill = controller.progress.forSkill(id);
    final due = skill.dueAt?.toLocal();
    if (due == null) return 'Срок ещё не назначен';
    if (skill.isDue(controller.now)) return 'Пора повторить';
    return 'Повторить: ${due.day.toString().padLeft(2, '0')}.${due.month.toString().padLeft(2, '0')}.${due.year} ${due.hour.toString().padLeft(2, '0')}:${due.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final current = controller.reviewLevel;
    if (current != null) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: controller.closeReview,
              icon: const Icon(Icons.arrow_back, size: 17),
              label: const Text('Все задачи'),
            ),
          ),
          Expanded(
            child: PuzzleCard(
              key: ValueKey(controller.reviewRevision),
              controller: controller,
              level: current,
              number: levels.indexWhere((l) => l.id == current.id) + 1,
              total: levels.length,
              onNext: controller.closeReview,
              review: true,
            ),
          ),
        ],
      );
    }
    final completed = controller.completedLevels;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
      children: [
        const ScreenHeading(
          eyebrow: 'От знания к навыку',
          title: 'Повторение',
          subtitle: 'Знакомая задача. Новая уверенность.',
        ),
        if (completed.isEmpty)
          EmptyState(
            icon: Icons.replay_rounded,
            title: 'Здесь появятся твои задачи',
            description:
                'Реши первый уровень — и сможешь вернуться к нему, чтобы закрепить навык.',
            action: 'К первому открытию',
            onAction: () => controller.openLevel(0),
          )
        else ...[
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Tag(
                  'ТВОЯ ПРАКТИКА',
                  color: AppColors.mint,
                  icon: Icons.bolt_outlined,
                ),
                const SizedBox(height: 16),
                Text(
                  'К повторению: ${controller.dueLevels.length}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Повторяем через 1, 3 и 7 дней. Новые данные проверяют тот же принцип. Ранняя тренировка доступна, но не продвигает расписание.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => controller.startReview(),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      controller.dueLevels.isEmpty
                          ? 'Тренироваться заранее'
                          : 'Начать повторение',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Знакомые задачи · ${completed.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 13),
          for (final level in completed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  leading: Icon(
                    controller.skill(level).state == SkillState.confirmed
                        ? Icons.verified_outlined
                        : Icons.rotate_right,
                    color: AppColors.mint,
                  ),
                  title: Text(
                    level.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${controller.skill(level).state.label}\n${_dueLabel(level.id)}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => controller.startReview(levelId: level.id),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
