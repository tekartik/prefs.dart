import 'package:path/path.dart';
import 'package:sembast/sembast.dart' as sembast;
import 'package:tekartik_common_utils/common_utils_import.dart' hide parseInt;
import 'package:tekartik_prefs/prefs.dart';
import 'package:tekartik_prefs/src/prefs_mixin.dart'; // ignore: implementation_imports

class PrefsSembast extends Object with PrefsMixin implements Prefs {
  final PrefsFactorySembast prefsFactorySembast;
  @override
  final String name;
  @override
  int version = 0;
  late sembast.Database database;
  final store = sembast.StoreRef<String, Object?>.main();

  PrefsSembast(this.prefsFactorySembast, this.name);

  String get dbPath => prefsFactorySembast.getDbPath(name);

  @override
  Future close() async {
    await save();
    _allPrefs.remove(name);
    await database.close();
  }

  @override
  Future save() async {
    if (changes.isNotEmpty) {
      final changes = Map<String, Object?>.from(this.changes);
      // devPrint(changes);
      importChanges();

      // save
      await database.transaction((txn) async {
        var futures = <Future>[];
        changes.forEach((String key, dynamic value) {
          // devPrint('saving $key $value ${value.runtimeType}');
          var record = store.record(key);
          if (value == null) {
            futures.add(record.delete(txn));
          } else {
            futures.add(record.put(txn, value));
          }
        });
        await Future.wait(futures);
      });
    }
  }

  Future open() async {
    var signatureRecord = store.record(signatureKey);
    // devPrint('opening $dbPath');
    database = await prefsFactorySembast.databaseFactory
        .openDatabase(dbPath, version: 1, onVersionChanged:
            (sembast.Database db, int oldVersion, int newVersion) async {
      if (oldVersion == 0) {
        await signatureRecord.put(db, signatureValue);
      }
    });

    await database.transaction((txn) async {
      var signature = await signatureRecord.get(txn);
      if (signature != signatureValue || database.version > 1) {
        await store.delete(txn);
        await signatureRecord.put(txn, signatureValue);
      } else {
        version = parseInt(await store.record(prefsVersionKey).get(txn)) ?? 0;
      }

      // load all
      var records = await store.find(txn);
      for (var record in records) {
        data[record.key] = record.value;
      }
    });
  }
}

final _allPrefs = <String, PrefsSembast>{};

class PrefsFactorySembast extends Object
    with PrefsFactoryMixin
    implements PrefsFactory {
  final sembast.DatabaseFactory databaseFactory;
  final String path;

  String getDbPath(String name) => join(path, name);
  final lock = Lock();

  PrefsFactorySembast(this.databaseFactory, this.path);

  @override
  Future<Prefs> openPreferences(String name,
      {int? version,
      Future Function(Prefs pref, int oldVersion, int newVersion)?
          onVersionChanged}) async {
    name = fixName(name);

    var prefs = await lock.synchronized(() async {
      var prefs = _allPrefs[name];
      // devPrint('opening prefs $name $prefs');
      if (prefs == null) {
        prefs = PrefsSembast(this, name);
        _allPrefs[name] = prefs;

        // we read into memory
        await prefs.open();
      }

      final oldVersion = prefs.version;
      if (version != null && version != oldVersion) {
        if (onVersionChanged != null) {
          await onVersionChanged(prefs, oldVersion, version);
        }
        prefs.version = version;
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
      // devPrint('deleting prefs $name $prefs');
      if (prefs != null) {
        await prefs.close();
      }
      await databaseFactory.deleteDatabase(getDbPath(name));
    });
  }

  @override
  bool get hasStorage => databaseFactory.hasStorage;
}

PrefsFactorySembast getPrefsFactorySembast(
        sembast.DatabaseFactory databaseFactory, String path) =>
    PrefsFactorySembast(databaseFactory, path);
