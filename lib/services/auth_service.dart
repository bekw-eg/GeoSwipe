import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract interface class AuthStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

class SharedPreferencesAuthStore implements AuthStore {
  SharedPreferencesAuthStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

class MemoryAuthStore implements AuthStore {
  MemoryAuthStore([Map<String, String>? initial]) : _data = initial ?? {};
  final Map<String, String> _data;

  @override
  Future<String?> getString(String key) async => _data[key];

  @override
  Future<void> setString(String key, String value) async => _data[key] = value;

  @override
  Future<void> remove(String key) async => _data.remove(key);
}

class AuthService {
  AuthService({String? baseUrl, http.Client? client, AuthStore? store})
    : baseUrl = baseUrl ?? 'http://10.0.2.2:3000',
      _client = client ?? http.Client(),
      _store = store ?? SharedPreferencesAuthStore();

  factory AuthService.inMemory({Map<String, String>? initialData}) =>
      AuthService(store: MemoryAuthStore(initialData));

  final String baseUrl;
  final http.Client _client;
  final AuthStore _store;

  static const String sessionKey = 'geoswipe.auth.session';
  static const String usersKey = 'geoswipe.auth.local_users';

  Uri _uri(String path) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$cleanPath');
  }

  /// Check whether a persistent session exists in storage
  Future<AuthSession?> checkSession() async {
    try {
      final raw = await _store.getString(sessionKey);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return AuthSession.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Register a new user
  Future<AuthSession> register({
    required String email,
    required String username,
    required String password,
    required String displayName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanUsername = username.trim();
    final cleanName = displayName.trim().isEmpty
        ? cleanUsername
        : displayName.trim();

    // 1. Try remote PostgreSQL backend if available
    try {
      final response = await _client
          .post(
            _uri('/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': cleanEmail,
              'username': cleanUsername,
              'password': password,
              'displayName': cleanName,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>;
        final profileData = data['profile'] as Map<String, dynamic>?;

        final user = AuthUser(
          id:
              userData['id']?.toString() ??
              'user_${DateTime.now().millisecondsSinceEpoch}',
          email: userData['email']?.toString() ?? cleanEmail,
          username: userData['username']?.toString() ?? cleanUsername,
          displayName: profileData?['displayName']?.toString() ?? cleanName,
          preferredLanguage:
              profileData?['preferredLanguage']?.toString() ?? 'kk',
          createdAt: DateTime.now(),
        );

        final session = AuthSession(
          token: token,
          user: user,
          savedAt: DateTime.now(),
        );
        await _saveSession(session);
        await _saveLocalUser(cleanEmail, cleanUsername, password, user);
        return session;
      } else if (response.statusCode == 400 || response.statusCode == 409) {
        final err = jsonDecode(response.body);
        throw AuthException(
          err['error']?.toString() ?? 'Тіркелу кезінде қате орын алды',
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      // Network unreachable / server offline -> gracefully register locally
    }

    // 2. Offline-first local registration
    final localUsers = await _getLocalUsers();
    for (final u in localUsers) {
      if (u['email'] == cleanEmail) {
        throw AuthException('Бұл email тіркелген. Басқа email таңдаңыз.');
      }
      if (u['username'] == cleanUsername) {
        throw AuthException('Бұл пайдаланушы аты бос емес.');
      }
    }

    final localUser = AuthUser(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      email: cleanEmail,
      username: cleanUsername,
      displayName: cleanName,
      preferredLanguage: 'kk',
      createdAt: DateTime.now(),
    );

    final localSession = AuthSession(
      token: 'local_token_${DateTime.now().millisecondsSinceEpoch}',
      user: localUser,
      savedAt: DateTime.now(),
    );

    await _saveLocalUser(cleanEmail, cleanUsername, password, localUser);
    await _saveSession(localSession);
    return localSession;
  }

  /// Login existing user
  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async {
    final cleanIdentifier = identifier.trim().toLowerCase();

    // 1. Try remote PostgreSQL backend if available
    try {
      final response = await _client
          .post(
            _uri('/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'identifier': cleanIdentifier,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>;
        final profileData = data['profile'] as Map<String, dynamic>?;

        final user = AuthUser(
          id: userData['id']?.toString() ?? '',
          email: userData['email']?.toString() ?? cleanIdentifier,
          username: userData['username']?.toString() ?? cleanIdentifier,
          displayName:
              profileData?['displayName']?.toString() ?? cleanIdentifier,
          preferredLanguage:
              profileData?['preferredLanguage']?.toString() ?? 'kk',
          createdAt: DateTime.now(),
        );

        final session = AuthSession(
          token: token,
          user: user,
          savedAt: DateTime.now(),
        );
        await _saveSession(session);
        return session;
      } else if (response.statusCode == 401 || response.statusCode == 400) {
        final err = jsonDecode(response.body);
        throw AuthException(
          err['error']?.toString() ?? 'Қате логин немесе құпиясөз',
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      // Network unreachable -> check local users
    }

    // 2. Offline-first local login verification
    final localUsers = await _getLocalUsers();
    final match = localUsers.firstWhere(
      (u) =>
          ((u['email'] as String? ?? '').toLowerCase() == cleanIdentifier ||
              (u['username'] as String? ?? '').toLowerCase() ==
                  cleanIdentifier) &&
          u['password'] == password,
      orElse: () => {},
    );

    if (match.isNotEmpty) {
      final user = AuthUser.fromJson(match['user'] as Map<String, dynamic>);
      final session = AuthSession(
        token: 'local_token_${DateTime.now().millisecondsSinceEpoch}',
        user: user,
        savedAt: DateTime.now(),
      );
      await _saveSession(session);
      return session;
    }

    // Default demo account for instant testing if no users registered yet
    if ((cleanIdentifier == 'student' ||
            cleanIdentifier == 'student@geoswipe.kz') &&
        password == 'student123') {
      final demoUser = AuthUser(
        id: 'demo_student_1',
        email: 'student@geoswipe.kz',
        username: 'student',
        displayName: 'Геометрия Студенті',
        preferredLanguage: 'kk',
        createdAt: DateTime.now(),
      );
      final demoSession = AuthSession(
        token: 'demo_token_123',
        user: demoUser,
        savedAt: DateTime.now(),
      );
      await _saveSession(demoSession);
      return demoSession;
    }

    throw AuthException(
      'Қате логин немесе құпиясөз енгізілді. Қайталап көріңіз.',
    );
  }

  /// Logout and clear stored session
  Future<void> logout() async {
    await _store.remove(sessionKey);
  }

  /// Update user profile
  Future<AuthSession> updateProfile({
    required AuthSession currentSession,
    required String displayName,
  }) async {
    final updatedUser = currentSession.user.copyWith(
      displayName: displayName.trim(),
    );
    final updatedSession = AuthSession(
      token: currentSession.token,
      user: updatedUser,
      savedAt: DateTime.now(),
    );
    await _saveSession(updatedSession);

    // Try remote update if connected
    if (!currentSession.token.startsWith('local_') &&
        !currentSession.token.startsWith('demo_')) {
      try {
        await _client
            .put(
              _uri('/api/profile'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${currentSession.token}',
              },
              body: jsonEncode({'displayName': displayName.trim()}),
            )
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
    }

    return updatedSession;
  }

  /// Award geo-bonus points
  Future<AuthSession> awardGeoPoints(
    AuthSession currentSession,
    int points,
    String badgeName,
  ) async {
    final currentBadges = List<String>.from(currentSession.user.unlockedBadges);
    if (!currentBadges.contains(badgeName)) {
      currentBadges.add(badgeName);
    }
    final updatedUser = currentSession.user.copyWith(
      geoBonusPoints: currentSession.user.geoBonusPoints + points,
      unlockedBadges: currentBadges,
    );
    final updatedSession = AuthSession(
      token: currentSession.token,
      user: updatedUser,
      savedAt: DateTime.now(),
    );
    await _saveSession(updatedSession);
    return updatedSession;
  }

  Future<void> _saveSession(AuthSession session) async {
    await _store.setString(sessionKey, jsonEncode(session.toJson()));
  }

  Future<List<Map<String, dynamic>>> _getLocalUsers() async {
    try {
      final raw = await _store.getString(usersKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw);
      if (list is List) {
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocalUser(
    String email,
    String username,
    String password,
    AuthUser user,
  ) async {
    final users = await _getLocalUsers();
    users.removeWhere((u) => u['email'] == email || u['username'] == username);
    users.add({
      'email': email,
      'username': username,
      'password': password,
      'user': user.toJson(),
    });
    await _store.setString(usersKey, jsonEncode(users));
  }
}
