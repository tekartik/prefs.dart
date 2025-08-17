import 'package:cv/utils/value_utils.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_prefs/src/prefs_async.dart';

import 'prefs_mixin.dart'
    show
        PrefsCommonPrv,
        prefsSignatureKey,
        prefsSignatureValue,
        prefsVersionKey;

/// Prefs mixin
abstract mixin class PrefsAsyncFactoryMixin implements PrefsAsyncFactory {
  PrefsAsyncFactoryOptions? _options;

  @override
  PrefsAsyncFactoryOptions get options =>
      _options ??= PrefsAsyncFactoryOptions();

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
    name = fixName(name);
    await lock.synchronized(() async {
      /// Close existing
      var prefs =
          allPrefs[name] ?? (await openPreferences(name) as PrefsAsyncMixin);

      await prefs.clearForDelete();
      await prefs.close();
    });
  }

  @override
  Future<PrefsAsync> openPreferences(
    String name, {
    int? version,
    PrefsAsyncOnVersionChangedFunction? onVersionChanged,
  }) async {
    name = fixName(name);
    var prefs = await lock.synchronized(() async {
      var prefs = allPrefs[name];

      if (prefs == null) {
        prefs = await newPrefs(name);
        allPrefs[name] = prefs;

        await prefs.handleMigration(
          version: version,
          onVersionChanged: onVersionChanged,
        );
      } else {
        if (version != null) {
          if (version != prefs.version) {
            throw StateError(
              'Cannot reopen preferences version ${prefs.version} with a different version',
            );
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

  @override
  void init({PrefsAsyncFactoryOptions? options}) {
    _options = options;
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

/// Private extension
extension PrefsAsyncMixinExtPrv on PrefsAsyncMixin {
  /// The options
  PrefsAsyncFactoryOptions get options => this.factory.options;
}

/// mixin to discard any implementation key modification
mixin PrefsAsyncNoImplementationKeyMixin implements PrefsCommonPrv {
  @override
  String keyToImplementationKey(String key) => key;

  @override
  String implementationKeyToKey(String implementationKey) => implementationKey;
}

/// Strict value defs
abstract interface class PrefsAsyncStrictValue implements PrefsAsyncMixin {
  /// Get double value
  Future<double?> getDoubleStrict(String key);

  /// Get int value
  Future<int?> getIntStrict(String key);

  /// Get bool value
  Future<bool?> getBoolStrict(String key);

  /// Get string value
  Future<String?> getStringStrict(String key);

  /// Only validate that it is a list
  Future<List<String>?> getStringListStrict(String key);
}

/// Value getter helper
abstract mixin class PrefsAsyncValueMixin
    implements PrefsAsyncMixin, PrefsAsyncStrictValue, PrefsAsyncKeyValue {
  @override
  Future<double?> getDouble(String key) async {
    if (options.strictType) {
      var doubleValue = await getDoubleStrict(key);
      if (doubleValue != null) {
        return doubleValue;
      }
      if (doubleValue == null) {
        if (kDartIsWebJs) {
          var intValue = await getIntStrict(key);
          if (intValue != null) {
            return intValue.toDouble();
          }
        }
      }
      return null;
    } else {
      return basicTypeToDouble(await getRawValue(key));
    }
  }

  @override
  Future<int?> getInt(String key) async {
    if (options.strictType) {
      return getIntStrict(key);
    } else {
      return basicTypeToInt(await getRawValue(key));
    }
  }

  // Get bool value
  @override
  Future<bool?> getBool(String key) async {
    if (options.strictType) {
      return getBoolStrict(key);
    } else {
      return basicTypeToBool(await getRawValue(key));
    }
  }

  /// Get string value
  @override
  Future<String?> getString(String key) async {
    if (options.strictType) {
      return getStringStrict(key);
    } else {
      var rawValue = await getRawValue(key);
      return rawValue?.toString();
    }
  }

  /// Only validate that it is a list
  @override
  Future<List<String>?> getStringList(String key) async {
    if (options.strictType) {
      return getStringListStrict(key);
    } else {
      var list = await getRawValue(key);
      if (list is List) {
        return list
            .map((value) => value is String ? value : null)
            .nonNulls
            .toList();
      }
      return null;
    }
  }

  @override
  Future<double?> getDoubleStrict(String key) async {
    return getValue<double>(key);
  }

  @override
  Future<int?> getIntStrict(String key) async {
    return getValue<int>(key);
  }

  // Get bool value
  @override
  Future<bool?> getBoolStrict(String key) async {
    return getValue<bool>(key);
  }

  /// Get string value
  @override
  Future<String?> getStringStrict(String key) async {
    return getValue<String>(key);
  }

  /// Only validate that it is a list
  @override
  Future<List<String>?> getStringListStrict(String key) async {
    return (await getValue<List>(key))?.cast<String>().toList();
  }
}

/// Key value abstract interface
abstract interface class PrefsAsyncKeyValue implements PrefsAsync {}

/// Read interface
abstract class PrefsAsyncReadKeyValuePrv {
  /// Get a value (not available for strict type)
  Future<T?> getValue<T>(String key);

  /// Get a value (not available for strict type)
  Future<Object?> getRawValue(String key);

  /// Get a value without key check
  Future<T?> getValueNoKeyCheck<T>(String key);
}

/// Async Read halper
abstract mixin class PrefsAsyncReadKeyValueMixin
    implements PrefsAsyncReadKeyValuePrv, PrefsCommonPrv {
  /// Check and get key
  @override
  Future<T?> getValue<T>(String key) {
    checkKey(key);
    return getValueNoKeyCheck<T>(key);
  }
}

/// Read interface
abstract class PrefsAsyncWriteKeyValuePrv {
  /// Check key and set value
  Future<void> setValue<T>(String key, T value);

  /// Set any value
  Future<void> setValueNoKeyCheck<T>(String key, T value);

  /// Clear before delete
  Future<void> clearForDelete();
}

/// Async Write mixin
abstract mixin class PrefsAsyncWriteKeyValueMixin
    implements PrefsAsyncWriteKeyValuePrv, PrefsCommonPrv {
  /// Check key and set value
  @override
  Future<void> setValue<T>(String key, T value) {
    checkKey(key);
    return setValueNoKeyCheck(key, value);
  }
}

/// Convenient key value mixin
abstract mixin class PrefsAsyncKeyValueMixin
    implements
        PrefsAsyncMixin,
        PrefsAsyncKeyValue,
        PrefsAsyncReadKeyValuePrv,
        PrefsAsyncWriteKeyValuePrv {
  Future<Object?> _getRawValueNoKeyCheck(String key) =>
      getValueNoKeyCheck<Object>(key);

  @override
  Future<Object?> getRawValue(String key) {
    checkKey(key);
    return _getRawValueNoKeyCheck(key);
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
  Future<int?> getIntNoKeyCheck(String key) async =>
      (await getValueNoKeyCheck<num>(key))?.round();

  @override
  Future<void> setBool(String key, bool value) => setValue(key, value);

  @override
  Future<void> setDouble(String key, double value) {
    return setValue(key, value);
  }

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
abstract mixin class PrefsAsyncMixin implements PrefsAsync, PrefsCommonPrv {
  /// Options
  @override
  late final options = factory.options;

  /// To implement
  PrefsAsyncFactoryMixin get factory;

  /// Get a value (not available for strict type)
  Future<T?> getValue<T>(String key);

  /// Get a value (not available for strict type)
  Future<Object?> getRawValue(String key);

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
  @override
  String implementationKeyToKey(String implementationKey) {
    return implementationKey.substring(implementationKeyPrefix.length);
  }

  /// True for private key
  @override
  bool isPrivateKey(String key) =>
      [prefsVersionKey, prefsSignatureKey].contains(key);

  /// Filter any implementation keys to public keys
  Iterable<String> filterImplementationKeys(
    Iterable<String> implementationKeys, {
    bool includePrivate = false,
  }) {
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
  @override
  void checkKey(String key) {
    if (key.isEmpty) {
      throw ArgumentError.notNull('prefs key name cannot be empty');
    }
    if (key.startsWith('_')) {
      throw ArgumentError('prefs key name cannot start with _');
    }
  }

  /// Get the prefs key
  @override
  String keyToImplementationKey(String key) => '$implementationKeyPrefix$key';

  /// Handle migration
  Future<void> handleMigration({
    final int? version,
    PrefsAsyncOnVersionChangedFunction? onVersionChanged,
  }) async {
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
