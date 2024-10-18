import 'package:path/path.dart';
import 'package:sembast/sembast.dart' as sembast;
import 'package:tekartik_common_utils/common_utils_import.dart' hide parseInt;
import 'package:tekartik_common_utils/int_utils.dart';
import 'package:tekartik_prefs/mixin/prefs_async_mixin.dart';
import 'package:tekartik_prefs/prefs_async.dart';

final store = sembast.StoreRef<String, Object?>.main();
final metaStore = sembast.StoreRef<String, Object?>('meta');
final metaVersionRecord = metaStore.record('version');
final signatureRecord = metaStore.record('signature');

class PrefsAsyncSembast extends PrefsAsyncBase
    with PrefsAsyncNoImplementationKeyMixin, PrefsAsyncKeyValueMixin {
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
    database = await _factory.databaseFactory.openDatabase(dbPath, version: 1,
        onVersionChanged:
            (sembast.Database db, int oldVersion, int newVersion) async {
      if (oldVersion == 0) {
        await signatureRecord.put(db, prefsSignatureValue);
      }
    });
  }

  /// Handle migration
  @override
  Future<void> handleMigration(
      {final int? version,
      PrefsAsyncOnVersionChangedFunction? onVersionChanged}) async {
    await lock.synchronized(() async {
      await database.transaction((txn) async {
        _openTransaction = txn;
        try {
          var signature = signatureRecord.getSync(txn);
          if (signature != prefsSignatureValue || database.version > 1) {
            await store.delete(txn);
            await metaStore.delete(txn);
            await signatureRecord.put(txn, prefsSignatureValue);
          }

          var prefsOldVersion =
              this.version = parseInt(metaVersionRecord.getSync(txn)) ?? 0;
          final prefsNewVersion = version;

          if (prefsNewVersion != null && prefsNewVersion != prefsOldVersion) {
            if (onVersionChanged != null) {
              await onVersionChanged(this, prefsOldVersion, prefsNewVersion);
              await metaVersionRecord.put(txn, prefsNewVersion);
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
      Future<T> Function(sembast.Transaction txn) action) async {
    if (_openTransaction != null) {
      return await action(_openTransaction!);
    } else {
      return await database.transaction(action);
    }
  }

  @override
  Future<void> clear() => store.delete(_client);

  @override
  Future<void> clearForDelete() {
    throw UnimplementedError();
  }

  @override
  Future<bool> containsKey(String key) => store.record(key).exists(_client);

  @override
  Future<Map<String, Object?>> getAll() async {
    var records = await store.query().getSnapshots(_client);
    return <String, Object?>{
      for (var record in records) record.key: record.value
    };
  }

  @override
  Future<Set<String>> getKeys() async =>
      (await store.findKeys(_client)).toSet();

  @override
  Future<T?> getValueNoKeyCheck<T>(String key) async {
    return checkValueType(store.record(key).getSync(_client));
  }

  @override
  Future<void> remove(String key) => store.record(key).delete(_client);

  @override
  Future<void> setValueNoKeyCheck<T>(String key, T value) =>
      store.record(key).put(_client, value);
}

class PrefsAsyncFactorySembast extends Object
    with PrefsAsyncFactoryMixin
    implements PrefsAsyncFactory {
  final sembast.DatabaseFactory databaseFactory;
  final String path;

  String getDbPath(String name) => join(path, name);

  PrefsAsyncFactorySembast(this.databaseFactory, this.path);

  /*
  @override
  Future<PrefsAsync> openPreferences(String name,
      {int? version, PrefsAsyncOnVersionChangedFunction? onVersionChanged}) async {
    name = fixName(name);

    var prefs = await lock.synchronized(() async {
      var prefs = _allPrefs[name];
      // devPrint('opening prefs $name $prefs');
      if (prefs == null) {
        prefs = PrefsSembast(this, name);
        _allPrefs[name] = prefs;

        // we read into memory
        await prefs.open(version: version, onVersionChanged: onVersionChanged);
      }

      return prefs;
    });
    return prefs;
  }*/

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
        sembast.DatabaseFactory databaseFactory, String path) =>
    PrefsAsyncFactorySembast(databaseFactory, path);
