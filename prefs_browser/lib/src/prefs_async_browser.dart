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

class _PrefsAsyncBrowser extends PrefsAsyncBase
    with PrefsAsyncKeyValueMixin, PrefsAsyncValueMixin {
  _PrefsAsyncBrowser({required super.factory, required super.name});

  _PrefsAsyncFactoryBrowser get prefsFactoryBrowser =>
      factory as _PrefsAsyncFactoryBrowser;

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
    var allImplementationKeys =
        filterImplementationKeys(_allStorageKeys, includePrivate: true);
    for (var implKey in allImplementationKeys) {
      _storage.removeItem(implKey);
    }
  }

  @override
  Future<bool> containsKey(String key) async {
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
  Future<Map<String, Object?>> getAll() async {
    var allImplementationKeys = filterImplementationKeys(_allStorageKeys);
    var map = <String, Object?>{
      for (var key in allImplementationKeys)
        key: _implementationKeyGetValue(key)
    };
    return map;
  }

  @override
  Future<Set<String>> getKeys() async {
    var allImplementationKeys = filterImplementationKeys(_allStorageKeys);

    return allImplementationKeys.map(implementationKeyToKey).toSet();
  }

  @override
  Future<T?> getValueNoKeyCheck<T>(String key) async {
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

class _PrefsAsyncFactoryBrowser with PrefsAsyncFactoryMixin {
  @override
  Future<PrefsAsyncMixin> newPrefs(String name) async {
    return _PrefsAsyncBrowser(factory: this, name: name);
  }
}

final _prefsAsyncFactoryBrowser = _PrefsAsyncFactoryBrowser();

/// Async prefs factory for browser or null
PrefsAsyncFactory? get prefsAsyncFactoryBrowserOrNull =>
    prefsAsyncFactoryBrowser;

/// Async prefs factory for browser
PrefsAsyncFactory get prefsAsyncFactoryBrowser => _prefsAsyncFactoryBrowser;
