import 'package:cv/utils/value_utils.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_prefs/prefs_async.dart';
import 'package:tekartik_prefs/src/prefs_async_mixin.dart';

import 'prefs_mixin.dart'
    show
        PrefsCommonPrv,
        prefsSignatureKey,
        prefsSignatureValue,
        prefsVersionKey;

/// Prefs mixin
abstract mixin class PrefsAsyncWithCacheFactoryMixin
    implements PrefsAsyncWithCacheFactory {
  PrefsAsyncWithCacheFactoryOptions? _options;

  @override
  PrefsAsyncWithCacheFactoryOptions get options =>
      _options ??= PrefsAsyncWithCacheFactoryOptions();

  /// Lock access
  final lock = Lock(reentrant: true);

  /// To only access in _lock.synchronized
  final allPrefs = <String, PrefsAsyncWithCacheMixin>{};

  /// Fix the name
  String fixName(String name) {
    if (name.isEmpty) {
      return 'default.prefs';
    }
    return name;
  }

  /// To implement
  Future<PrefsAsyncWithCacheMixin> newPrefs(String name);

  @override
  Future<void> deletePreferences(String name) async {
    name = fixName(name);
    await lock.synchronized(() async {
      /// Close existing
      var prefs =
          allPrefs[name] ??
          (await openPreferences(name) as PrefsAsyncWithCacheMixin);

      await prefs.clearForDelete();
      await prefs.close();
    });
  }

  @override
  Future<PrefsAsyncWithCache> openPreferences(
    String name, {
    int? version,
    PrefsAsyncWithCacheOnVersionChangedFunction? onVersionChanged,
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
  Future<void> closePreferences(PrefsAsyncWithCache prefs) async {
    allPrefs.remove(prefs.name);
  }

  @override
  void init({PrefsAsyncWithCacheFactoryOptions? options}) {
    _options = options;
  }
}

/// Prefs base implementation
abstract class PrefsAsyncWithCacheBase with PrefsAsyncWithCacheMixin {
  /// The factory mixin
  @override
  final PrefsAsyncWithCacheFactoryMixin factory;

  /// The name
  @override
  final String name;

  /// Create a prefs base
  PrefsAsyncWithCacheBase({required this.factory, required this.name});
}

/// Private extension
extension PrefsAsyncWithCacheMixinExtPrv on PrefsAsyncWithCacheMixin {
  /// The options
  PrefsAsyncWithCacheFactoryOptions get options => this.factory.options;
}

/// mixin to discard any implementation key modification
mixin PrefsAsyncNoImplementationKeyMixin implements PrefsCommonPrv {
  @override
  String keyToImplementationKey(String key) => key;

  @override
  String implementationKeyToKey(String implementationKey) => implementationKey;
}

/// Strict value defs
abstract interface class PrefsAsyncWithCacheStrictValue
    implements PrefsAsyncWithCacheMixin {
  /// Get double value
  double? getDoubleStrict(String key);

  /// Get int value
  int? getIntStrict(String key);

  /// Get bool value
  bool? getBoolStrict(String key);

  /// Get string value
  String? getStringStrict(String key);
}

/// Value getter helper
abstract mixin class PrefsAsyncWithCacheValueMixin
    implements
        PrefsAsyncWithCacheMixin,
        PrefsAsyncWithCacheStrictValue,
        PrefsAsyncWithCacheKeyValue {
  @override
  double? getDouble(String key) {
    return basicTypeToDouble(getRawValue(key));
  }

  @override
  int? getInt(String key) {
    return basicTypeToInt(getRawValue(key));
  }

  // Get bool value
  @override
  bool? getBool(String key) {
    return basicTypeToBool(getRawValue(key));
  }

  /// Get string value
  @override
  String? getString(String key) {
    var rawValue = getRawValue(key);
    return rawValue?.toString();
  }

  @override
  double? getDoubleStrict(String key) {
    return getValue<double>(key);
  }

  @override
  int? getIntStrict(String key) {
    return getValue<int>(key);
  }

  // Get bool value
  @override
  bool? getBoolStrict(String key) {
    return getValue<bool>(key);
  }

  /// Get string value
  @override
  String? getStringStrict(String key) {
    return getValue<String>(key);
  }
}

/// Key value abstract interface
abstract interface class PrefsAsyncWithCacheKeyValue
    implements PrefsAsyncWithCache {}

/// Read interface
abstract class PrefsAsyncWithCacheReadKeyValuePrv {
  /// Get a value (not available for strict type)
  T? getValue<T>(String key);

  /// Get a value (not available for strict type)
  Object? getRawValue(String key);

  /// Get a value without key check
  T? getValueNoKeyCheck<T>(String key);
}

/// Async Read halper
abstract mixin class PrefsAsyncWithCacheReadKeyValueMixin
    implements PrefsAsyncWithCacheReadKeyValuePrv, PrefsCommonPrv {
  /// Check and get key
  @override
  T? getValue<T>(String key) {
    checkKey(key);
    return getValueNoKeyCheck<T>(key);
  }
}

/// Convenient key value mixin
abstract mixin class PrefsAsyncWithCacheKeyValueMixin
    implements
        PrefsAsyncWithCacheMixin,
        PrefsAsyncWithCacheKeyValue,
        PrefsAsyncWithCacheReadKeyValuePrv,
        PrefsAsyncWriteKeyValuePrv {
  Object? _getRawValueNoKeyCheck(String key) => getValueNoKeyCheck<Object>(key);

  @override
  Object? getRawValue(String key) {
    checkKey(key);
    return _getRawValueNoKeyCheck(key);
  }

  @override
  String? getStringNoKeyCheck(String key) => getValueNoKeyCheck<String>(key);

  @override
  bool? getBool(String key) => getValue<bool>(key);

  /// Get num value
  Future<num?> getNum(String key) async {
    return getValue<num>(key);
  }

  @override
  int? getIntNoKeyCheck(String key) => (getValueNoKeyCheck<num>(key))?.round();

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
  Future<void> setStringNoKeyCheck(String key, String value) =>
      setValueNoKeyCheck(key, value);
}

/// Prefs mixin
abstract mixin class PrefsAsyncWithCacheMixin
    implements PrefsAsyncWithCache, PrefsCommonPrv {
  /// Options
  @override
  late final options = factory.options;

  /// To implement
  PrefsAsyncWithCacheFactoryMixin get factory;

  /// Get a value (not available for strict type)
  T? getValue<T>(String key);

  /// Get a value (not available for strict type)
  Object? getRawValue(String key);

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
  String? getStringNoKeyCheck(String key);

  /// To implement, no check on key
  int? getIntNoKeyCheck(String key);

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
    PrefsAsyncWithCacheOnVersionChangedFunction? onVersionChanged,
  }) async {
    await lock.synchronized(() async {
      var signature = getStringNoKeyCheck(prefsSignatureKey);
      if (signature != prefsSignatureValue) {
        await clearForDelete();
        await setStringNoKeyCheck(prefsSignatureKey, prefsSignatureValue);
        await setIntNoKeyCheck(prefsVersionKey, 0);
      }
      final prefsNewVersion = version;
      final prefsOldVersion = getIntNoKeyCheck(prefsVersionKey) ?? 0;
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
