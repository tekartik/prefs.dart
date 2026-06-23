import 'package:idb_shim/sdb/sdb.dart' as sdb;
import 'package:path/path.dart';
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

/// Sdb implementation of the [PrefsAsync] interface.
class PrefsAsyncSdb extends PrefsAsyncBase
    with
        PrefsCommonMixin,
        PrefsAsyncNoImplementationKeyMixin,
        PrefsAsyncKeyValueMixin,
        PrefsAsyncReadKeyValueMixin,
        PrefsAsyncWriteKeyValueMixin,
        PrefsAsyncValueMixin {
  PrefsAsyncFactorySdb get _factory => this.factory as PrefsAsyncFactorySdb;

  /// The underlying Sdb database instance.
  late sdb.SdbDatabase database;

  /// Creates a new [PrefsAsyncSdb] instance.
  PrefsAsyncSdb({required super.factory, required super.name});

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
    PrefsAsyncOnVersionChangedFunction? onVersionChanged,
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
  Future<void> clear() => _store.delete(_client);

  @override
  Future<void> clearForDelete() {
    throw UnimplementedError();
  }

  @override
  Future<bool> containsKey(String key) => _store.record(key).exists(_client);

  @override
  Future<Map<String, Object?>> getAll() async {
    var records = await _store.findRecords(_client);
    return <String, Object?>{
      for (var record in records) record.key: record.value,
    };
  }

  @override
  Future<Set<String>> getKeys() async {
    var recordKeys = await _store.findRecordKeys(_client);
    return recordKeys.keys.toSet();
  }

  @override
  Future<T?> getValueNoKeyCheck<T>(String key) async {
    return checkValueType(await _store.record(key).getValue(_client));
  }

  @override
  Future<void> remove(String key) => _store.record(key).delete(_client);

  @override
  Future<void> setValueNoKeyCheck<T>(String key, T value) =>
      _store.record(key).put(_client, _sdbSanitizeValue(value) as Object);
}

/// Sdb implementation of the [PrefsAsyncFactory] interface.
class PrefsAsyncFactorySdb extends Object
    with PrefsAsyncFactoryMixin
    implements PrefsAsyncFactory {
  /// The underlying Sdb database factory.
  final sdb.SdbFactory sdbFactory;

  /// Gets the database path for a given preference name.
  String getDbPath(String name) => join(name);

  /// Creates a new [PrefsAsyncFactorySdb] instance.
  PrefsAsyncFactorySdb(this.sdbFactory);

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
  Future<PrefsAsyncMixin> newPrefs(String name) async {
    var prefs = PrefsAsyncSdb(factory: this, name: name);
    await prefs.open();
    return prefs;
  }
}

/// Helper function to create a [PrefsAsyncFactorySdb] instance.
PrefsAsyncFactorySdb getPrefsAsyncFactorySdb(sdb.SdbFactory sdbFactory) =>
    PrefsAsyncFactorySdb(sdbFactory);
