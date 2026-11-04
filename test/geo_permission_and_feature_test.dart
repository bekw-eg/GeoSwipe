import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoswipe/app.dart';
import 'package:geoswipe/core/app_controller.dart';
import 'package:geoswipe/core/auth_provider.dart';
import 'package:geoswipe/core/geo_provider.dart';
import 'package:geoswipe/data/progress_repository.dart';
import 'package:geoswipe/models/geo_landmark.dart';
import 'package:geoswipe/services/auth_service.dart';
import 'package:geoswipe/services/geo_service.dart';
import 'support/memory_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryAuthStore memoryAuthStore;
  late AuthService authService;
  late AuthProvider authProvider;
  late AppController controller;
  late MockGeoService mockGeoService;
  late GeoProvider geoProvider;

  setUp(() async {
    memoryAuthStore = MemoryAuthStore();
    authService = AuthService(store: memoryAuthStore);
    authProvider = AuthProvider(authService: authService);
    controller = AppController(ProgressRepository(MemoryStore()));
    await controller.load();

    mockGeoService = MockGeoService(
      serviceEnabled: true,
      initialStatus: GeoPermissionStatus.notRequested,
    );
    geoProvider = GeoProvider(geoService: mockGeoService);
  });

  tearDown(() {
    authProvider.dispose();
    geoProvider.dispose();
    controller.dispose();
  });

  Future<void> launch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      GeoSwipeApp(
        controller: controller,
        authProvider: authProvider,
        geoProvider: geoProvider,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Практикалық жұмыс №6: Геолокация, Permission және Бизнес-логика', () {
    test('11-12. Математикалық қашықтықты есептеу (Haversine formula)', () {
      // Coordinates of Bayterek, Astana (51.1283, 71.4305)
      const userLat = 51.1283;
      const userLng = 71.4305;

      final bayterek = kGeometricLandmarks.firstWhere(
        (l) => l.id == 'bayterek-tower',
      );
      final distToBayterek = bayterek.distanceTo(userLat, userLng);
      // Same point distance should be 0 km
      expect(distToBayterek, closeTo(0.0, 0.01));

      // Distance from Bayterek to Nur Alem Sphere (51.0899, 71.4172) ~ 4.4 km
      final sphere = kGeometricLandmarks.firstWhere(
        (l) => l.id == 'nur-alem-sphere',
      );
      final distToSphere = sphere.distanceTo(userLat, userLng);
      expect(distToSphere, greaterThan(4.0));
      expect(distToSphere, lessThan(5.0));
      expect(sphere.formatDistanceTo(userLat, userLng), contains('км'));
    });

    testWidgets('13, 15. Permission: Not Requested күйі және сұрау жасау', (
      tester,
    ) async {
      authProvider.continueAsGuest();
      mockGeoService.setStatus(GeoPermissionStatus.notRequested);

      await launch(tester);

      // Navigate to Geo-Quest tab (Index 4)
      await tester.tap(find.text('Гео-карта'));
      await tester.pumpAndSettle();

      // Permission Not Requested card must be displayed
      expect(
        find.byKey(const Key('geo_permission_not_requested_card')),
        findsOneWidget,
      );
      expect(find.text('Геолокация рұқсаты қажет'), findsOneWidget);
      expect(
        find.byKey(const Key('geo_request_permission_button')),
        findsOneWidget,
      );

      // Tap request permission
      await tester.tap(find.byKey(const Key('geo_request_permission_button')));
      await tester.pumpAndSettle();

      // State transitions to granted
      expect(geoProvider.status, GeoPermissionStatus.granted);
      expect(
        find.byKey(const Key('geo_live_coordinates_card')),
        findsOneWidget,
      );
    });

    testWidgets('15. Permission: Denied (Бас тартылған) күйін өңдеу', (
      tester,
    ) async {
      authProvider.continueAsGuest();
      mockGeoService.setStatus(GeoPermissionStatus.denied);

      await launch(tester);

      // Navigate to Geo-Quest tab
      await tester.tap(find.text('Гео-карта'));
      await tester.pumpAndSettle();

      // Denied card must be displayed
      expect(
        find.byKey(const Key('geo_permission_denied_card')),
        findsOneWidget,
      );
      expect(find.text('Геолокацияға рұқсат берілмеді'), findsOneWidget);
      expect(
        find.byKey(const Key('geo_retry_permission_button')),
        findsOneWidget,
      );

      // Retrying permission
      await tester.tap(find.byKey(const Key('geo_retry_permission_button')));
      await tester.pumpAndSettle();

      // Permission is granted on retry
      expect(geoProvider.status, GeoPermissionStatus.granted);
      expect(
        find.byKey(const Key('geo_live_coordinates_card')),
        findsOneWidget,
      );
    });

    testWidgets('15. Permission: Denied Forever (Біржола бұғатталған) күйі', (
      tester,
    ) async {
      authProvider.continueAsGuest();
      mockGeoService.setStatus(GeoPermissionStatus.deniedForever);

      await launch(tester);

      await tester.tap(find.text('Гео-карта'));
      await tester.pumpAndSettle();

      // Denied Forever card must be shown
      expect(
        find.byKey(const Key('geo_permission_denied_forever_card')),
        findsOneWidget,
      );
      expect(find.text('Рұқсат біржола бұғатталған'), findsOneWidget);
      expect(
        find.byKey(const Key('geo_open_app_settings_button')),
        findsOneWidget,
      );
    });

    testWidgets('15. Permission: GPS қызметі өшірулі (Service Disabled) күйі', (
      tester,
    ) async {
      authProvider.continueAsGuest();
      mockGeoService.serviceEnabled = false;

      await launch(tester);

      await tester.tap(find.text('Гео-карта'));
      await tester.pumpAndSettle();

      // GPS disabled card must be shown
      expect(
        find.byKey(const Key('geo_service_disabled_card')),
        findsOneWidget,
      );
      expect(find.text('GPS қызметі өшірулі'), findsOneWidget);
      expect(find.byKey(const Key('geo_open_settings_button')), findsOneWidget);
    });

    testWidgets(
      '14, 17. Permission Granted: Координаттар көрсету және Гео-квест орындау',
      (tester) async {
        // Authenticate user to verify bonus points reward
        await authProvider.login(identifier: 'student', password: 'student123');
        final initialPoints = authProvider.currentUser?.geoBonusPoints ?? 0;

        mockGeoService.setStatus(GeoPermissionStatus.granted);
        await geoProvider.init();

        await launch(tester);

        // Navigate to Geo tab
        await tester.tap(find.text('Гео-карта'));
        await tester.pumpAndSettle();

        // Live Coordinates Card
        expect(
          find.byKey(const Key('geo_live_coordinates_card')),
          findsOneWidget,
        );
        expect(find.text('51.1283° N'), findsOneWidget);
        expect(find.text('71.4305° E'), findsOneWidget);

        // Nearest landmark highlight
        expect(
          find.byKey(const Key('geo_nearest_landmark_card')),
          findsOneWidget,
        );
        expect(find.text('«Бәйтерек» монументі'), findsAtLeastNWidgets(1));

        // Start / Open Geo-quest dialog
        expect(
          find.byKey(const Key('nearest_open_quest_button')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('nearest_open_quest_button')));
        await tester.pumpAndSettle();

        // Dialog with geometric fact and solve button
        expect(find.byKey(const Key('solve_geo_quest_button')), findsOneWidget);
        await tester.tap(find.byKey(const Key('solve_geo_quest_button')));
        await tester.pumpAndSettle();

        // User awarded bonus points and quest completed
        expect(
          geoProvider.completedQuestIds.contains('bayterek-tower'),
          isTrue,
        );
        expect(authProvider.currentUser?.geoBonusPoints, initialPoints + 45);
        expect(
          authProvider.currentUser?.unlockedBadges,
          contains('Гео-зерттеуші: «Бәйтерек» монументі'),
        );

        // Check Profile tab updates with the geo-badge
        await tester.tap(find.text('Профиль'));
        await tester.pumpAndSettle();

        expect(find.text('+45 ұпай'), findsOneWidget);
        expect(
          find.text('Гео-зерттеуші: «Бәйтерек» монументі'),
          findsOneWidget,
        );
      },
    );
  });
}
