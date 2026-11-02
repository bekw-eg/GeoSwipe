import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:geoswipe/data/progress_repository.dart';

class MemoryProgressStore implements ProgressStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String v) async => value = v;
}

void main() {
  group('PostgresApiProgressStore', () {
    test('falls back to local store when token is null', () async {
      final local = MemoryProgressStore()..value = '{"version":1,"levels":{}}';
      final store = PostgresApiProgressStore(
        baseUrl: 'http://localhost:4000',
        token: null,
        localFallback: local,
      );

      final result = await store.read();
      expect(result, '{"version":1,"levels":{}}');
    });

    test('reads from remote PostgreSQL API and updates local cache', () async {
      final local = MemoryProgressStore();
      final client = MockClient((request) async {
        expect(request.url.path, '/api/progress');
        expect(request.headers['Authorization'], 'Bearer test-jwt-token');
        return http.Response(
          jsonEncode({
            'version': 1,
            'lastLevelId': 'angle-45',
            'levels': {
              'angle-45': {
                'attempts': 3,
                'completions': 3,
                'assistedCompletions': 0,
                'independentCompletions': 3,
                'independentReviews': 1,
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final store = PostgresApiProgressStore(
        baseUrl: 'http://localhost:4000',
        token: 'test-jwt-token',
        localFallback: local,
        client: client,
      );

      final result = await store.read();
      expect(result, isNotNull);
      expect(jsonDecode(result!)['lastLevelId'], 'angle-45');
      // Local cache was also updated
      expect(local.value, result);
    });

    test(
      'falls back to local store if remote API fails or is offline',
      () async {
        final local = MemoryProgressStore()
          ..value = '{"version":1,"lastLevelId":"local-level"}';
        final client = MockClient((request) async {
          return http.Response('Server error', 500);
        });

        final store = PostgresApiProgressStore(
          baseUrl: 'http://localhost:4000',
          token: 'test-jwt-token',
          localFallback: local,
          client: client,
        );

        final result = await store.read();
        expect(result, '{"version":1,"lastLevelId":"local-level"}');
      },
    );

    test(
      'write updates local store and syncs to remote PostgreSQL API',
      () async {
        final local = MemoryProgressStore();
        var putCalled = false;

        final client = MockClient((request) async {
          if (request.method == 'PUT' && request.url.path == '/api/progress') {
            putCalled = true;
            expect(request.headers['Authorization'], 'Bearer test-jwt-token');
            expect(request.body, contains('angle-90'));
            return http.Response('{"success":true}', 200);
          }
          return http.Response('Not found', 404);
        });

        final store = PostgresApiProgressStore(
          baseUrl: 'http://localhost:4000',
          token: 'test-jwt-token',
          localFallback: local,
          client: client,
        );

        await store.write('{"version":1,"lastLevelId":"angle-90","levels":{}}');

        expect(local.value, contains('angle-90'));
        expect(putCalled, isTrue);
      },
    );

    test('recordAttempt sends attempt to remote API', () async {
      var attemptRecorded = false;
      final client = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/progress/attempt') {
          attemptRecorded = true;
          final body = jsonDecode(request.body);
          expect(body['levelId'], 'angle-45');
          expect(body['correct'], true);
          return http.Response('{"success":true}', 201);
        }
        return http.Response('Bad request', 400);
      });

      final store = PostgresApiProgressStore(
        baseUrl: 'http://localhost:4000',
        token: 'test-jwt-token',
        localFallback: MemoryProgressStore(),
        client: client,
      );

      final success = await store.recordAttempt(
        levelId: 'angle-45',
        topicId: 'angles',
        correct: true,
      );

      expect(success, isTrue);
      expect(attemptRecorded, isTrue);
    });

    test(
      'ProgressRepository works seamlessly with PostgresApiProgressStore',
      () async {
        final local = MemoryProgressStore();
        final client = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'version': 1,
              'lastLevelId': 'pythagoras-3-4',
              'levels': {
                'pythagoras-3-4': {
                  'attempts': 1,
                  'completions': 1,
                  'assistedCompletions': 0,
                  'independentCompletions': 1,
                  'independentReviews': 0,
                },
              },
            }),
            200,
          );
        });

        final store = PostgresApiProgressStore(
          baseUrl: 'http://localhost:4000',
          token: 'jwt-token',
          localFallback: local,
          client: client,
        );

        final repo = ProgressRepository(store);
        final snapshot = await repo.load();

        expect(snapshot.lastLevelId, 'pythagoras-3-4');
        expect(snapshot.forLevel('pythagoras-3-4').isCompleted, isTrue);
      },
    );
  });
}
