import 'package:flutter/foundation.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  AuthStatus _status = AuthStatus.initial;
  AuthSession? _session;
  bool _isGuest = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  AuthUser? get currentUser => _session?.user;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _session != null;
  bool get isGuest => _isGuest;
  bool get isLoading => _status == AuthStatus.loading;
  String? get errorMessage => _errorMessage;

  /// Check persisted session on app startup
  Future<void> init() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final savedSession = await _authService.checkSession();
      if (savedSession != null) {
        _session = savedSession;
        _isGuest = false;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Register a new user
  Future<bool> register({
    required String email,
    required String username,
    required String password,
    required String displayName,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _authService.register(
        email: email,
        username: username,
        password: password,
        displayName: displayName,
      );
      _session = session;
      _isGuest = false;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Login existing user
  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _authService.login(
        identifier: identifier,
        password: password,
      );
      _session = session;
      _isGuest = false;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Continue without registration (guest mode)
  void continueAsGuest() {
    _isGuest = true;
    _session = null;
    _errorMessage = null;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Logout and clear session
  Future<void> logout() async {
    await _authService.logout();
    _session = null;
    _isGuest = false;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Update display name
  Future<void> updateDisplayName(String newName) async {
    if (_session == null) return;
    try {
      _session = await _authService.updateProfile(
        currentSession: _session!,
        displayName: newName,
      );
      notifyListeners();
    } catch (_) {}
  }

  /// Award geo points & badge
  Future<void> awardGeoBonus(int points, String badgeName) async {
    if (_session == null) return;
    try {
      _session = await _authService.awardGeoPoints(
        _session!,
        points,
        badgeName,
      );
      notifyListeners();
    } catch (_) {}
  }

  /// Clear active error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
