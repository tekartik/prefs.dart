import 'package:shared_preferences/shared_preferences.dart';
import 'package:tekartik_prefs/mixin/prefs_async_mixin.dart';
import 'package:tekartik_prefs/prefs_async.dart';

class PrefsAsyncFlutter extends PrefsAsyncBase {
  PrefsAsyncFlutter({required super.factory, required super.name});

  PrefsAsyncFactoryFlutter get _factory => factory as PrefsAsyncFactoryFlutter;

  SharedPreferencesAsync get _impl => _factory.sharedPreferencesAsync;
  String _implKey(String key) {
    checkKey(key);
    return keyToImplementationKey(key);
  }

  Future<T?> wrapTypeError<T>(Future<T?> Function() f) async {
    try {
      return await f();
    } on TypeError catch (_) {
      return null;
    }
  }

  @override
  Future<bool> containsKey(String key) => _impl.containsKey(_implKey(key));

  @override
  Future<bool?> getBool(String key) =>
      wrapTypeError(() => _impl.getBool(_implKey(key)));

  @override
  Future<double?> getDouble(String key) async {
    var implKey = _implKey(key);
    try {
      return await _impl.getDouble(implKey);
    } on TypeError catch (_) {
      return (await wrapTypeError(() => _impl.getInt(implKey)))?.toDouble();
    }
  }

  @override
  Future<int?> getInt(String key) async {
    var implKey = _implKey(key);
    try {
      return await _impl.getInt(implKey);
    } on TypeError catch (_) {
      return (await wrapTypeError(() => _impl.getDouble(implKey)))?.round();
    }
  }

  @override
  Future<String?> getString(String key) =>
      wrapTypeError(() => _impl.getString(_implKey(key)));

  @override
  Future<List<String>?> getStringList(String key) =>
      wrapTypeError(() => _impl.getStringList(_implKey(key)));

  @override
  Future<Set<String>> getKeys() async {
    var allImplementationKeys = filterImplementationKeys(await _impl.getKeys());
    return allImplementationKeys.map(implementationKeyToKey).toSet();
  }

  @override
  Future<void> remove(String key) => _impl.remove(_implKey(key));

  @override
  Future<void> setBool(String key, bool value) =>
      _impl.setBool(_implKey(key), value);

  @override
  Future<void> setDouble(String key, double value) =>
      _impl.setDouble(_implKey(key), value);

  @override
  Future<void> setInt(String key, int value) =>
      _impl.setInt(_implKey(key), value);

  @override
  Future<void> setString(String key, String value) =>
      _impl.setString(_implKey(key), value);

  @override
  Future<void> setStringList(String key, List<String> value) =>
      _impl.setStringList(_implKey(key), value);

  @override
  Future<void> clear() async {
    var allImplementationKeys = filterImplementationKeys(await _impl.getKeys());

    await _impl.clear(allowList: allImplementationKeys.toSet());
  }

  @override
  Future<void> clearForDelete() async {
    var allImplementationKeys =
        filterImplementationKeys(await _impl.getKeys(), includePrivate: true);
    await _impl.clear(allowList: allImplementationKeys.toSet());
  }

  @override
  Future<Map<String, Object?>> getAll() async {
    var allImplementationKeys = await _impl.getKeys();
    return (await _impl.getAll(allowList: allImplementationKeys))
        .map((key, value) => MapEntry(implementationKeyToKey(key), value));
  }

  @override
  Future<int?> getIntNoKeyCheck(String key) =>
      _impl.getInt(keyToImplementationKey(key));

  @override
  Future<String?> getStringNoKeyCheck(String key) =>
      _impl.getString(keyToImplementationKey(key));

  @override
  Future<void> setIntNoKeyCheck(String key, int value) =>
      _impl.setInt(keyToImplementationKey(key), value);

  @override
  Future<void> setStringNoKeyCheck(String key, String value) =>
      _impl.setString(keyToImplementationKey(key), value);
}

class PrefsAsyncFactoryFlutter extends PrefsAsyncFactory
    with PrefsAsyncFactoryMixin {
  /// Implementation
  final sharedPreferencesAsync = SharedPreferencesAsync();

  @override
  Future<PrefsAsyncFlutter> newPrefs(String name) async {
    return PrefsAsyncFlutter(factory: this, name: name);
  }
}

final _prefsAsyncFactoryFlutter = PrefsAsyncFactoryFlutter();

/// Flutter factory
PrefsAsyncFactory get prefsAsyncFactoryFlutter => _prefsAsyncFactoryFlutter;
