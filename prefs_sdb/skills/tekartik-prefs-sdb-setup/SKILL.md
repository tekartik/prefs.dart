---
name: tekartik-prefs-sdb-setup
description: >-
  Use when backing tekartik_prefs with an sdb database (idb_shim: indexed_db on
  the web, sembast io on the VM) through tekartik_prefs_sdb:
  getPrefsAsyncFactorySdb, getPrefsAsyncWithCacheFactorySdb, getPrefsFactorySdb,
  getPrefsLightSdb, the package:tekartik_prefs_sdb/prefs_async.dart, prefs.dart
  and prefs_light.dart imports, choosing an SdbFactory (sdbFactoryWeb,
  sdbFactoryIo, newSdbFactoryMemory, sdbFactory.sandbox(path:)), and running the
  tekartik_prefs_test suites against it.
---

# tekartik_prefs_sdb: prefs on sdb (tekartik_prefs_sdb)

`tekartik_prefs_sdb` implements the `tekartik_prefs` factories on top of `sdb`,
the simple typed database API of `idb_shim`. One prefs store is one sdb
database, so the same code persists to indexed_db on the web, to a sembast file
on the Dart VM and to memory in tests, without touching the app code.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_prefs_sdb:
      git:
        url: https://github.com/tekartik/prefs.dart
        path: prefs_sdb
    idb_shim: '>=2.9.4'
  ```
  It brings `tekartik_prefs` (same repo, `path: prefs`); declare `idb_shim`
  yourself since you must pick the `SdbFactory`.
* Imports, each re-exporting its `tekartik_prefs` counterpart, so one import
  gives both the interfaces and the factory builder:
  * `package:tekartik_prefs_sdb/prefs_async.dart`:
    `getPrefsAsyncFactorySdb(sdbFactory)` and
    `getPrefsAsyncWithCacheFactorySdb(sdbFactory)`.
  * `package:tekartik_prefs_sdb/prefs.dart`: `getPrefsFactorySdb(sdbFactory)`
    (legacy synchronous API).
  * `package:tekartik_prefs_sdb/prefs_light.dart`:
    `getPrefsLightSdb(sdbFactory, name: )`, a single `PrefsLight` store
    (database name defaults to `prefs.db`).
  The `SdbFactory` type and the concrete factories come from
  `package:idb_shim/sdb/sdb.dart`.
* Pick the `SdbFactory` per platform: `sdbFactoryWeb` (indexed_db, web only),
  `sdbFactoryIo` (sembast io, VM/Flutter native only), `sdbFactoryMemory` or
  `newSdbFactoryMemory()` for tests. `sdbFactoryFromIdb(idbFactory)` wraps any
  other `idb_shim` factory (`idb_sqflite`, a worker, ...).
* Scope the databases with the idb_shim `sandbox(path:)` extension on the
  factory (`sdbFactoryIo.sandbox(path: join('.dart_tool', 'my_app'))`): the
  prefs name is used directly as the database name/path, so a sandbox keeps
  the prefs databases out of the way of the rest of the app, and is what tests
  should do. The `tekartik_prefs` `factory.sandbox(path:)` extension also works
  on the returned prefs factories (it prefixes the prefs name).
* All the `get...FactorySdb` functions build a new factory object each call, but
  the opened prefs are cached per name inside it: build the factory once and
  reuse it, or two factories will open the same database twice.
* `hasStorage` reflects the underlying idb factory (`false` for memory).
  `deletePreferences(name)` closes the prefs and deletes the whole database.
* Values are stored in an sdb `main` store keyed by the prefs key, with version
  and signature in a `meta` store. Maps and lists are sanitized to plain json
  types before writing, so keep values json encodable.
* Anti-patterns: using `sdbFactoryIo` in code compiled for the web (or
  `sdbFactoryWeb` on the VM); rebuilding the prefs factory on every access;
  opening the same database name through both the sync and the async families.
* Testing: the shared suites from `tekartik_prefs_test` (dev dependency,
  `path: prefs_test`) run against any factory —
  `runPrefsTests`, `runPrefsAsyncTests`, `runPrefsAsyncWithCacheTests`,
  `runPrefsLightTests` and `runKvStoreTests`. Use `newSdbFactoryMemory()` for a
  platform-independent test, `sdbFactoryIo` under `@TestOn('vm')` and
  `sdbFactoryWeb` under `@TestOn('browser')`.

## Examples

### Async prefs on an in-memory sdb (tests, no platform dependency)

```dart
import 'package:idb_shim/sdb/sdb.dart';
import 'package:tekartik_prefs_sdb/prefs_async.dart';

Future<void> main() async {
  var factory = getPrefsAsyncFactorySdb(newSdbFactoryMemory());
  var prefs = await factory.openPreferences('my_app.prefs', version: 1);

  await prefs.setString('user', 'alex');
  await prefs.setMap('window', {'width': 800, 'height': 600});
  print(await prefs.getString('user')); // alex
  print(await prefs.getMap('window'));

  await prefs.close();
  await factory.deletePreferences('my_app.prefs');
}
```

### One factory per platform, shared app code

```dart
import 'package:idb_shim/sdb/sdb.dart';
import 'package:tekartik_prefs_sdb/prefs_async.dart';

/// Keep the databases below a known path.
PrefsAsyncWithCacheFactory prefsFactory(SdbFactory sdbFactory) =>
    getPrefsAsyncWithCacheFactorySdb(sdbFactory.sandbox(path: 'my_app'));

class AppSettings {
  final PrefsAsyncWithCache prefs;

  AppSettings(this.prefs);

  static Future<AppSettings> open(SdbFactory sdbFactory) async => AppSettings(
    await prefsFactory(sdbFactory).openPreferences('settings', version: 1),
  );

  // Synchronous once opened.
  bool get dark => prefs.getBool('dark') ?? false;

  Future<void> setDark(bool value) => prefs.setBool('dark', value);
}

Future<void> main() async {
  // sdbFactoryWeb on the web, sdbFactoryIo on the VM, memory in tests.
  var settings = await AppSettings.open(newSdbFactoryMemory());
  await settings.setDark(true);
  print(settings.dark); // true
}
```

### On the Dart VM, in a chosen directory

```dart
@TestOn('vm')
library;

import 'package:idb_shim/sdb/sdb.dart';
import 'package:path/path.dart';
import 'package:tekartik_prefs_sdb/prefs.dart';
import 'package:test/test.dart';

void main() {
  var sdbFactory = sdbFactoryIo.sandbox(
    path: join('.dart_tool', 'my_app', 'prefs'),
  );

  test('legacy sync prefs on io', () async {
    var factory = getPrefsFactorySdb(sdbFactory);
    var prefs = await factory.openPreferences('settings');
    prefs.setBool('dark', true);
    await prefs.save(); // flush the background write
    expect(prefs.getBool('dark'), true);
    await prefs.close();
  });
}
```

### A single light store

```dart
import 'package:idb_shim/sdb/sdb.dart';
import 'package:tekartik_prefs_sdb/prefs_light.dart';

Future<void> main() async {
  // Opens 'prefs.db' lazily, on first access.
  var prefs = getPrefsLightSdb(newSdbFactoryMemory(), name: 'prefs.db');

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
import 'package:idb_shim/sdb/sdb.dart';
import 'package:tekartik_prefs_sdb/prefs.dart';
import 'package:tekartik_prefs_sdb/prefs_async.dart';
import 'package:tekartik_prefs_sdb/prefs_light.dart';
import 'package:tekartik_prefs_test/kv_store_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_async_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_async_with_cache_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_light_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_test_runner.dart' as prefs;
import 'package:test/test.dart';

void main() {
  prefs.runPrefsTests(getPrefsFactorySdb(newSdbFactoryMemory()));
  runPrefsAsyncTests(getPrefsAsyncFactorySdb(newSdbFactoryMemory()));
  runPrefsAsyncWithCacheTests(
    getPrefsAsyncWithCacheFactorySdb(newSdbFactoryMemory()),
  );
  runPrefsLightTests(getPrefsLightSdb(newSdbFactoryMemory()));
  group('kv_store', () {
    runKvStoreTests(getPrefsLightSdb(newSdbFactoryMemory()));
  });
}
```
