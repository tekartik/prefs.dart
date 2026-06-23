import 'package:idb_shim/sdb/sdb.dart' as sdb;
import 'package:tekartik_common_utils/common_utils_import.dart' hide parseInt;
import 'package:tekartik_common_utils/int_utils.dart';
import 'package:tekartik_prefs/mixin/prefs_async_mixin.dart';
import 'package:tekartik_prefs/prefs_async.dart';

final _store = sdb.SdbStoreRef<String, Object>('main');
final _metaStore = sdb.SdbStoreRef<String, Object>('meta');
final _metaVersionRecord = _metaStore.record('version');
final _signatureRecord = _metaStore.record('signature');

/// Helper function to sanitize map and list values before writing to Sdb.
Object? _sdbSanitizeValue(Object? value) {
  if (value == null || value is num || value is String || value is bool) {
    return value;
  } else if (value is Map) {
    return <String, Object?>{
      for (var entry in value.entries)
        entry.key.toString(): _sdbSanitizeValue(entry.value),
    };
  } else if (value is Iterable) {
    return <Object?>[for (var item in value) _sdbSanitizeValue(item)];
  }
  return value;
}

/// Sdb implementation of the [PrefsAsyncWithCache] interface.
class PrefsAsyncWithCacheSdb extends PrefsAsyncWithCacheBase
    with
        PrefsCommonMixin,
        PrefsAsyncNoImplementationKeyMixin,
        PrefsAsyncWithCacheKeyValueMixin,
        PrefsAsyncWithCacheReadKeyValueMixin,
        PrefsAsyncWriteKeyValueMixin,
        PrefsAsyncWithCacheValueMixin {
  PrefsAsyncWithCacheFactorySdb get _factory =>
      this.factory as PrefsAsyncWithCacheFactorySdb;

  /// The underlying Sdb database instance.
  late sdb.SdbDatabase database;

  // Local cache in memory for synchronous reads
  final _map = <String, Object?>{};

  /// Creates a new [PrefsAsyncWithCacheSdb] instance.
  PrefsAsyncWithCacheSdb({required super.factory, required super.name});

  /// Gets the database file path.
  String get dbPath => _factory.getDbPath(name);

  @override
  Future close() async {
    await database.close();
    await super.close();
  }

  sdb.SdbTransaction? _openTransaction;

  /// Opens the preferences database.
  Future open() async {
    final sdbSchema = sdb.SdbDatabaseSchema(
      stores: [_store.schema(), _metaStore.schema()],
    );
    database = await _factory.sdbFactory.openDatabase(
      dbPath,
      options: sdb.SdbOpenDatabaseOptions(
        version: 1,
        schema: sdbSchema,
        onVersionChange: (event) async {
          if (event.oldVersion == 0) {
            await _signatureRecord.put(event.transaction, prefsSignatureValue);
          }
        },
      ),
    );
  }

  /// Handle migration
  @override
  Future<void> handleMigration({
    final int? version,
    PrefsAsyncWithCacheOnVersionChangedFunction? onVersionChanged,
  }) async {
    await lock.synchronized(() async {
      await database.inStoresTransaction(
        [_store, _metaStore],
        sdb.SdbTransactionMode.readWrite,
        (txn) async {
          _openTransaction = txn;
          try {
            var signature = await _signatureRecord.getValue(txn);
            if (signature != prefsSignatureValue || database.version > 1) {
              await txn.store(_store).deleteRecords();
              await txn.store(_metaStore).deleteRecords();
              await _signatureRecord.put(txn, prefsSignatureValue);
            }

            var prefsOldVersion = this.version =
                parseInt(await _metaVersionRecord.getValue(txn)) ?? 0;
            final prefsNewVersion = version;

            // Populate cache from DB first
            _map.clear();
            var records = await txn.store(_store).findRecords();
            for (var record in records) {
              _map[record.key] = record.value;
            }

            var versionVal = await _metaVersionRecord.getValue(txn);
            if (versionVal != null) {
              _map[prefsVersionKey] = versionVal;
            }
            var sigVal = await _signatureRecord.getValue(txn);
            if (sigVal != null) {
              _map[prefsSignatureKey] = sigVal;
            }

            if (prefsNewVersion != null && prefsNewVersion != prefsOldVersion) {
              if (onVersionChanged != null) {
                await onVersionChanged(this, prefsOldVersion, prefsNewVersion);
                await _metaVersionRecord.put(txn, prefsNewVersion);
              }
              this.version = prefsNewVersion;
            }
          } finally {
            _openTransaction = null;
          }
        },
      );
    });
  }

  sdb.SdbClient get _client => _openTransaction ?? database;

  @override
  Future<void> clear() async {
    _map.removeWhere((key, value) => !isPrivateKey(key));
    await _store.delete(_client);
  }

  @override
  Future<void> clearForDelete() async {
    _map.clear();
    await _store.delete(_client);
    await _metaStore.delete(_client);
  }

  @override
  bool containsKey(String key) => _map.containsKey(key) && !isPrivateKey(key);

  @override
  Set<String> get keys => Set<String>.of(_map.keys)..removeWhere(isPrivateKey);

  @override
  T? getValueNoKeyCheck<T>(String key) {
    return checkValueType(_map[key]);
  }

  @override
  Future<void> remove(String key) async {
    _map.remove(key);
    await _store.record(key).delete(_client);
  }

  @override
  Future<void> setValueNoKeyCheck<T>(String key, T value) async {
    _map[key] = value;
    await _store.record(key).put(_client, _sdbSanitizeValue(value) as Object);
  }

  @override
  String? getStringNoKeyCheck(String key) {
    return _map[key]?.toString();
  }

  @override
  int? getIntNoKeyCheck(String key) {
    return parseInt(_map[key]);
  }

  @override
  Future<void> setStringNoKeyCheck(String key, String value) async {
    _map[key] = value;
    await _metaStore.record(key).put(_client, value);
  }

  @override
  Future<void> setIntNoKeyCheck(String key, int value) async {
    _map[key] = value;
    await _metaStore.record(key).put(_client, value);
  }
}

/// Sdb implementation of the [PrefsAsyncWithCacheFactory] interface.
class PrefsAsyncWithCacheFactorySdb extends Object
    with PrefsAsyncWithCacheFactoryMixin
    implements PrefsAsyncWithCacheFactory {
  /// The underlying Sdb database factory.
  final sdb.SdbFactory sdbFactory;

  /// Gets the database path for a given preference name.
  String getDbPath(String name) => name;

  /// Creates a new [PrefsAsyncWithCacheFactorySdb] instance.
  PrefsAsyncWithCacheFactorySdb(this.sdbFactory);

  @override
  Future deletePreferences(String name) async {
    name = fixName(name);
    await lock.synchronized(() async {
      var prefs = allPrefs[name];
      if (prefs != null) {
        await prefs.close();
      }
      await sdbFactory.deleteDatabase(getDbPath(name));
    });
  }

  @override
  Future<PrefsAsyncWithCacheMixin> newPrefs(String name) async {
    var prefs = PrefsAsyncWithCacheSdb(factory: this, name: name);
    await prefs.open();
    return prefs;
  }
}

/// Helper function to create a [PrefsAsyncWithCacheFactorySdb] instance.
PrefsAsyncWithCacheFactorySdb getPrefsAsyncWithCacheFactorySdb(
  sdb.SdbFactory sdbFactory,
) => PrefsAsyncWithCacheFactorySdb(sdbFactory);
