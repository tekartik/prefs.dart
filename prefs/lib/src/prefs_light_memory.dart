import 'package:cv/cv.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_prefs/prefs_light.dart';
import 'package:tekartik_prefs/src/prefs_utils.dart';

/// In memory prefs (light)
abstract class PrefsMemory implements Prefs {
  /// Creates a new instance of [PrefsMemory].
  factory PrefsMemory() {
    return _PrefsMemory();
  }
}

/// In memory prefs (light)
class _PrefsMemory implements PrefsMemory {
  final _map = newModel();

  /// Test map content
  @visibleForTesting
  Model get map => _map;

  T? _getValue<T>(String key) {
    return checkValueType<T>(_map[key]);
  }

  void _setValue<T>(String key, T value) {
    _map[key] = value;
  }

  Future<T?> _getValueAsync<T>(String key) async {
    return _getValue<T>(key);
  }

  Future<void> _setValueAsync<T>(String key, T value) async {
    _setValue(key, value);
  }

  @override
  Future<bool?> getBool(String key) => _getValueAsync<bool>(key);

  @override
  Future<double?> getDouble(String key) => _getValueAsync<double>(key);

  @override
  Future<int?> getInt(String key) => _getValueAsync<int>(key);

  @override
  Future<String?> getString(String key) => _getValueAsync<String>(key);

  @override
  Future<void> remove(String key) async => _map.remove(key);

  @override
  Future<void> setBool(String key, bool value) =>
      _setValueAsync<bool>(key, value);

  @override
  Future<void> setDouble(String key, double value) =>
      _setValueAsync<double>(key, value);

  @override
  Future<void> setInt(String key, int value) => _setValueAsync<int>(key, value);

  @override
  Future<void> setString(String key, String value) =>
      _setValueAsync<String>(key, value);
}
