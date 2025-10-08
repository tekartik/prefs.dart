import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_prefs/mixin/prefs_async_mixin.dart';
import 'package:tekartik_prefs/prefs_async.dart';
// ignore: implementation_imports
import 'package:web/web.dart' show window, Storage;

Storage get _storage => window.localStorage;
Iterable<String> get _allStorageKeys {
  var keys = <String>[];
  for (var i = 0; i < _storage.length; i++) {
    keys.add(_storage.key(i)!);
  }
  return keys;
}

class _PrefsAsyncWithCacheBrowser extends PrefsAsyncWithCacheBase
    with
        PrefsCommonMixin,
        PrefsAsyncWithCacheKeyValueMixin,
        PrefsAsyncWithCacheReadKeyValueMixin,
        PrefsAsyncWriteKeyValueMixin,
        PrefsAsyncWithCacheValueMixin {
  _PrefsAsyncWithCacheBrowser({required super.factory, required super.name});

  _PrefsAsyncWithCacheFactoryBrowser get prefsFactoryBrowser =>
      factory as _PrefsAsyncWithCacheFactoryBrowser;

  String _implKey(String key) {
    checkKey(key);
    return keyToImplementationKey(key);
  }

  @override
  Future<void> clear() async {
    var allImplementationKeys = filterImplementationKeys(_allStorageKeys);
    for (var implKey in allImplementationKeys) {
      _storage.removeItem(implKey);
    }
  }

  @override
  Future<void> clearForDelete() async {
    var allImplementationKeys = filterImplementationKeys(
      _allStorageKeys,
      includePrivate: true,
    );
    for (var implKey in allImplementationKeys) {
      _storage.removeItem(implKey);
    }
  }

  @override
  bool containsKey(String key) {
    return _storage.getItem(_implKey(key)) != null;
  }

  Object? _implementationKeyGetValue(String key) {
    var value = _storage.getItem(key);
    if (value == null) {
      return null;
    }
    return jsonDecode(value);
  }

  @override
  Set<String> get keys {
    var allImplementationKeys = filterImplementationKeys(_allStorageKeys);

    return allImplementationKeys.map(implementationKeyToKey).toSet();
  }

  @override
  T? getValueNoKeyCheck<T>(String key) {
    var value = _implementationKeyGetValue(keyToImplementationKey(key));
    return checkValueType<T>(value);
  }

  @override
  Future<void> remove(String key) async {
    _storage.removeItem(_implKey(key));
  }

  @override
  Future<void> setValueNoKeyCheck<T>(String key, T value) async {
    _storage.setItem(keyToImplementationKey(key), jsonEncode(value));
  }
}

class _PrefsAsyncWithCacheFactoryBrowser with PrefsAsyncWithCacheFactoryMixin {
  @override
  Future<PrefsAsyncWithCacheMixin> newPrefs(String name) async {
    return _PrefsAsyncWithCacheBrowser(factory: this, name: name);
  }
}

final _prefsAsyncWithCacheFactoryBrowser = _PrefsAsyncWithCacheFactoryBrowser();

/// AsyncWithCache prefs factory for browser or null
PrefsAsyncWithCacheFactory? get prefsAsyncWithCacheFactoryBrowserOrNull =>
    prefsAsyncWithCacheFactoryBrowser;

/// AsyncWithCache prefs factory for browser
PrefsAsyncWithCacheFactory get prefsAsyncWithCacheFactoryBrowser =>
    _prefsAsyncWithCacheFactoryBrowser;
