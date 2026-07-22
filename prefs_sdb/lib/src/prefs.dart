import 'package:idb_shim/sdb/sdb.dart' as sdb;
import 'package:tekartik_common_utils/common_utils_import.dart' hide parseInt;
import 'package:tekartik_prefs/prefs.dart';
import 'package:tekartik_prefs/src/prefs_mixin.dart'; // ignore: implementation_imports

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

/// Sdb implementation of the [Prefs] interface.
class PrefsSdb extends Object with PrefsMixin implements Prefs {
  /// The factory that created this instance.
  final PrefsFactorySdb prefsFactorySdb;

  @override
  final String name;

  @override
  int version = 0;

  /// The underlying Sdb database instance.
  late sdb.SdbDatabase database;

  /// The main store ref for preferences.
  final store = sdb.SdbStoreRef<String, Object>('main');

  /// The metadata store ref.
  final metaStore = sdb.SdbStoreRef<String, Object>('meta');

  /// Record ref for the preferences version.
  late final metaVersionRecord = metaStore.record('version');

  /// Record ref for the signature.
  late final signatureRecord = metaStore.record('signature');

  /// Creates a new [PrefsSdb] instance.
  PrefsSdb(this.prefsFactorySdb, this.name);

  /// Gets the database file path.
  String get dbPath => prefsFactorySdb.getDbPath(name);

  @override
  Future close() async {
    await save();
    _allPrefs.remove(name);
    await database.close();
  }

  Future? _saveFuture;

  @override
  Future save() {
    _saveFuture ??= () async {
      try {
        if (changes.isNotEmpty) {
          final changes = Map<String, Object?>.from(this.changes);

          importChanges();

          // save
          await database.inStoreTransaction(
            store,
            sdb.SdbTransactionMode.readWrite,
            (txn) async {
              var futures = <Future>[];
              changes.forEach((String key, dynamic value) {
                if (value == null) {
                  futures.add(txn.delete(key));
                } else {
                  futures.add(txn.put(key, _sdbSanitizeValue(value) as Object));
                }
              });
              await Future.wait(futures);
            },
          );
        }
      } finally {
        _saveFuture = null;
      }
    }();
    return _saveFuture!;
  }

  /// Opens the preferences database and loads records into memory.
  Future open({
    final int? version,
    PrefsOnVersionChangedFunction? onVersionChanged,
  }) async {
    final prefsNewVersion = version;
    late final int prefsOldVersion;

    final sdbSchema = sdb.SdbDatabaseSchema(
      stores: [store.schema(), metaStore.schema()],
    );

    database = await prefsFactorySdb.sdbFactory.openDatabase(
      dbPath,
      options: sdb.SdbOpenDatabaseOptions(
        version: 1,
        schema: sdbSchema,
        onVersionChange: (event) async {
          if (event.oldVersion == 0) {
            await signatureRecord.put(event.transaction, prefsSignatureValue);
          }
        },
      ),
    );

    await database.inStoresTransaction(
      [store, metaStore],
      sdb.SdbTransactionMode.readWrite,
      (txn) async {
        var txnStore = txn.store(store);
        var txnMetaStore = txn.store(metaStore);
        var signature = await txnMetaStore.getValue('signature');

        if (signature != prefsSignatureValue || database.version > 1) {
          await txnStore.deleteRecords();
          await txnMetaStore.deleteRecords();
          await txnMetaStore.put('signature', prefsSignatureValue);
        }
        prefsOldVersion = parseInt(await txnMetaStore.getValue('version')) ?? 0;

        // load all
        var records = await txnStore.findRecords();
        for (var record in records) {
          data[record.key] = record.value;
        }

        this.version = prefsOldVersion;
        if (prefsNewVersion != null && prefsNewVersion != prefsOldVersion) {
          if (onVersionChanged != null) {
            await onVersionChanged(this, prefsOldVersion, prefsNewVersion);
            await txnMetaStore.put('version', prefsNewVersion);
          }
          this.version = prefsNewVersion;
        }
      },
    );
  }
}

final _allPrefs = <String, PrefsSdb>{};

/// Sdb implementation of the [PrefsFactory] interface.
class PrefsFactorySdb extends Object
    with PrefsFactoryMixin
    implements PrefsFactory {
  /// The underlying Sdb database factory.
  final sdb.SdbFactory sdbFactory;

  /// Gets the database path for a given preference name.
  String getDbPath(String name) => name;

  /// Synchronized lock.
  final lock = Lock();

  /// Creates a new [PrefsFactorySdb] instance.
  PrefsFactorySdb(this.sdbFactory);

  @override
  Future<Prefs> openPreferences(
    String name, {
    int? version,
    PrefsOnVersionChangedFunction? onVersionChanged,
  }) async {
    name = fixName(name);

    var prefs = await lock.synchronized(() async {
      var prefs = _allPrefs[name];
      if (prefs == null) {
        prefs = PrefsSdb(this, name);
        _allPrefs[name] = prefs;

        // we read into memory
        await prefs.open(version: version, onVersionChanged: onVersionChanged);
      }

      return prefs;
    });
    return prefs;
  }

  @override
  Future deletePreferences(String name) async {
    name = fixName(name);

    await lock.synchronized(() async {
      var prefs = _allPrefs[name];
      if (prefs != null) {
        await prefs.close();
      }
      await sdbFactory.deleteDatabase(getDbPath(name));
    });
  }

  @override
  bool get hasStorage => sdbFactory.idbFactory.persistent;
}

/// Helper function to create a [PrefsFactorySdb] instance.
PrefsFactorySdb getPrefsFactorySdb(sdb.SdbFactory sdbFactory) =>
    PrefsFactorySdb(sdbFactory);
