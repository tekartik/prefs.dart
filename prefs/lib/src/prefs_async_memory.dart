import 'package:cv/cv.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_prefs/prefs_async.dart';
import 'package:tekartik_prefs/src/prefs_async_mixin.dart';

/// Memory implementation of async prefs
class PrefsAsyncMemory extends PrefsAsyncBase
    with
        PrefsAsyncKeyValueMixin,
        // last wins
        PrefsAsyncNoImplementationKeyMixin {
  final _map = newModel();

  /// Test map content
  @visibleForTesting
  Model get map => _map;

  /// Create a memory prefs with a name
  PrefsAsyncMemory({required super.factory, required super.name});

  @override
  Future<void> clear() async {
    _map.removeWhere((key, value) => !isPrivateKey(key));
  }

  @override
  Future<void> clearForDelete() async {
    _map.clear();
  }

  @override
  Future<T?> getValueNoKeyCheck<T>(String key) async {
    return checkValueType(_map[key]);
  }

  @override
  Future<void> setValueNoKeyCheck<T>(String key, T value) async {
    _map[key] = value;
  }

  @override
  Future<bool> containsKey(String key) async => _map.containsKey(key);

  @override
  Future<Map<String, Object?>> getAll() async => _map.deepClone()
    ..removeWhere((key, value) {
      return isPrivateKey(key);
    });

  @override
  Future<Set<String>> getKeys() async =>
      Set<String>.of(_map.keys)..removeWhere(isPrivateKey);

  @override
  Future<void> remove(String key) async => _map.remove(key);
}

/// Memory implementation of async prefs factory
class PrefsAsyncFactoryMemory with PrefsAsyncFactoryMixin {
  final _persistentsPrefs = <String, PrefsAsyncMemory>{};

  /// Test map content
  @visibleForTesting
  Map<String, PrefsAsyncMemory> get persistentsPrefs => _persistentsPrefs;

  @override
  Future<PrefsAsyncMixin> newPrefs(String name) async {
    /// Reuse if found
    var prefs =
        _persistentsPrefs[name] ?? PrefsAsyncMemory(factory: this, name: name);

    /// Keep all persistent prefs
    _persistentsPrefs[name] = prefs;
    return prefs;
  }
}

/// Singleton memory prefs factory
final _prefsFactoryMemory = PrefsAsyncFactoryMemory();

/// Get the memory prefs factory
PrefsAsyncFactory get prefsAsyncFactoryMemory => _prefsFactoryMemory;

/// Create a new memory prefs
PrefsAsyncFactory newPrefsAsyncFactoryMemory() => PrefsAsyncFactoryMemory();
