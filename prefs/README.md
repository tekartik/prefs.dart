# tekartik_prefs

Storage agnostic preferences for Dart: named, versioned key/value stores
(`bool`, `int`, `double`, `String`, `List<String>`, JSON maps and lists) with
one API on every platform. This package holds the API and the memory
implementation; a backend package stores the data.

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_prefs:
    git:
      url: https://github.com/tekartik/prefs.dart
      path: prefs
```

```dart
import 'package:tekartik_prefs/prefs_async.dart';

Future<void> main() async {
  // A backend factory in an app, see below.
  var factory = newPrefsAsyncFactoryMemory();
  var prefs = await factory.openPreferences(
    'settings',
    version: 1,
    onVersionChanged: (prefs, oldVersion, newVersion) async {
      if (oldVersion == 0) {
        await prefs.setString('theme', 'dark'); // first run defaults
      }
    },
  );
  print(await prefs.getString('theme')); // dark
  await prefs.setInt('count', 1);
  await prefs.setMap('window', {'width': 800});
  print(await prefs.getMap('window')); // {width: 800}
  await prefs.close();
}
```

## Backends

| Platform | Package (same repo) | Factory |
|---|---|---|
| Any, in memory (tests) | `tekartik_prefs` | `prefsAsyncFactoryMemory`, `newPrefsAsyncFactoryMemory()` |
| Flutter (shared_preferences) | `tekartik_prefs_flutter` (`prefs_flutter`) | `prefsAsyncFactoryFlutter` |
| Browser (local storage) | `tekartik_prefs_browser` (`prefs_browser`) | `prefsAsyncFactoryBrowser` |
| Any, on sembast (io file, web) | `tekartik_prefs_sembast` (`prefs_sembast`) | `getPrefsAsyncFactorySembast(databaseFactory, path)` |
| Any, on sdb (idb_shim) | `tekartik_prefs_sdb` (`prefs_sdb`) | `getPrefsAsyncFactorySdb(sdbFactory)` |

Each backend re-exports the API: one import gives both.

## Which API

| API | Import | Use it for |
|---|---|---|
| `PrefsAsync` (`PrefsAsyncFactory`) | `prefs_async.dart` | the default: every read and write is a `Future` |
| `PrefsAsyncWithCache` | `prefs_async.dart` | synchronous reads (all values cached at open), async writes |
| `PrefsLight` (`KvStore`) | `prefs_light.dart`, `kv_store.dart` | a few values, no versioning; `KvStore` for strings only |
| `Prefs` (`PrefsFactory`) | `prefs.dart` | the older sync API (writes saved in the background) |

`factory.sandbox(path: 'feature')` gives a factory whose stores live under
`path` (one per user, feature or test).

## Common pitfalls

* Keys cannot be empty nor start with `_` (reserved for the version and the
  signature): `ArgumentError`.
* Reads are lenient by default (`getInt` of `'12'` is `12`). Call
  `factory.init(options: PrefsAsyncFactoryOptions(strictType: true))` before
  opening anything for `shared_preferences` typing.
* `getList` reads what `setList` wrote (JSON in a string); a `setStringList`
  value is read with `getStringList`.
* Reopening an open store with another `version` throws a `StateError`.
* `deletePreferences(name)` erases and closes the store: do not keep using an
  instance opened before.

The skills [tekartik-prefs-async](skills/tekartik-prefs-async/SKILL.md),
[tekartik-prefs-light](skills/tekartik-prefs-light/SKILL.md) and
[tekartik-prefs-sync](skills/tekartik-prefs-sync/SKILL.md) have more examples.

## KvStore

`KvStore` is the minimal string key/value interface, split in `KvStoreRead`
(`getString`) and `KvStoreWrite` (`setString`, `remove`). Depend on it when all
you need is to read and write strings, instead of a full prefs implementation.
`PrefsLight` implements it, so any light prefs can be passed where a `KvStore`
is expected. A store can also be built from 3 functions:

```dart
import 'package:tekartik_prefs/kv_store.dart';

Future<void> main() async {
  var map = <String, String>{};
  var store = KvStore(
    getString: (key) async => map[key],
    setString: (key, value) async => map[key] = value,
    remove: (key) async => map.remove(key),
  );
  await store.setString('key', 'value');
  await store.setStringOrNull('key', null); // remove
}
```
