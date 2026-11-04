import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_controller.dart';
import 'core/theme.dart';
import 'data/progress_repository.dart';
import 'features/learning/learning_screen.dart';
import 'features/play/play_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/review/review_screen.dart';
import 'widgets/common.dart';

class GeoSwipeApp extends StatefulWidget {
  const GeoSwipeApp({super.key, this.controller});
  final AppController? controller;
  @override
  State<GeoSwipeApp> createState() => _GeoSwipeAppState();
}

class _GeoSwipeAppState extends State<GeoSwipeApp> with WidgetsBindingObserver {
  late final AppController _controller =
      widget.controller ??
      AppController(ProgressRepository(PreferencesProgressStore()));
  Timer? _dueTimer;

  void _scheduleRefresh() {
    _dueTimer?.cancel();
    final now = _controller.now;
    final upcoming =
        _controller.progress.skills.values
            .map((skill) => skill.dueAt)
            .whereType<DateTime>()
            .where((due) => due.isAfter(now))
            .toList()
          ..sort();
    if (upcoming.isNotEmpty) {
      _dueTimer = Timer(
        upcoming.first.difference(now),
        _controller.refreshTime,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_scheduleRefresh);
    _scheduleRefresh();
    if (_controller.isLoading) _controller.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_scheduleRefresh);
    _dueTimer?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.refreshTime();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'GeoSwipe',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    locale: const Locale('ru'),
    supportedLocales: const [Locale('ru')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => _Home(controller: _controller),
    ),
  );
}

class _Home extends StatelessWidget {
  const _Home({required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            children: [
              const _BrandHeader(),
              if (controller.hasLoadError || controller.hasSaveError)
                Container(
                  margin: const EdgeInsets.fromLTRB(22, 0, 22, 10),
                  padding: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          controller.hasLoadError
                              ? 'Сохранение недоступно. Игра без записи.'
                              : 'Изменения пока не сохранены.',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: controller.hasLoadError
                            ? controller.load
                            : controller.persist,
                        child: const Text(
                          'Повторить',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : IndexedStack(
                        index: controller.tab,
                        children: [
                          PlayScreen(
                            key: ValueKey(controller.playRevision),
                            controller: controller,
                          ),
                          LearningScreen(controller: controller),
                          ReviewScreen(controller: controller),
                          ProfileScreen(controller: controller),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: NavigationBar(
              height: 72,
              selectedIndex: controller.tab,
              onDestinationSelected: controller.isLoading
                  ? null
                  : controller.selectTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.play_arrow_outlined),
                  selectedIcon: Icon(Icons.play_arrow_rounded),
                  label: 'Играть',
                ),
                NavigationDestination(
                  icon: Icon(Icons.route_outlined),
                  selectedIcon: Icon(Icons.route),
                  label: 'Карта обучения',
                ),
                NavigationDestination(
                  icon: Icon(Icons.replay_outlined),
                  label: 'Повторение',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Профиль',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 17, 22, 22),
    child: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.violet.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.change_history_rounded,
            size: 23,
            color: AppColors.violet,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  text: 'Geo',
                  children: [
                    TextSpan(
                      text: 'Swipe',
                      style: TextStyle(color: AppColors.violet),
                    ),
                  ],
                ),
                maxLines: 1,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.7,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Tag(
          'Офлайн',
          icon: Icons.offline_bolt_outlined,
          color: AppColors.mint,
        ),
      ],
    ),
  );
}
