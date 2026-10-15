import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress.dart';

abstract interface class ProgressStore {
  Future<String?> read();
  Future<void> write(String value);
}

class PreferencesProgressStore implements ProgressStore {
  PreferencesProgressStore() : _preferences = SharedPreferencesAsync();
  static const key = 'geoswipe.progress';
  final SharedPreferencesAsync _preferences;
  @override
  Future<String?> read() => _preferences.getString(key);
  @override
  Future<void> write(String value) => _preferences.setString(key, value);
}

class ProgressRepository {
  ProgressRepository(this.store);
  final ProgressStore store;
  Future<ProgressSnapshot> load() async {
    final source = await store.read();
    if (source == null) return ProgressSnapshot();
    final json = jsonDecode(source);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid save');
    }
    return ProgressSnapshot.fromJson(json);
  }

  Future<void> save(ProgressSnapshot snapshot) =>
      store.write(jsonEncode(snapshot.toJson()));
}
