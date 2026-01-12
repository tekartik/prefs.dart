import 'package:cv/utils/value_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tekartik_prefs/mixin/prefs_async_mixin.dart';
import 'package:tekartik_prefs/prefs_async.dart';

/// Flutter implementation of PrefsAsyncWithCache.
class PrefsAsyncWithCacheFlutter extends PrefsAsyncWithCacheBase
    with PrefsCommonMixin, PrefsAsyncWithCacheValueMixin
    implements PrefsAsyncWithCacheStrictValue, PrefsAsyncWithCache {
  /// Create a Flutter implementation of PrefsAsyncWithCache.
  PrefsAsyncWithCacheFlutter({required super.factory, required super.name});

  PrefsAsyncWithCacheFactoryFlutter get _factory =>
      super.factory as PrefsAsyncWithCacheFactoryFlutter;

  SharedPreferencesWithCache get _implWithCache =>
      _factory.sharePreferencesWithCache;

  String _implKey(String key) {
    checkKey(key);
    return keyToImplementationKey(key);
  }

  /// Helper to wrap type errors.
  T? wrapTypeError<T>(T? Function() f) {
    try {
      return f();
    } on TypeError catch (_) {
      return null;
    }
  }

  /// Helper to wrap type errors synchronously.
  T? wrapTypeErrorSync<T>(T? Function() f) {
    try {
      return f();
    } on TypeError catch (_) {
      return null;
    }
  }

  @override
  bool containsKey(String key) {
    var implKey = _implKey(key);

    return _implWithCache.containsKey(implKey);
  }

  @override
  bool? getBoolStrict(String key) =>
      wrapTypeErrorSync(() => _implWithCache.getBool(_implKey(key)));

  @override
  double? getDoubleStrict(String key) {
    var implKey = _implKey(key);
    try {
      return _implWithCache.getDouble(implKey);
    } on TypeError catch (_) {
      return null;
    }
  }

  @override
  int? getIntStrict(String key) {
    var implKey = _implKey(key);
    try {
      return _implWithCache.getInt(implKey);
    } on TypeError catch (_) {
      return null;
    }
  }

  @override
  String? getStringStrict(String key) =>
      wrapTypeErrorSync(() => _implWithCache.getString(_implKey(key)));

  @override
  Set<String> get keys {
    var allImplementationKeys = filterImplementationKeys(_implGetAllKeys());
    return allImplementationKeys.map(implementationKeyToKey).toSet();
  }

  @override
  Future<void> remove(String key) {
    var implKey = _implKey(key);
    return _implWithCache.remove(implKey);
  }

  @override
  Future<void> setBool(String key, bool value) {
    var implKey = _implKey(key);
    return _implWithCache.setBool(implKey, value);
  }

  @override
  Future<void> setDouble(String key, double value) {
    var implKey = _implKey(key);
    return _implWithCache.setDouble(implKey, value);
  }

  @override
  Future<void> setInt(String key, int value) {
    var implKey = _implKey(key);
    return _implWithCache.setInt(implKey, value);
  }

  @override
  Future<void> setString(String key, String value) {
    var implKey = _implKey(key);
    return _implWithCache.setString(implKey, value);
  }

  @override
  Future<void> clear() async {
    var allImplementationKeys = filterImplementationKeys(
      _implGetAllKeys(),
      includePrivate: false,
    );
    for (var key in allImplementationKeys) {
      await _implWithCache.remove(key);
    }
  }

  Set<String> _implGetAllKeys() {
    return _implWithCache.keys;
  }

  @override
  Future<void> clearForDelete() async {
    var allImplementationKeys = filterImplementationKeys(
      _implGetAllKeys(),
      includePrivate: true,
    );

    for (var key in allImplementationKeys) {
      await _implWithCache.remove(key);
    }
  }

  @override
  int? getIntNoKeyCheck(String key) {
    var implKey = keyToImplementationKey(key);
    return basicTypeToInt(_getRawValue(implKey));
  }

  @override
  String? getStringNoKeyCheck(String key) {
    var implKey = keyToImplementationKey(key);
    return (_getRawValue(implKey))?.toString();
  }

  @override
  Future<void> setIntNoKeyCheck(String key, int value) async {
    var implKey = keyToImplementationKey(key);
    await _implWithCache.setInt(implKey, value);
  }

  @override
  Future<void> setStringNoKeyCheck(String key, String value) async {
    var implKey = keyToImplementationKey(key);
    await _implWithCache.setString(implKey, value);
  }

  Object? _getRawValue(String key) {
    return _implWithCache.get(key);
  }

  @override
  Object? getRawValue(String key) {
    checkKey(key);
    var implKey = keyToImplementationKey(key);
    return _getRawValue(implKey);
  }

  @override
  T? getValue<T>(String key) {
    return checkValueType<T>(getRawValue(key));
  }
}

/// Flutter factory for PrefsAsyncWithCache.
class PrefsAsyncWithCacheFactoryFlutter extends PrefsAsyncWithCacheFactory
    with PrefsAsyncWithCacheFactoryMixin {
  SharedPreferencesWithCache? _sharePreferencesWithCache;

  /// Shared preferences with cache implementation.
  SharedPreferencesWithCache get sharePreferencesWithCache =>
      _sharePreferencesWithCache!;

  @override
  Future<PrefsAsyncWithCacheFlutter> newPrefs(String name) async {
    _sharePreferencesWithCache ??= await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    return PrefsAsyncWithCacheFlutter(factory: this, name: name);
  }

  @override
  String toString() => 'PrefsAsyncFactoryFlutter($options)';
}

final _prefsAsyncWithCacheFactoryFlutter = PrefsAsyncWithCacheFactoryFlutter();

/// Flutter factory
PrefsAsyncWithCacheFactory get prefsAsyncWithCacheFactoryFlutter =>
    _prefsAsyncWithCacheFactoryFlutter;
