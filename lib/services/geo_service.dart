import 'package:geolocator/geolocator.dart';

enum GeoPermissionStatus {
  notRequested,
  serviceDisabled,
  denied,
  deniedForever,
  granted,
}

class GeoCoordinates {
  const GeoCoordinates({
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    this.accuracy = 0.0,
    this.speed = 0.0,
  });

  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final double speed;
}

abstract class GeoService {
  Future<bool> isLocationServiceEnabled();
  Future<GeoPermissionStatus> checkPermission();
  Future<GeoPermissionStatus> requestPermission();
  Future<GeoCoordinates?> getCurrentPosition();
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
}

/// Real implementation of GeoService using package:geolocator
class DefaultGeoService implements GeoService {
  DefaultGeoService();

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<GeoPermissionStatus> checkPermission() async {
    try {
      final enabled = await isLocationServiceEnabled();
      if (!enabled) return GeoPermissionStatus.serviceDisabled;

      final permission = await Geolocator.checkPermission();
      return _mapPermission(permission);
    } catch (_) {
      return GeoPermissionStatus.denied;
    }
  }

  @override
  Future<GeoPermissionStatus> requestPermission() async {
    try {
      final enabled = await isLocationServiceEnabled();
      if (!enabled) return GeoPermissionStatus.serviceDisabled;

      final permission = await Geolocator.requestPermission();
      return _mapPermission(permission);
    } catch (_) {
      return GeoPermissionStatus.denied;
    }
  }

  @override
  Future<GeoCoordinates?> getCurrentPosition() async {
    try {
      final status = await checkPermission();
      if (status != GeoPermissionStatus.granted) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return GeoCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        accuracy: position.accuracy,
        speed: position.speed,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  GeoPermissionStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return GeoPermissionStatus.granted;
      case LocationPermission.deniedForever:
        return GeoPermissionStatus.deniedForever;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return GeoPermissionStatus.denied;
    }
  }
}

/// Mock implementation of GeoService for testing and desktop/emulator fallbacks
class MockGeoService implements GeoService {
  MockGeoService({
    this.serviceEnabled = true,
    GeoPermissionStatus initialStatus = GeoPermissionStatus.notRequested,
    this.mockPosition = const GeoCoordinates(
      latitude: 51.1283,
      longitude: 71.4305,
      altitude: 350.0,
      accuracy: 5.0,
      speed: 0.0,
    ),
  }) : _currentStatus = initialStatus;

  bool serviceEnabled;
  GeoPermissionStatus _currentStatus;
  GeoCoordinates? mockPosition;

  void setStatus(GeoPermissionStatus status) {
    _currentStatus = status;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<GeoPermissionStatus> checkPermission() async {
    if (!serviceEnabled) return GeoPermissionStatus.serviceDisabled;
    return _currentStatus;
  }

  @override
  Future<GeoPermissionStatus> requestPermission() async {
    if (!serviceEnabled) return GeoPermissionStatus.serviceDisabled;
    if (_currentStatus == GeoPermissionStatus.deniedForever) {
      return GeoPermissionStatus.deniedForever;
    }
    _currentStatus = GeoPermissionStatus.granted;
    return _currentStatus;
  }

  @override
  Future<GeoCoordinates?> getCurrentPosition() async {
    if (_currentStatus != GeoPermissionStatus.granted) return null;
    return mockPosition;
  }

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}
