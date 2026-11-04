import 'package:flutter/foundation.dart';
import '../models/geo_landmark.dart';
import '../services/geo_service.dart';
import 'auth_provider.dart';

class GeoProvider extends ChangeNotifier {
  GeoProvider({GeoService? geoService})
    : _geoService = geoService ?? DefaultGeoService(),
      landmarks = kGeometricLandmarks;

  final GeoService _geoService;
  final List<GeoLandmark> landmarks;

  GeoPermissionStatus _status = GeoPermissionStatus.notRequested;
  GeoCoordinates? _coordinates;
  bool _isLoading = false;
  GeoLandmark? _selectedLandmark;
  final Set<String> _completedQuestIds = {};
  bool _isSimulated = false;

  GeoPermissionStatus get status => _status;
  GeoCoordinates? get coordinates => _coordinates;
  bool get isLoading => _isLoading;
  GeoLandmark? get selectedLandmark => _selectedLandmark;
  Set<String> get completedQuestIds => _completedQuestIds;
  bool get isSimulated => _isSimulated;
  bool get hasLocation => _coordinates != null;

  /// Find the nearest geometric landmark to current position
  GeoLandmark? get nearestLandmark {
    if (_coordinates == null || landmarks.isEmpty) return null;
    GeoLandmark? closest;
    double minDistance = double.infinity;
    for (final landmark in landmarks) {
      final d = landmark.distanceTo(
        _coordinates!.latitude,
        _coordinates!.longitude,
      );
      if (d < minDistance) {
        minDistance = d;
        closest = landmark;
      }
    }
    return closest;
  }

  /// Initialize and check existing permission
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _status = await _geoService.checkPermission();
      if (_status == GeoPermissionStatus.granted) {
        _coordinates = await _geoService.getCurrentPosition();
      }
    } catch (_) {
      _status = GeoPermissionStatus.denied;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Request location permission from user
  Future<void> requestPermission() async {
    _isLoading = true;
    notifyListeners();

    try {
      _status = await _geoService.requestPermission();
      if (_status == GeoPermissionStatus.granted) {
        _coordinates = await _geoService.getCurrentPosition();
        _isSimulated = false;
      }
    } catch (_) {
      _status = GeoPermissionStatus.denied;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh current position
  Future<void> refresh() async {
    if (_status != GeoPermissionStatus.granted && !_isSimulated) {
      await requestPermission();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (!_isSimulated) {
        _coordinates = await _geoService.getCurrentPosition();
      }
    } catch (_) {
      // keep last known position
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a landmark for inspection
  void selectLandmark(GeoLandmark landmark) {
    _selectedLandmark = landmark;
    notifyListeners();
  }

  /// Solve/complete a landmark geo-quest and award rewards
  Future<bool> completeQuest(
    GeoLandmark landmark,
    AuthProvider? authProvider,
  ) async {
    if (_completedQuestIds.contains(landmark.id)) return false;
    _completedQuestIds.add(landmark.id);

    if (authProvider != null && authProvider.isAuthenticated) {
      await authProvider.awardGeoBonus(
        landmark.bonusPoints,
        'Гео-зерттеуші: ${landmark.name}',
      );
    }

    notifyListeners();
    return true;
  }

  /// Simulate a specific GPS coordinate (for desktop, emulator, or tests)
  void simulateCoordinates(double lat, double lng) {
    _coordinates = GeoCoordinates(
      latitude: lat,
      longitude: lng,
      altitude: 350.0,
      accuracy: 3.5,
      speed: 0.0,
    );
    _status = GeoPermissionStatus.granted;
    _isSimulated = true;
    notifyListeners();
  }

  /// Open system app settings
  Future<bool> openAppSettings() => _geoService.openAppSettings();

  /// Open device location settings
  Future<bool> openLocationSettings() => _geoService.openLocationSettings();
}
