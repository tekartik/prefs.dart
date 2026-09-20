---
name: tekartik-prefs-sembast-setup
description: >-
  Use when backing tekartik_prefs with a sembast database through
  tekartik_prefs_sembast: getPrefsAsyncFactorySembast,
  getPrefsAsyncWithCacheFactorySembast, getPrefsFactorySembast,
  getPrefsLightSembast(databaseFactory:, path:), the
  package:tekartik_prefs_sembast/prefs_async.dart, prefs.dart and
  prefs_light.dart imports, choosing a sembast DatabaseFactory
  (databaseFactoryIo, newDatabaseFactoryMemory, sembast_web, sembast_sqflite),
  the one-database-per-prefs-name layout, and running the tekartik_prefs_test
  suites against it.
---

# tekartik_prefs_sembast: prefs on sembast (tekartik_prefs_sembast)

`tekartik_prefs_sembast` implements the `tekartik_prefs` factories on top of
`sembast`. Each prefs store is one sembast database file under a directory you
choose, which makes it the natural backend for a command line tool, a server or
a Flutter app that already embeds sembast.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_prefs_sembast:
      git:
        url: https://github.com/tekartik/prefs.dart
        path: prefs_sembast
    sembast: '>=3.7.4+3'
  ```
  It brings `tekartik_prefs` (same repo, `path: prefs`); declare `sembast`
  yourself since you must pick the `DatabaseFactory`.
* Imports, each re-exporting its `tekartik_prefs` counterpart, so one import
  gives both the interfaces and the factory builder:
  * `package:tekartik_prefs_sembast/prefs_async.dart`:
    `getPrefsAsyncFactorySembast(databaseFactory, path)` and
    `getPrefsAsyncWithCacheFactorySembast(databaseFactory, path)` (both
    positional arguments).
  * `package:tekartik_prefs_sembast/prefs.dart`:
    `getPrefsFactorySembast(databaseFactory, path)` (legacy synchronous API).
  * `package:tekartik_prefs_sembast/prefs_light.dart`:
    `getPrefsLightSembast(databaseFactory: , path: )` (named arguments), a
    single lazily opened `PrefsLight` store on `prefs.db` under `path`.
* `path` is the directory holding the databases: the database of a prefs store
  is `join(path, prefsName)`. Use an app support directory in production
  (`path_provider` in Flutter) and something like
  `join('.dart_tool', 'my_app')` in tests. `'.'` is fine with an in-memory
  factory.
* Pick the sembast `DatabaseFactory`: `databaseFactoryIo` from
  `package:sembast/sembast_io.dart` (VM, Flutter native),
  `newDatabaseFactoryMemory()` or `databaseFactoryMemory` from
  `package:sembast/sembast_memory.dart` (tests), `databaseFactoryWeb` from the
  separate `sembast_web` package on the web, or `sembast_sqflite` on mobile.
  `factory.hasStorage` mirrors the sembast factory, so it is `false` for
  memory.
* Build the prefs factory once and reuse it: the opened prefs are cached per
  name inside a factory instance, so two factories over the same path would
  open the same database twice.
* `factory.sandbox(path: 'sub')` (the `tekartik_prefs` extension) prefixes the
  prefs names, i.e. it adds a sub-directory under the factory `path`. A name
  escaping the root throws an `ArgumentError`.
* `deletePreferences(name)` closes the prefs and deletes the database file.
  `prefs.close()` flushes pending writes and closes the database, so the sync
  `Prefs` needs `save()` or `close()` for the values to hit the disk.
* Storage layout: values live in the sembast main store keyed by the prefs key,
  version and signature in a `meta` store. Keep values json encodable (sembast
  only stores json types).
* Anti-patterns: importing `package:sembast/sembast_io.dart` in code compiled
  for the web; sharing one database between the sync and the async families;
  putting application data in prefs — open a sembast database of your own for
  that, the two can share the same `DatabaseFactory`.
* Testing: the shared suites from `tekartik_prefs_test` (dev dependency,
  `path: prefs_test`) run against any factory — `runPrefsTests`,
  `runPrefsAsyncTests`, `runPrefsAsyncWithCacheTests`, `runPrefsLightTests`
  and `runKvStoreTests`. Use `newDatabaseFactoryMemory()` for a platform
  independent test, `databaseFactoryIo` under `@TestOn('vm')`.

## Examples

### Async prefs on an in-memory database

```dart
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_prefs_sembast/prefs_async.dart';

Future<void> main() async {
  var factory = getPrefsAsyncFactorySembast(newDatabaseFactoryMemory(), '.');
  var prefs = await factory.openPreferences('my_app.prefs', version: 1);

  await prefs.setString('user', 'alex');
  await prefs.setMap('window', {'width': 800, 'height': 600});
  print(await prefs.getString('user')); // alex
  print(await prefs.getMap('window'));

  await prefs.close();
  await factory.deletePreferences('my_app.prefs');
}
```

### Persistent prefs in a directory, cached reads

```dart
import 'package:path/path.dart';
import 'package:sembast/sembast_io.dart';
import 'package:tekartik_prefs_sembast/prefs_async.dart';

/// One factory for the whole app.
final prefsFactory = getPrefsAsyncWithCacheFactorySembast(
  databaseFactoryIo,
  join('.dart_tool', 'my_app', 'prefs'),
);

class AppSettings {
  final PrefsAsyncWithCache prefs;

  AppSettings(this.prefs);

  static Future<AppSettings> open() async => AppSettings(
    await prefsFactory.openPreferences(
      'settings',
      version: 1,
      onVersionChanged: (prefs, oldVersion, newVersion) async {
        if (oldVersion == 0) {
          await prefs.setBool('dark', false);
        }
      },
    ),
  );

  // Synchronous once opened.
  bool get dark => prefs.getBool('dark') ?? false;

  Future<void> setDark(bool value) => prefs.setBool('dark', value);
}

Future<void> main() async {
  var settings = await AppSettings.open();
  await settings.setDark(true);
  print(settings.dark); // true
  await settings.prefs.close();
}
```

### Legacy synchronous prefs

```dart
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_prefs_sembast/prefs.dart';

Future<void> main() async {
  var factory = getPrefsFactorySembast(newDatabaseFactoryMemory(), '.');

  // 'sub' becomes a sub directory of the factory path.
  var sandboxFactory = factory.sandbox(path: 'sub');
  var prefs = await sandboxFactory.openPreferences('settings');

  prefs.setBool('dark', true);
  print(prefs.getBool('dark')); // true, synchronous
  await prefs.save(); // flush the background write
  await prefs.close();
}
```

### A single light store

```dart
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_prefs_sembast/prefs_light.dart';

Future<void> main() async {
  // Opens '<path>/prefs.db' lazily, on first access.
  var prefs = getPrefsLightSembast(
    databaseFactory: newDatabaseFactoryMemory(),
    path: '.',
  );

  await prefs.setString('user', 'alex');
  await prefs.setInt('count', 3);
  print(await prefs.getString('user')); // alex

  // It is also a KvStore.
  KvStore store = prefs;
  await store.setStringOrNull('user', null);
  print(await store.getString('user')); // null
}
```

### Run the shared tekartik_prefs_test suites

```dart
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_prefs_sembast/prefs.dart';
import 'package:tekartik_prefs_sembast/prefs_async.dart';
import 'package:tekartik_prefs_sembast/prefs_light.dart';
import 'package:tekartik_prefs_test/kv_store_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_async_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_async_with_cache_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_light_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_test_runner.dart' as prefs;
import 'package:test/test.dart';

void main() {
  prefs.runPrefsTests(getPrefsFactorySembast(newDatabaseFactoryMemory(), '.'));
  runPrefsAsyncTests(
    getPrefsAsyncFactorySembast(newDatabaseFactoryMemory(), '.'),
  );
  runPrefsAsyncWithCacheTests(
    getPrefsAsyncWithCacheFactorySembast(newDatabaseFactoryMemory(), '.'),
  );
  runPrefsLightTests(
    getPrefsLightSembast(databaseFactory: newDatabaseFactoryMemory(), path: '.'),
  );
  group('kv_store', () {
    runKvStoreTests(
      getPrefsLightSembast(
        databaseFactory: newDatabaseFactoryMemory(),
        path: '.',
      ),
    );
  });
}
```
