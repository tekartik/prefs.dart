import 'package:path/path.dart';
import 'package:sembast/sembast.dart' as sembast;
import 'package:tekartik_common_utils/common_utils_import.dart' hide parseInt;
import 'package:tekartik_common_utils/int_utils.dart';
import 'package:tekartik_prefs/mixin/prefs_async_mixin.dart';
import 'package:tekartik_prefs/prefs_async.dart';

final _store = sembast.StoreRef<String, Object?>.main();
final _metaStore = sembast.StoreRef<String, Object?>('meta');
final _metaVersionRecord = _metaStore.record('version');
final _signatureRecord = _metaStore.record('signature');

class PrefsAsyncSembast extends PrefsAsyncBase
    with
        PrefsCommonMixin,
        PrefsAsyncNoImplementationKeyMixin,
        PrefsAsyncKeyValueMixin,
        PrefsAsyncReadKeyValueMixin,
        PrefsAsyncWriteKeyValueMixin,
        PrefsAsyncValueMixin {
  PrefsAsyncFactorySembast get _factory =>
      this.factory as PrefsAsyncFactorySembast;

  late sembast.Database database;

  PrefsAsyncSembast({required super.factory, required super.name});

  String get dbPath => _factory.getDbPath(name);

  @override
  Future close() async {
    await database.close();
    await super.close();
  }

  sembast.Transaction? _openTransaction;

  Future open() async {
    database = await _factory.databaseFactory.openDatabase(
      dbPath,
      version: 1,
      onVersionChanged: (
        sembast.Database db,
        int oldVersion,
        int newVersion,
      ) async {
        if (oldVersion == 0) {
          await _signatureRecord.put(db, prefsSignatureValue);
        }
      },
    );
  }

  /// Handle migration
  @override
  Future<void> handleMigration({
    final int? version,
    PrefsAsyncOnVersionChangedFunction? onVersionChanged,
  }) async {
    await lock.synchronized(() async {
      await database.transaction((txn) async {
        _openTransaction = txn;
        try {
          var signature = _signatureRecord.getSync(txn);
          if (signature != prefsSignatureValue || database.version > 1) {
            await _store.delete(txn);
            await _metaStore.delete(txn);
            await _signatureRecord.put(txn, prefsSignatureValue);
          }

          var prefsOldVersion =
              this.version = parseInt(_metaVersionRecord.getSync(txn)) ?? 0;
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
      });
    });
  }

  sembast.DatabaseClient get _client => _openTransaction ?? database;

  // ignore: unused_element
  Future<T> _transaction<T>(
    Future<T> Function(sembast.Transaction txn) action,
  ) async {
    if (_openTransaction != null) {
      return await action(_openTransaction!);
    } else {
      return await database.transaction(action);
    }
  }

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
    var records = await _store.query().getSnapshots(_client);
    return <String, Object?>{
      for (var record in records) record.key: record.value,
    };
  }

  @override
  Future<Set<String>> getKeys() async =>
      (await _store.findKeys(_client)).toSet();

  @override
  Future<T?> getValueNoKeyCheck<T>(String key) async {
    return checkValueType(await _store.record(key).get(_client));
  }

  @override
  Future<void> remove(String key) => _store.record(key).delete(_client);

  @override
  Future<void> setValueNoKeyCheck<T>(String key, T value) =>
      _store.record(key).put(_client, value);
}

class PrefsAsyncFactorySembast extends Object
    with PrefsAsyncFactoryMixin
    implements PrefsAsyncFactory {
  final sembast.DatabaseFactory databaseFactory;
  final String path;

  String getDbPath(String name) => join(path, name);

  /// path is the root path
  PrefsAsyncFactorySembast(this.databaseFactory, this.path);

  @override
  Future deletePreferences(String name) async {
    name = fixName(name);
    await lock.synchronized(() async {
      var prefs = allPrefs[name];
      // devPrint('deleting prefs $name $prefs');
      if (prefs != null) {
        await prefs.close();
      }
      await databaseFactory.deleteDatabase(getDbPath(name));
    });
  }

  @override
  Future<PrefsAsyncMixin> newPrefs(String name) async {
    var prefs = PrefsAsyncSembast(factory: this, name: name);
    await prefs.open();
    return prefs;
  }
}

PrefsAsyncFactorySembast getPrefsAsyncFactorySembast(
  sembast.DatabaseFactory databaseFactory,
  String path,
) => PrefsAsyncFactorySembast(databaseFactory, path);
