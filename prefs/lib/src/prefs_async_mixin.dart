import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_prefs/prefs_async.dart';

import 'prefs_mixin.dart'
    show prefsVersionKey, prefsSignatureKey, prefsSignatureValue;

/// Prefs mixin
abstract mixin class PrefsAsyncFactoryMixin implements PrefsAsyncFactory {
  /// Lock access
  final lock = Lock(reentrant: true);

  /// To only access in _lock.synchronized
  final allPrefs = <String, PrefsAsyncMixin>{};

  /// Fix the name
  String fixName(String name) {
    if (name.isEmpty) {
      return 'default.prefs';
    }
    return name;
  }

  /// To implement
  Future<PrefsAsyncMixin> newPrefs(String name);

  @override
  Future<void> deletePreferences(String name) async {
    await lock.synchronized(() async {
      /// Close existing
      var prefs =
          allPrefs[name] ?? (await openPreferences(name) as PrefsAsyncMixin);

      await prefs.clearForDelete();
      await prefs.close();
    });
  }

  @override
  Future<PrefsAsync> openPreferences(String name,
      {int? version,
      PrefsAsyncOnVersionChangedFunction? onVersionChanged}) async {
    var prefs = await lock.synchronized(() async {
      var prefs = allPrefs[name];

      if (prefs == null) {
        prefs = await newPrefs(name);
        allPrefs[name] = prefs;

        await prefs.handleMigration(
            version: version, onVersionChanged: onVersionChanged);
      } else {
        if (version != null) {
          if (version != prefs.version) {
            throw StateError(
                'Cannot reopen preferences version ${prefs.version} with a different version');
          }
        }
      }
      return prefs;
    });
    return prefs;
  }

  /// Close the prefs, by default, just remove it from the map
  Future<void> closePreferences(PrefsAsync prefs) async {
    allPrefs.remove(prefs.name);
  }
}

/// Prefs base implementation
abstract class PrefsAsyncBase with PrefsAsyncMixin {
  /// The factory mixin
  @override
  final PrefsAsyncFactoryMixin factory;

  /// The name
  @override
  final String name;

  /// Create a prefs base
  PrefsAsyncBase({required this.factory, required this.name});
}

/// mixin to discard any implementation key modification
abstract mixin class PrefsAsyncNoImplementationKeyMixin
    implements PrefsAsyncMixin {
  @override
  String keyToImplementationKey(String key) => key;

  @override
  String implementationKeyToKey(String implementationKey) => implementationKey;
}

/// Convenient key value mixin
abstract mixin class PrefsAsyncKeyValueMixin implements PrefsAsyncMixin {
  /// Get a value without key check
  Future<T?> getValueNoKeyCheck<T>(String key);

  /// Set any value
  Future<void> setValueNoKeyCheck<T>(String key, T value);

  /// Check and get key
  Future<T?> getValue<T>(String key) {
    checkKey(key);
    return getValueNoKeyCheck<T>(key);
  }

  /// Check key and set value
  Future<void> setValue<T>(String key, T value) {
    checkKey(key);
    return setValueNoKeyCheck(key, value);
  }

  @override
  Future<String?> getStringNoKeyCheck(String key) =>
      getValueNoKeyCheck<String>(key);

  @override
  Future<bool?> getBool(String key) => getValue<bool>(key);

  /// Get num value
  Future<num?> getNum(String key) async {
    return getValue<num>(key);
  }

  @override
  Future<double?> getDouble(String key) async =>
      (await getValue<num>(key))?.toDouble();

  @override
  Future<int?> getInt(String key) async => (await getValue<num>(key))?.toInt();

  @override
  Future<int?> getIntNoKeyCheck(String key) async =>
      (await getValueNoKeyCheck<num>(key))?.toInt();

  @override
  Future<String?> getString(String key) => getValue<String>(key);

  @override
  Future<List<String>?> getStringList(String key) async {
    var list = await getValueNoKeyCheck<List>(key);
    return list
        ?.map((value) => value is String ? value : null)
        .nonNulls
        .toList();
  }

  @override
  Future<void> setBool(String key, bool value) => setValue(key, value);

  @override
  Future<void> setDouble(String key, double value) => setValue(key, value);

  @override
  Future<void> setInt(String key, int value) => setValue(key, value);

  @override
  Future<void> setIntNoKeyCheck(String key, int value) =>
      setValueNoKeyCheck(key, value);

  @override
  Future<void> setString(String key, String value) => setValue(key, value);

  @override
  Future<void> setStringList(String key, List<String> value) =>
      setValue(key, value);

  @override
  Future<void> setStringNoKeyCheck(String key, String value) =>
      setValueNoKeyCheck(key, value);
}

/// Prefs mixin
abstract mixin class PrefsAsyncMixin implements PrefsAsync {
  /// To implement
  PrefsAsyncFactoryMixin get factory;

  /// Check type
  T? checkValueType<T>(Object? value) {
    if (value is T) {
      return value;
    }
    return null;
  }

  /// Lock access
  final lock = Lock(reentrant: true);

  @override
  Future<void> close() => factory.closePreferences(this);

  /// Version
  int? versionOrNull;
  @override
  int get version => versionOrNull ?? 0;

  set version(int version) => versionOrNull = version;

  /// To implement, delelete also signature and version
  Future<void> clearForDelete();

  /// To implement, no check on key
  Future<String?> getStringNoKeyCheck(String key);

  /// To implement, no check on key
  Future<int?> getIntNoKeyCheck(String key);

  /// To implement, no check on key
  Future<void> setStringNoKeyCheck(String key, String value);

  /// To implement, no check on key
  Future<void> setIntNoKeyCheck(String key, int value);

  /// Implementation key prefix
  String get implementationKeyPrefix => '$name/';

  /// True for valid implementation key
  bool isImplementationKey(String implementationKey) {
    return implementationKey.startsWith(implementationKeyPrefix);
  }

  /// Remove the prefix (must check isImplementationKey before)
  String implementationKeyToKey(String implementationKey) {
    return implementationKey.substring(implementationKeyPrefix.length);
  }

  /// True for private key
  bool isPrivateKey(String key) =>
      [prefsVersionKey, prefsSignatureKey].contains(key);

  /// Filter any implementation keys to public keys
  Iterable<String> filterImplementationKeys(Set<String> implementationKeys,
      {bool includePrivate = false}) {
    return implementationKeys.map((implementationKey) {
      if (isImplementationKey(implementationKey)) {
        var publicKey = implementationKeyToKey(implementationKey);
        if (!includePrivate && isPrivateKey(publicKey)) {
          return null;
        }
        return implementationKey;
      }
      return null;
    }).nonNulls;
  }

  /// Check the name
  void checkKey(String name) {
    if (name.isEmpty) {
      throw ArgumentError.notNull('prefs key name cannot be empty');
    }
    if (name.startsWith('_')) {
      throw ArgumentError('prefs key name cannot start with _');
    }
  }

  /// Get the prefs key
  String keyToImplementationKey(String key) => '$implementationKeyPrefix$key';

  /// Handle migration
  Future<void> handleMigration(
      {final int? version,
      PrefsAsyncOnVersionChangedFunction? onVersionChanged}) async {
    await lock.synchronized(() async {
      var signature = await getStringNoKeyCheck(prefsSignatureKey);
      if (signature != prefsSignatureValue) {
        await clearForDelete();
        await setStringNoKeyCheck(prefsSignatureKey, prefsSignatureValue);
        await setIntNoKeyCheck(prefsVersionKey, 0);
      }
      final prefsNewVersion = version;
      final prefsOldVersion = await getIntNoKeyCheck(prefsVersionKey) ?? 0;
      this.version = prefsOldVersion;
      if (prefsNewVersion != null && prefsNewVersion != prefsOldVersion) {
        if (onVersionChanged != null) {
          await onVersionChanged(this, prefsOldVersion, prefsNewVersion);
        }
        await setIntNoKeyCheck(prefsVersionKey, prefsNewVersion);
        this.version = prefsNewVersion;
      }
    });
  }
}
