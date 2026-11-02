import 'dart:convert';
import 'package:http/http.dart' as http;
import 'progress_repository.dart';

/// Progress store integrating with the PostgreSQL REST API backend
/// while maintaining local offline fallback to ensure offline-first behavior.
class PostgresApiProgressStore implements ProgressStore {
  PostgresApiProgressStore({
    required this.baseUrl,
    this.token,
    ProgressStore? localFallback,
    http.Client? client,
  }) : localStore = localFallback ?? PreferencesProgressStore(),
       _client = client ?? http.Client();

  final String baseUrl;
  String? token;
  final ProgressStore localStore;
  final http.Client _client;

  Uri _uri(String path) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$cleanPath');
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  @override
  Future<String?> read() async {
    // If configured with token and baseUrl, attempt remote fetch from PostgreSQL
    if (token != null && token!.isNotEmpty) {
      try {
        final response = await _client
            .get(_uri('/api/progress'), headers: _headers)
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final body = response.body;
          // Validate JSON structure before caching locally
          final decoded = jsonDecode(body);
          if (decoded is Map<String, dynamic>) {
            // Update local fallback cache
            await localStore.write(body);
            return body;
          }
        }
      } catch (_) {
        // Network timeout / offline / server unreachable: gracefully fall back to local
      }
    }

    // Fallback to local storage (offline-first)
    return localStore.read();
  }

  @override
  Future<void> write(String value) async {
    // Always persist to local store first to ensure zero data loss offline
    await localStore.write(value);

    // Sync to PostgreSQL backend if configured
    if (token != null && token!.isNotEmpty) {
      try {
        await _client
            .put(_uri('/api/progress'), headers: _headers, body: value)
            .timeout(const Duration(seconds: 4));
      } catch (_) {
        // If sync fails due to network, local copy is preserved.
      }
    }
  }

  /// Helper to record an individual attempt to PostgreSQL backend
  Future<bool> recordAttempt({
    required String levelId,
    required String topicId,
    required bool correct,
    int hintCount = 0,
    bool review = false,
    bool scheduledReview = false,
    int variant = 0,
    String answer = '',
  }) async {
    if (token == null || token!.isEmpty) return false;
    try {
      final response = await _client
          .post(
            _uri('/api/progress/attempt'),
            headers: _headers,
            body: jsonEncode({
              'levelId': levelId,
              'topicId': topicId,
              'correct': correct,
              'hintCount': hintCount,
              'review': review,
              'scheduledReview': scheduledReview,
              'variant': variant,
              'answer': answer,
            }),
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
