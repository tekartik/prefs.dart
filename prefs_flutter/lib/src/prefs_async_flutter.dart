import 'package:cv/utils/value_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tekartik_prefs/mixin/prefs_async_mixin.dart';
import 'package:tekartik_prefs/prefs_async.dart';

/// Flutter implementation of PrefsAsync.
class PrefsAsyncFlutter extends PrefsAsyncBase
    with PrefsCommonMixin, PrefsAsyncValueMixin
    implements PrefsAsyncStrictValue {
  /// Create a Flutter implementation of PrefsAsync.
  PrefsAsyncFlutter({required super.factory, required super.name});

  PrefsAsyncFactoryFlutter get _factory =>
      super.factory as PrefsAsyncFactoryFlutter;

  SharedPreferencesAsync get _impl => _factory.sharedPreferencesAsync;

  SharedPreferencesWithCache get _implWithCache =>
      _factory.sharePreferencesWithCache;

  String _implKey(String key) {
    checkKey(key);
    return keyToImplementationKey(key);
  }

  /// Helper to wrap type errors.
  Future<T?> wrapTypeError<T>(Future<T?> Function() f) async {
    try {
      return await f();
    } on TypeError catch (_) {
      return null;
    }
  }

  @override
  Future<bool> containsKey(String key) {
    var implKey = _implKey(key);
    if (options.strictType) {
      return _impl.containsKey(implKey);
    } else {
      return Future.value(_implWithCache.containsKey(implKey));
    }
  }

  @override
  Future<bool?> getBoolStrict(String key) =>
      wrapTypeError(() => _impl.getBool(_implKey(key)));

  @override
  Future<double?> getDoubleStrict(String key) async {
    var implKey = _implKey(key);
    try {
      return await _impl.getDouble(implKey);
    } on TypeError catch (_) {
      return null;
    }
  }

  @override
  Future<int?> getIntStrict(String key) async {
    var implKey = _implKey(key);
    try {
      return await _impl.getInt(implKey);
    } on TypeError catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getStringStrict(String key) =>
      wrapTypeError(() => _impl.getString(_implKey(key)));

  @override
  Future<List<String>?> getStringListStrict(String key) =>
      wrapTypeError(() => _impl.getStringList(_implKey(key)));

  @override
  Future<Set<String>> getKeys() async {
    var allImplementationKeys = filterImplementationKeys(
      await _implGetAllKeys(),
    );
    return allImplementationKeys.map(implementationKeyToKey).toSet();
  }

  @override
  Future<void> remove(String key) {
    var implKey = _implKey(key);
    if (options.strictType) {
      return _impl.remove(implKey);
    } else {
      return _implWithCache.remove(implKey);
    }
  }

  @override
  Future<void> setBool(String key, bool value) {
    var implKey = _implKey(key);
    if (options.strictType) {
      return _impl.setBool(implKey, value);
    } else {
      return _implWithCache.setBool(implKey, value);
    }
  }

  @override
  Future<void> setDouble(String key, double value) {
    var implKey = _implKey(key);
    if (options.strictType) {
      return _impl.setDouble(implKey, value);
    } else {
      return _implWithCache.setDouble(implKey, value);
    }
  }

  @override
  Future<void> setInt(String key, int value) {
    var implKey = _implKey(key);
    if (options.strictType) {
      return _impl.setInt(implKey, value);
    } else {
      return _implWithCache.setInt(implKey, value);
    }
  }

  @override
  Future<void> setString(String key, String value) {
    var implKey = _implKey(key);
    if (options.strictType) {
      return _impl.setString(implKey, value);
    } else {
      return _implWithCache.setString(implKey, value);
    }
  }

  @override
  Future<void> setStringList(String key, List<String> value) {
    var implKey = _implKey(key);
    if (options.strictType) {
      return _impl.setStringList(implKey, value);
    } else {
      return _implWithCache.setStringList(implKey, value);
    }
  }

  @override
  Future<void> clear() async {
    var allImplementationKeys = filterImplementationKeys(
      await _implGetAllKeys(),
      includePrivate: false,
    );
    if (options.strictType) {
      await _impl.clear(allowList: allImplementationKeys.toSet());
    } else {
      for (var key in allImplementationKeys) {
        await _implWithCache.remove(key);
      }
    }
  }

  Future<Set<String>> _implGetAllKeys() async {
    if (options.strictType) {
      return await _impl.getKeys();
    } else {
      return _implWithCache.keys;
    }
  }

  @override
  Future<void> clearForDelete() async {
    var allImplementationKeys = filterImplementationKeys(
      await _implGetAllKeys(),
      includePrivate: true,
    );
    if (options.strictType) {
      await _impl.clear(allowList: allImplementationKeys.toSet());
    } else {
      for (var key in allImplementationKeys) {
        await _implWithCache.remove(key);
      }
    }
  }

  @override
  Future<Map<String, Object?>> getAll() async {
    var allImplementationKeys = await _implGetAllKeys();
    if (options.strictType) {
      return (await _impl.getAll(
        allowList: allImplementationKeys,
      )).map((key, value) => MapEntry(implementationKeyToKey(key), value));
    } else {
      var map = <String, Object?>{
        for (var key in allImplementationKeys)
          implementationKeyToKey(key): _implWithCache.get(key),
      };
      return map;
    }
  }

  @override
  Future<int?> getIntNoKeyCheck(String key) async {
    var implKey = keyToImplementationKey(key);
    if (options.strictType) {
      return await _impl.getInt(implKey);
    } else {
      return basicTypeToInt(_getRawValue(implKey));
    }
  }

  @override
  Future<String?> getStringNoKeyCheck(String key) async {
    var implKey = keyToImplementationKey(key);
    if (options.strictType) {
      return await _impl.getString(implKey);
    } else {
      return (_getRawValue(implKey))?.toString();
    }
  }

  @override
  Future<void> setIntNoKeyCheck(String key, int value) async {
    var implKey = keyToImplementationKey(key);
    if (options.strictType) {
      await _impl.setInt(implKey, value);
    } else {
      await _implWithCache.setInt(implKey, value);
    }
  }

  @override
  Future<void> setStringNoKeyCheck(String key, String value) async {
    var implKey = keyToImplementationKey(key);
    if (options.strictType) {
      await _impl.setString(implKey, value);
    } else {
      await _implWithCache.setString(implKey, value);
    }
  }

  Object? _getRawValue(String key) {
    return _implWithCache.get(key);
  }

  @override
  Future<Object?> getRawValue(String key) async {
    checkKey(key);
    var implKey = keyToImplementationKey(key);
    return _getRawValue(implKey);
  }

  @override
  Future<T?> getValue<T>(String key) async {
    return checkValueType<T>(await getRawValue(key));
  }
}

/// Flutter factory for PrefsAsync.
class PrefsAsyncFactoryFlutter extends PrefsAsyncFactory
    with PrefsAsyncFactoryMixin {
  SharedPreferencesAsync? _sharedPreferencesAsync;
  SharedPreferencesWithCache? _sharePreferencesWithCache;

  /// Implementation
  SharedPreferencesAsync get sharedPreferencesAsync => _sharedPreferencesAsync!;

  /// Shared preferences with cache implementation.
  SharedPreferencesWithCache get sharePreferencesWithCache =>
      _sharePreferencesWithCache!;

  @override
  Future<PrefsAsyncFlutter> newPrefs(String name) async {
    if (options.strictType) {
      _sharedPreferencesAsync ??= SharedPreferencesAsync();
      if (kDebugMode) {
        _sharePreferencesWithCache = null;
      }
    } else {
      _sharePreferencesWithCache ??= await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(),
      );
      if (kDebugMode) {
        _sharedPreferencesAsync = null;
      }
    }
    return PrefsAsyncFlutter(factory: this, name: name);
  }

  @override
  String toString() => 'PrefsAsyncFactoryFlutter($options)';
}

final _prefsAsyncFactoryFlutter = PrefsAsyncFactoryFlutter();

/// Flutter factory
PrefsAsyncFactory get prefsAsyncFactoryFlutter => _prefsAsyncFactoryFlutter;
