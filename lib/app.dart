import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/app_controller.dart';
import 'core/auth_provider.dart';
import 'core/geo_provider.dart';
import 'core/theme.dart';
import 'data/progress_repository.dart';
import 'services/auth_service.dart';
import 'services/geo_service.dart';
import 'features/auth/auth_screen.dart';
import 'features/geo/geo_screen.dart';
import 'features/learning/learning_screen.dart';
import 'features/play/play_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/review/review_screen.dart';
import 'widgets/common.dart';

class GeoSwipeApp extends StatefulWidget {
  const GeoSwipeApp({
    super.key,
    this.controller,
    this.authProvider,
    this.geoProvider,
  });

  final AppController? controller;
  final AuthProvider? authProvider;
  final GeoProvider? geoProvider;

  @override
  State<GeoSwipeApp> createState() => _GeoSwipeAppState();
}

class _GeoSwipeAppState extends State<GeoSwipeApp> {
  late final AppController _controller =
      widget.controller ??
      AppController(ProgressRepository(PreferencesProgressStore()));

  late final AuthProvider _authProvider =
      widget.authProvider ??
      (widget.controller != null
          ? (AuthProvider(authService: AuthService.inMemory())
              ..continueAsGuest())
          : AuthProvider());

  late final GeoProvider _geoProvider =
      widget.geoProvider ??
      (widget.controller != null
          ? GeoProvider(
              geoService: MockGeoService(
                initialStatus: GeoPermissionStatus.granted,
              ),
            )
          : GeoProvider());

  @override
  void initState() {
    super.initState();
    if (_controller.isLoading) _controller.load();

    if (widget.authProvider == null && widget.controller == null) {
      _authProvider.init();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.authProvider == null) _authProvider.dispose();
    if (widget.geoProvider == null) _geoProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<GeoProvider>.value(value: _geoProvider),
        ChangeNotifierProvider<AppController>.value(value: _controller),
      ],
      child: MaterialApp(
        title: 'GeoSwipe',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('kk')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Auth Gate (Step 16)
            if (!auth.isAuthenticated && !auth.isGuest) {
              return const AuthScreen();
            }

            return ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => _Home(controller: _controller),
            );
          },
        ),
      ),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final geo = context.watch<GeoProvider>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              children: [
                _BrandHeader(auth: auth, geo: geo),
                if (auth.isGuest)
                  Container(
                    margin: const EdgeInsets.fromLTRB(22, 0, 22, 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.blue.withValues(alpha: .3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.blue,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Қонақ режимі: прогресті бұлтқа сақтау үшін тіркеліңіз.',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => auth.logout(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Кіру',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                          index: controller.tab.clamp(0, 4),
                          children: [
                            PlayScreen(
                              key: ValueKey(controller.playRevision),
                              controller: controller,
                            ),
                            LearningScreen(controller: controller),
                            ReviewScreen(controller: controller),
                            ProfileScreen(controller: controller),
                            const GeoScreen(),
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
                selectedIndex: controller.tab.clamp(0, 4),
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
                  NavigationDestination(
                    icon: Icon(Icons.explore_outlined),
                    selectedIcon: Icon(Icons.explore_rounded),
                    label: 'Гео-карта',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.auth, required this.geo});

  final AuthProvider auth;
  final GeoProvider geo;

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
        Tag(
          auth.isAuthenticated
              ? (auth.currentUser?.displayName.split(' ').first ?? 'Профиль')
              : 'Офлайн',
          icon: auth.isAuthenticated
              ? Icons.account_circle_outlined
              : Icons.offline_bolt_outlined,
          color: AppColors.mint,
        ),
      ],
    ),
  );
}
