import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_prefs/mixin/prefs_async_mixin.dart';
import 'package:tekartik_prefs/prefs_async.dart';

import 'prefs_memory_mixin.dart';

/// Memory implementation of async prefs
class PrefsAsyncWithCacheMemory extends PrefsAsyncWithCacheBase
    with
        PrefsMemoryMixin,
        PrefsCommonMixin,
        PrefsAsyncWithCacheKeyValueMixin,
        PrefsAsyncWithCacheReadKeyValueMixin,
        PrefsAsyncWriteKeyValueMixin,
        PrefsAsyncWithCacheValueMixin,
        // last wins
        PrefsAsyncNoImplementationKeyMixin {
  /// Create a memory prefs with a name
  PrefsAsyncWithCacheMemory({required super.factory, required super.name});

  @override
  T? getValueNoKeyCheck<T>(String key) {
    return memoryGetValueNoKeyCheck(key);
  }

  @override
  bool containsKey(String key) => memoryContainsKey(key);

  @override
  Set<String> get keys => memoryGetKeys();
}

/// Memory implementation of async prefs factory
class PrefsAsyncWithCacheFactoryMemory with PrefsAsyncWithCacheFactoryMixin {
  final _persistentsPrefs = <String, PrefsAsyncWithCacheMemory>{};

  /// Test map content
  @visibleForTesting
  Map<String, PrefsAsyncWithCacheMemory> get persistentsPrefs =>
      _persistentsPrefs;

  @override
  Future<PrefsAsyncWithCacheMixin> newPrefs(String name) async {
    /// Reuse if found
    var prefs =
        _persistentsPrefs[name] ??
        PrefsAsyncWithCacheMemory(factory: this, name: name);

    /// Keep all persistent prefs
    _persistentsPrefs[name] = prefs;
    return prefs;
  }
}

/// Singleton memory prefs factory
final _prefsAsyncWithCacheFactoryMemory = PrefsAsyncWithCacheFactoryMemory();

/// Get the memory prefs factory
PrefsAsyncWithCacheFactory get prefsAsyncWithCacheFactoryMemory =>
    _prefsAsyncWithCacheFactoryMemory;

/// Create a new memory prefs
PrefsAsyncWithCacheFactory newPrefsAsyncWithCacheFactoryMemory() =>
    PrefsAsyncWithCacheFactoryMemory();
