import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_controller.dart';
import '../../core/auth_provider.dart';
import '../../core/geo_provider.dart';
import '../../core/theme.dart';
import '../../data/level_catalog.dart';
import '../../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});

  final AppController controller;

  void _showEditProfileDialog(BuildContext context, AuthProvider auth) {
    final nameController = TextEditingController(
      text: auth.currentUser?.displayName ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Профильді өңдеу (Редактировать)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('edit_display_name_field'),
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Аты-жөні (Имя)',
                filled: true,
                fillColor: AppColors.elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Бас тарту'),
          ),
          FilledButton(
            key: const Key('save_profile_button'),
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await auth.updateDisplayName(nameController.text.trim());
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Сақтау'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Жүйеден шығу (Выйти)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Шынымен жүйеден шыққыңыз келе ме? Жергілікті сақталған прогресіңіз құрылғыда қалады.',
          style: TextStyle(color: AppColors.text, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Жоқ, қалу'),
          ),
          FilledButton(
            key: const Key('confirm_logout_button'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent.shade700,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
            },
            child: const Text('Иә, шығу'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AuthProvider? auth;
    GeoProvider? geo;
    try {
      auth = context.watch<AuthProvider>();
    } catch (_) {}
    try {
      geo = context.watch<GeoProvider>();
    } catch (_) {}

    final user = auth?.currentUser;
    final isGuest = auth?.isGuest ?? true;

    return ListView(
      key: const Key('profile_screen_list_view'),
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
      children: [
        const ScreenHeading(
          eyebrow: 'Каждый шаг считается',
          title: 'Твой профиль',
          subtitle: 'Твой путь к математической интуиции.',
        ),

        // User Identity Card
        SurfaceCard(
          key: const Key('profile_identity_card'),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        colors: isGuest
                            ? [const Color(0xFF6C5EC8), const Color(0xFF3E6B9D)]
                            : [
                                const Color(0xFF6C5EC8),
                                const Color(0xFF3E6B9D),
                              ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isGuest
                          ? 'И'
                          : (user != null && user.displayName.isNotEmpty
                                ? user.displayName.substring(0, 1).toUpperCase()
                                : 'U'),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 17),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isGuest
                                    ? 'Исследователь'
                                    : (user?.displayName ?? 'Исследователь'),
                                style: Theme.of(context).textTheme.titleLarge,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isGuest && user != null && auth != null) ...[
                              const SizedBox(width: 6),
                              IconButton(
                                key: const Key('edit_profile_icon_button'),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: AppColors.muted,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () =>
                                    _showEditProfileDialog(context, auth!),
                              ),
                            ],
                          ],
                        ),
                        if (!isGuest && user != null) ...[
                          Text(
                            '@${user.username} • ${user.email}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                        ],
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Tag(
                              isGuest
                                  ? 'На своём устройстве'
                                  : 'Тіркелген аккаунт',
                              color: AppColors.mint,
                              icon: Icons.offline_bolt_outlined,
                            ),
                            if (!isGuest &&
                                user != null &&
                                user.geoBonusPoints > 0)
                              Tag(
                                '+${user.geoBonusPoints} ұпай',
                                color: AppColors.violet,
                                icon: Icons.stars_rounded,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Action buttons inside identity card
              if (auth != null) ...[
                const SizedBox(height: 16),
                const Divider(color: AppColors.line, height: 1),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (isGuest)
                        OutlinedButton.icon(
                          key: const Key('guest_switch_to_auth_button'),
                          onPressed: () async {
                            await auth!.logout();
                          },
                          icon: const Icon(Icons.login_rounded, size: 16),
                          label: const Text('Тіркелу / Кіру'),
                        )
                      else
                        const Tag(
                          'Сессия белсенді',
                          color: AppColors.mint,
                          icon: Icons.cloud_done_outlined,
                        ),
                      TextButton.icon(
                        key: const Key('profile_logout_button'),
                        onPressed: () =>
                            _showLogoutConfirmation(context, auth!),
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                        label: const Text(
                          'Шығу',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Unlocked Badges / Geo-status section
        if (!isGuest && user != null && user.unlockedBadges.isNotEmpty) ...[
          const SizedBox(height: 20),
          SurfaceCard(
            key: const Key('profile_badges_card'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.military_tech_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Ашылған гео-марапаттар',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final badge in user.unlockedBadges)
                      Tag(
                        badge,
                        color: AppColors.violet,
                        icon: Icons.workspace_premium_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 25),

        // Real Stats Grid (matches test/app_test.dart expectations)
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
        Text(
          'Как растёт навык',
          style: Theme.of(context).textTheme.titleMedium,
        ),
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

        // Device & GPS connection status
        Builder(
          builder: (context) {
            final coords = geo?.coordinates;
            return SurfaceCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    coords != null
                        ? Icons.location_on_outlined
                        : Icons.cloud_off_outlined,
                    size: 20,
                    color: coords != null ? AppColors.mint : AppColors.muted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      coords != null
                          ? 'GPS геолокация байланыстырылды: ${coords.latitude.toStringAsFixed(2)}°N, ${coords.longitude.toStringAsFixed(2)}°E (${geo?.nearestLandmark?.name ?? ""})'
                          : controller.hasLoadError
                          ? 'Не удалось прочитать сохранение. Исходные данные сохранены. Сейчас доступна игра без сохранения.'
                          : controller.hasSaveError
                          ? 'Последние изменения пока не сохранены. Повтори сохранение с помощью сообщения вверху.'
                          : 'Прогресс хранится только здесь. Играй без интернета и регистрации. Удаление данных приложения удалит прогресс.',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
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
