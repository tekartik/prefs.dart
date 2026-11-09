# tekartik_prefs_sdb

[tekartik_prefs](../prefs/README.md) stored in an sdb database (the typed
database API of `idb_shim`): IndexedDB on the web, a sembast file on the Dart
VM and Flutter native, memory in tests. One database per prefs name.

## Getting started

Git package, not on pub.dev; add `idb_shim` to pick the `SdbFactory`:

```yaml
dependencies:
  tekartik_prefs_sdb:
    git:
      url: https://github.com/tekartik/prefs.dart
      path: prefs_sdb
  idb_shim: '>=2.9.4'
```

```dart
import 'package:idb_shim/sdb/sdb.dart';
import 'package:tekartik_prefs_sdb/prefs_async.dart';

Future<void> main() async {
  // sdbFactoryWeb on the web, sdbFactoryIo on the VM, memory in tests.
  var factory = getPrefsAsyncFactorySdb(newSdbFactoryMemory());
  var prefs = await factory.openPreferences('settings', version: 1);
  await prefs.setString('user', 'alex');
  print(await prefs.getString('user')); // alex
  await prefs.close();
}
```

Runnable: [example/main.dart](example/main.dart).

## Platforms and factories

| `SdbFactory` (`package:idb_shim/sdb/sdb.dart`) | Platform |
|---|---|
| `sdbFactoryWeb` | web (IndexedDB) |
| `sdbFactoryIo` | Dart VM, Flutter native (sembast files) |
| `newSdbFactoryMemory()`, `sdbFactoryMemory` | any, tests |

Builders: `getPrefsAsyncFactorySdb`, `getPrefsAsyncWithCacheFactorySdb`
(`prefs_async.dart`), `getPrefsLightSdb` (`prefs_light.dart`),
`getPrefsFactorySdb` (`prefs.dart`, older sync API). Use
`sdbFactory.sandbox(path: ...)` to keep the prefs databases in a folder.

## Common pitfalls

* Build the prefs factory once: each one caches its opened prefs.
* Async prefs: `onVersionChanged` runs inside the IndexedDB transaction of the
  open. Await only this prefs there; awaiting anything else (a delay, another
  database) lets the transaction commit and the open fails with
  `DatabaseInactiveError`. The sync `Prefs` calls it after the transaction.
* `deletePreferences(name)` closes the prefs and deletes its database: writes
  through an instance kept from before fail (an exception for the async
  prefs, an uncaught error from the background save for the sync one).
* Maps and lists are stored as plain JSON types.

## Testing

```bash
dart test -p vm
dart test -p chrome
```

The tests run every `tekartik_prefs_test` suite on memory, io and web sdb
factories.
