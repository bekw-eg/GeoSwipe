import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoswipe/app.dart';
import 'package:geoswipe/core/app_controller.dart';
import 'package:geoswipe/core/auth_provider.dart';
import 'package:geoswipe/data/progress_repository.dart';
import 'package:geoswipe/services/auth_service.dart';
import 'support/memory_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryAuthStore memoryAuthStore;
  late AuthService authService;
  late AuthProvider authProvider;
  late AppController controller;

  setUp(() async {
    memoryAuthStore = MemoryAuthStore();
    authService = AuthService(store: memoryAuthStore);
    authProvider = AuthProvider(authService: authService);
    controller = AppController(ProgressRepository(MemoryStore()));
    await controller.load();
  });

  tearDown(() {
    authProvider.dispose();
    controller.dispose();
  });

  Future<void> launch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      GeoSwipeApp(controller: controller, authProvider: authProvider),
    );
    await tester.pumpAndSettle();
  }

  group('Практикалық жұмыс №6: Тіркелу, Кіру, Сессия және Валидация тестілері', () {
    testWidgets('1-2. Тіркелу формасындағы өрістерді тексеру (Validation)', (
      tester,
    ) async {
      await authProvider.init();
      await launch(tester);

      // Should be on AuthScreen because unauthenticated
      expect(find.byKey(const Key('auth_tab_register')), findsOneWidget);

      // Switch to Register tab
      await tester.tap(find.byKey(const Key('auth_tab_register')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_submit_button')), findsOneWidget);

      // Tap register with empty fields
      await tester.ensureVisible(
        find.byKey(const Key('register_submit_button')),
      );
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      // Validation errors must be displayed
      expect(find.text('Аты-жөніңізді енгізіңіз'), findsOneWidget);
      expect(find.text('Пайдаланушы атын енгізіңіз'), findsOneWidget);
      expect(find.text('Электрондық поштаны енгізіңіз'), findsOneWidget);
      expect(find.text('Құпиясөзді енгізіңіз'), findsOneWidget);

      // Enter invalid email format
      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        'invalid-email',
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Жарамды email адресін көрсетіңіз (мысалы: user@example.com)',
        ),
        findsOneWidget,
      );

      // Enter short password
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        '123',
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Құпиясөз кемінде 6 таңбадан тұруы керек'),
        findsOneWidget,
      );

      // Enter mismatched confirm password
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        'secret123',
      );
      await tester.enterText(
        find.byKey(const Key('register_confirm_password_field')),
        'secret999',
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Құпиясөздер бір-біріне сәйкес келмейді'),
        findsOneWidget,
      );

      // Enter all valid fields
      await tester.enterText(
        find.byKey(const Key('register_display_name_field')),
        'Асқар Жұмаділов',
      );
      await tester.enterText(
        find.byKey(const Key('register_username_field')),
        'askar_geo',
      );
      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        'askar@geoswipe.kz',
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('register_confirm_password_field')),
        'password123',
      );
      await tester.pumpAndSettle();

      // Submit registration
      await tester.ensureVisible(
        find.byKey(const Key('register_submit_button')),
      );
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      // After successful registration, user is authenticated and main screen opens
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.displayName, 'Асқар Жұмаділов');
      expect(authProvider.currentUser?.username, 'askar_geo');
      expect(find.text('Играть'), findsOneWidget);
    });

    testWidgets(
      '3-4. Кіру (Login) функциясы және қате енгізгенде хабарлама шығуы',
      (tester) async {
        await authProvider.init();
        await launch(tester);

        // We are on Login tab
        expect(find.byKey(const Key('login_submit_button')), findsOneWidget);

        // Tap submit with empty fields
        await tester.ensureVisible(
          find.byKey(const Key('login_submit_button')),
        );
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pumpAndSettle();

        expect(find.text('Логин немесе email енгізіңіз'), findsOneWidget);
        expect(find.text('Құпиясөзді енгізіңіз'), findsOneWidget);

        // Enter wrong credentials
        await tester.enterText(
          find.byKey(const Key('login_identifier_field')),
          'wrong_user',
        );
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          'wrong_password',
        );
        await tester.ensureVisible(
          find.byKey(const Key('login_submit_button')),
        );
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pumpAndSettle();

        // Error banner and snackbar must be shown
        expect(find.byKey(const Key('login_error_banner')), findsOneWidget);
        expect(
          find.text('Қате логин немесе құпиясөз енгізілді. Қайталап көріңіз.'),
          findsAtLeastNWidgets(1),
        );
        expect(authProvider.isAuthenticated, isFalse);

        // Quick Demo Fill button
        await tester.ensureVisible(
          find.byKey(const Key('login_demo_fill_button')),
        );
        await tester.tap(find.byKey(const Key('login_demo_fill_button')));
        await tester.pumpAndSettle();

        // Submit valid demo login
        await tester.ensureVisible(
          find.byKey(const Key('login_submit_button')),
        );
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pumpAndSettle();

        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.currentUser?.username, 'student');
        expect(find.text('Играть'), findsOneWidget);
      },
    );

    testWidgets(
      '5-6. Сессияны сақтау және қосымшаны қайта қосқанда сессияны қалпына келтіру',
      (tester) async {
        // 1. First session: register user
        final registered = await authService.register(
          email: 'saved_user@geoswipe.kz',
          username: 'saved_user',
          password: 'password123',
          displayName: 'Сақталған Ойыншы',
        );
        expect(registered.token, isNotEmpty);

        // Verify session was persisted in store
        final rawSession = await memoryAuthStore.getString(
          AuthService.sessionKey,
        );
        expect(rawSession, isNotNull);
        expect(rawSession, contains('saved_user@geoswipe.kz'));

        // 2. Simulate App Restart: new AuthProvider instance reading the same store
        final restartedAuthProvider = AuthProvider(
          authService: AuthService(store: memoryAuthStore),
        );

        // Before init: initial
        expect(restartedAuthProvider.isAuthenticated, isFalse);

        // Check session on restart
        await restartedAuthProvider.init();

        // User must be restored immediately into authenticated state!
        expect(restartedAuthProvider.isAuthenticated, isTrue);
        expect(
          restartedAuthProvider.currentUser?.email,
          'saved_user@geoswipe.kz',
        );
        expect(
          restartedAuthProvider.currentUser?.displayName,
          'Сақталған Ойыншы',
        );

        restartedAuthProvider.dispose();
      },
    );

    testWidgets('7-8. Профиль экраны және Жүйеден шығу (Logout) функциясы', (
      tester,
    ) async {
      // Login first
      await authProvider.login(identifier: 'student', password: 'student123');
      expect(authProvider.isAuthenticated, isTrue);

      await launch(tester);

      // Navigate to Profile tab (Index 3)
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();

      // Profile details must show authenticated user data
      expect(find.byKey(const Key('profile_identity_card')), findsOneWidget);
      expect(find.text('Геометрия Студенті'), findsOneWidget);
      expect(find.text('@student • student@geoswipe.kz'), findsOneWidget);

      // Logout button test
      await tester.ensureVisible(
        find.byKey(const Key('profile_logout_button')),
      );
      expect(find.byKey(const Key('profile_logout_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('profile_logout_button')));
      await tester.pumpAndSettle();

      // Confirmation dialog opens
      expect(find.text('Жүйеден шығу (Выйти)'), findsOneWidget);
      expect(find.byKey(const Key('confirm_logout_button')), findsOneWidget);

      // Confirm logout
      await tester.tap(find.byKey(const Key('confirm_logout_button')));
      await tester.pumpAndSettle();

      // User is now unauthenticated and redirected to AuthScreen
      expect(authProvider.isAuthenticated, isFalse);
      expect(find.byKey(const Key('auth_tab_login')), findsOneWidget);

      // Persisted session in store must be removed
      final sessionInStore = await memoryAuthStore.getString(
        AuthService.sessionKey,
      );
      expect(sessionInStore, isNull);
    });

    testWidgets(
      '16. Авторизацияланған және авторизацияланбаған пайдаланушыларға қолжетімділік (Auth Gate)',
      (tester) async {
        await authProvider.init();
        await launch(tester);

        // 1. Unauthenticated: AuthScreen is shown, main game tabs are NOT accessible directly
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.byKey(const Key('auth_tab_login')), findsOneWidget);

        // 2. Tap continue as guest
        await tester.ensureVisible(find.byKey(const Key('auth_guest_button')));
        await tester.tap(find.byKey(const Key('auth_guest_button')));
        await tester.pumpAndSettle();

        // Guest has restricted access, can play but has guest warning
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(
          find.text('Қонақ режимі: прогресті бұлтқа сақтау үшін тіркеліңіз.'),
          findsOneWidget,
        );
      },
    );
  });
}
