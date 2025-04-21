import 'package:shared_preferences/shared_preferences.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_prefs/prefs.dart';
import 'package:tekartik_prefs/src/prefs_mixin.dart'; // ignore: implementation_imports

// ignore: implementation_imports

class PrefsFlutter extends Object with PrefsMixin implements Prefs {
  final PrefsFactoryFlutter factory;

  SharedPreferences? get sharedPreferences => factory.sharedPreferences;
  @override
  final String name;

  @override
  int version = 0;

  PrefsFlutter(this.factory, this.name);

  @override
  Future close() async {
    await save();
    _allPrefs.remove(name);
  }

  String getKey(String name) => '${this.name}/$name';

  @override
  dynamic getSourceValue(String name) {
    var key = getKey(name);
    var value = sharedPreferences!.get(key);
    // devPrint('loading $name: $value ${value?.runtimeType}');
    return value;
  }

  @override
  Future save() async {
    if (changes.isNotEmpty) {
      var changes = Map<String, Object?>.from(this.changes);
      importChanges();
      if (pendingClear) {
        pendingClear = false;
        await sharedPreferences!.clear();
      }
      var futures = <Future>[];
      changes.forEach((String name, value) {
        // devPrint('saving $name: $value');
        var key = getKey(name);
        if (value == null) {
          futures.add(sharedPreferences!.remove(key));
        } else if (value is int) {
          futures.add(sharedPreferences!.setInt(key, value));
        } else if (value is bool) {
          futures.add(sharedPreferences!.setBool(key, value));
        } else if (value is String) {
          futures.add(sharedPreferences!.setString(key, value));
        } else if (value is double) {
          futures.add(sharedPreferences!.setDouble(key, value));
        } else {
          futures.add(sharedPreferences!.setString(key, encodeJson(value)!));
        }
      });
      await Future.wait(futures);
    }
  }

  @override
  Set<String> get keys {
    var keys = <String>{};
    for (var key in sharedPreferences!.getKeys()) {
      if (key.startsWith('$name/')) {
        keys.add(key.substring(name.length + 1));
      }
    }
    return keys..addAll(super.keys);
  }
}

final _allPrefs = <String?, PrefsFlutter>{};

class PrefsFactoryFlutter extends Object
    with PrefsFactoryMixin
    implements PrefsFactory {
  SharedPreferences? sharedPreferences;
  SharedPreferencesAsync? sharedPreferencesAsync;
  final lock = Lock();

  @override
  Future deletePreferences(String name) async {
    _allPrefs.remove(name);
    await lock.synchronized(() async {
      sharedPreferences ??= await SharedPreferences.getInstance();
      var futures = <Future>[];
      for (var key in sharedPreferences!.getKeys()) {
        if (key.startsWith('$name/')) {
          futures.add(sharedPreferences!.remove(key));
        }
      }
      await Future.wait(futures);
    });
  }

  @override
  bool get hasStorage => true;

  @override
  Future<Prefs> openPreferences(
    String name, {
    final int? version,
    PrefsOnVersionChangedFunction? onVersionChanged,
  }) async {
    var prefs = await lock.synchronized(() async {
      sharedPreferences ??= await SharedPreferences.getInstance();
      var prefs = _allPrefs[name];

      if (prefs == null) {
        prefs = PrefsFlutter(this, name);
        _allPrefs[name] = prefs;
      }

      await prefs.handleMigration(
        version: version,
        onVersionChanged: onVersionChanged,
      );
      return prefs;
    });
    return prefs;
  }
}

PrefsFactoryFlutter? _prefsFactoryFlutter;

PrefsFactory get prefsFactoryFlutter =>
    _prefsFactoryFlutter ??= PrefsFactoryFlutter();

/*

class PrefsSembast extends Object with PrefsMixin implements Prefs {
  final PrefsFactorySembast prefsFactorySembast;
  final String name;
  int version = 0;
  sembast.Database database;

  PrefsSembast(this.prefsFactorySembast, this.name);

  String get dbPath => this.prefsFactorySembast.getDbPath(name);

  @override
  Future close() async {
    await save();
    _allPrefs.remove(name);
  }

  @override
  Future save() async {
    if (this.changes.isNotEmpty) {
      Map<String, Object?> changes = Map.from(this.changes);
      // devPrint(changes);
      importChanges();

      // save
      await database.transaction((txn) async {
        var futures = <Future>[];
        changes.forEach((String key, dynamic value) {
          // devPrint('saving $key $value ${value.runtimeType}');
          if (value == null) {
            futures.add(txn.delete(key));
          } else {
            futures.add(txn.put(value, key));
          }
        });
        await Future.wait(futures);
      });
    }
  }

  Future open() async {
    database = await prefsFactorySembast.databaseFactory
        .openDatabase(dbPath, version: 1, onVersionChanged:
            (sembast.Database db, int oldVersion, int newVersion) async {
      if (oldVersion == 0) {
        await db.put(signatureValue, signatureKey);
      }
    });

    await database.transaction((txn) async {
      var signature = await txn.get(signatureKey);
      if (signature != signatureValue || database.version > 1) {
        await txn.mainStore.clear();
        await txn.mainStore.put(signatureValue, signatureKey);
      } else {
        this.version = parseInt(await txn.get(prefsVersionKey)) ?? 0;
      }

      // load all
      var records = await txn.findRecords(sembast.Finder());
      for (var record in records) {
        data[record.key as String] = record.value;
      }
    });
  }
}


class PrefsFactorySembast extends Object
    with PrefsFactoryMixin
    implements PrefsFactory {
  final sembast.DatabaseFactory databaseFactory;
  final String path;

  String getDbPath(String name) => join(path, name);
  final lock = Lock();
  PrefsFactorySembast(this.databaseFactory, this.path);

  @override
  Future deletePreferences(String name) async {
    await lock.synchronized(() async {
      _allPrefs.remove(name);
      await databaseFactory.deleteDatabase(getDbPath(name));
    });
  }

  @override
  bool get hasStorage => databaseFactory.hasStorage;
}

PrefsFactorySembast getPrefsFactorySembast(
        sembast.DatabaseFactory databaseFactory, String path) =>
    PrefsFactorySembast(databaseFactory, path);

 */
