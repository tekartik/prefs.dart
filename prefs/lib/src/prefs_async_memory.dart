import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_prefs/mixin/prefs_async_mixin.dart';
import 'package:tekartik_prefs/src/prefs_async.dart';

import 'prefs_memory_mixin.dart';

/// Memory implementation of async prefs
class PrefsAsyncMemory extends PrefsAsyncBase
    with
        PrefsMemoryMixin,
        PrefsCommonMixin,
        PrefsAsyncKeyValueMixin,
        PrefsAsyncReadKeyValueMixin,
        PrefsAsyncWriteKeyValueMixin,
        PrefsAsyncValueMixin,
        // last wins
        PrefsAsyncNoImplementationKeyMixin {
  /// Create a memory prefs with a name
  PrefsAsyncMemory({required super.factory, required super.name});

  @override
  Future<T?> getValueNoKeyCheck<T>(String key) async {
    return memoryGetValueNoKeyCheck(key);
  }

  @override
  Future<bool> containsKey(String key) async => memoryContainsKey(key);

  @override
  Future<Map<String, Object?>> getAll() async => memoryGetAll();

  @override
  Future<Set<String>> getKeys() async => memoryGetKeys();
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
