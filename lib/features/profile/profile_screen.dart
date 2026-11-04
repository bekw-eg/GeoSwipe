import 'package:flutter/material.dart';
import '../../core/app_controller.dart';
import '../../core/theme.dart';
import '../../data/level_catalog.dart';
import '../../models/learning_progress.dart';
import '../../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
    children: [
      const ScreenHeading(
        eyebrow: 'Каждый шаг считается',
        title: 'Твой профиль',
        subtitle: 'Результаты твоих решений на этом устройстве.',
      ),
      SurfaceCard(
        child: Column(
          children: [
            _Metric(
              'Уровней решено',
              '${controller.completedCount} из ${levels.length}',
            ),
            _Metric('Навыков освоено', '${controller.masteredCount}'),
            _Metric('Заданий без подсказок', '${controller.independentCount}'),
            _Metric('Всего проверок', '${controller.totalAttempts}'),
            _Metric('Задач к повторению', '${controller.dueLevels.length}'),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text('Ошибки по темам', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      SurfaceCard(
        child: Column(
          children: [
            for (final topic in topics)
              _Metric(topic.title, '${controller.errorsByTopic[topic.id]}'),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Задачи для повторения',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.dueLevels.isEmpty)
              Text(
                controller.completedCount == 0
                    ? 'На сейчас повторений нет. Расписание появится после решения уровня.'
                    : 'На сейчас повторений нет. Будущие задания доступны в расписании.',
              )
            else
              for (final level in controller.dueLevels)
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(level.title),
                    subtitle: Text(controller.skill(level).state.label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => controller.startReview(levelId: level.id),
                  ),
                ),
            TextButton(
              onPressed: () => controller.selectTab(2),
              child: const Text('Расписание и тренировка'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text('Состояния навыков', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      SurfaceCard(
        child: Column(
          children: [
            for (final state in SkillState.values)
              _Metric(
                state.label,
                '${levels.where((l) => controller.skill(l).state == state).length}',
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const SurfaceCard(
        child: Text(
          'Уровень считается решённым после первой верной проверки. '
          'Задания без подсказок — уникальные уровни хотя бы с одним самостоятельным решением. '
          'Ошибка — каждая неверная проверка. Освоение — три самостоятельных повторения '
          'после сроков 1, 3 и 7 дней. Подсказки и ранняя тренировка не подтверждают освоение. '
          'После ошибки стадия повторения снижается. Старые сохранения учитываются в счётчиках; '
          'даты и подробная история доступны только для новых попыток.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ),
      const SizedBox(height: 16),
      SurfaceCard(
        child: Text(
          controller.hasLoadError
              ? 'Сохранение не прочитано. Исходные данные сохранены, новые результаты пока не записываются.'
              : controller.hasSaveError
              ? 'Последние изменения пока не сохранены. Повтори сохранение кнопкой вверху.'
              : 'Прогресс хранится на устройстве и доступен после перезапуска. Удаление данных приложения удалит прогресс.',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.mint,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
