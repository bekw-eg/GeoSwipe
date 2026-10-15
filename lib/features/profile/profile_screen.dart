import 'package:flutter/material.dart';
import '../../core/app_controller.dart';
import '../../core/theme.dart';
import '../../data/level_catalog.dart';
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
        subtitle: 'Твой путь к математической интуиции.',
      ),
      SurfaceCard(
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5EC8), Color(0xFF3E6B9D)],
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.text,
                size: 29,
              ),
            ),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Исследователь',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 7),
                  const Tag(
                    'На своём устройстве',
                    color: AppColors.mint,
                    icon: Icons.offline_bolt_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 25),
      LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Stat(
              width: (constraints.maxWidth - 12) / 2,
              value: '${controller.completedCount}',
              label: 'Уровней решено',
              icon: Icons.check_circle_outline,
              color: AppColors.violet,
            ),
            _Stat(
              width: (constraints.maxWidth - 12) / 2,
              value: '${controller.masteredCount}',
              label: 'Навыков освоено',
              icon: Icons.verified_outlined,
              color: AppColors.mint,
            ),
            _Stat(
              width: (constraints.maxWidth - 12) / 2,
              value: '${controller.totalAttempts}',
              label: 'Всего проверок',
              icon: Icons.touch_app_outlined,
              color: AppColors.blue,
            ),
            _Stat(
              width: (constraints.maxWidth - 12) / 2,
              value: controller.totalAttempts == 0
                  ? '—'
                  : '${(controller.totalCorrect / controller.totalAttempts * 100).round()}%',
              label: 'Верных проверок',
              icon: Icons.track_changes,
              color: AppColors.warning,
            ),
          ],
        ),
      ),
      const SizedBox(height: 27),
      Text('Как растёт навык', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProgressRow(
              label: 'Решено',
              value: '${controller.completedCount} из ${levels.length}',
              color: AppColors.violet,
            ),
            const SizedBox(height: 13),
            ProgressLine(
              value: controller.completedCount / levels.length,
              color: AppColors.violet,
            ),
            const SizedBox(height: 22),
            _ProgressRow(
              label: 'Пока только с подсказкой',
              value: '${controller.assistedCount}',
              color: AppColors.warning,
            ),
            const SizedBox(height: 18),
            _ProgressRow(
              label: 'Освоено самостоятельно',
              value: '${controller.masteredCount}',
              color: AppColors.mint,
            ),
            const SizedBox(height: 17),
            const Text(
              'Освоение — минимум два самостоятельных решения, одно из них в повторении. Подсказка помогает пройти уровень, но не подтверждает освоение.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      SurfaceCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 20,
              color: AppColors.muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.hasLoadError
                    ? 'Не удалось прочитать сохранение. Исходные данные сохранены. Сейчас доступна игра без сохранения.'
                    : controller.hasSaveError
                    ? 'Последние изменения пока не сохранены. Повтори сохранение с помощью сообщения вверху.'
                    : 'Прогресс хранится только здесь. Играй без интернета и регистрации. Удаление данных приложения удалит прогресс.',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.width,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  final double width;
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
