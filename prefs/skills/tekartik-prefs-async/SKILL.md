---
name: tekartik-prefs-async
description: >-
  Use when storing named application preferences through the async tekartik_prefs
  API: PrefsAsync, PrefsAsyncFactory, PrefsAsyncWithCache,
  PrefsAsyncWithCacheFactory, openPreferences, deletePreferences,
  prefsAsyncFactoryMemory, newPrefsAsyncFactoryMemory,
  prefsAsyncWithCacheFactoryMemory, PrefsAsyncFactoryOptions(strictType:),
  onVersionChanged migrations, sandbox(path:), the setMap/setList/getMap/getList
  and setStringOrNull extensions, and the package:tekartik_prefs/prefs_async.dart
  import shared by the sembast, sdb, browser and flutter implementations.
---

# Async prefs (tekartik_prefs)

`tekartik_prefs` is the storage agnostic preferences interface: named,
versioned key/value stores holding `bool`, `int`, `double`, `String`,
`List<String>` and json encodable maps/lists. This package only ships the
interfaces plus the in-memory implementation; a real backend comes from
`tekartik_prefs_sembast`, `tekartik_prefs_sdb`, `tekartik_prefs_browser` or
`tekartik_prefs_flutter`, which all re-export this API.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_prefs:
      git:
        url: https://github.com/tekartik/prefs.dart
        path: prefs
  ```
* Import `package:tekartik_prefs/prefs_async.dart`. Implementation packages
  re-export it, so importing `package:tekartik_prefs_sembast/prefs_async.dart`
  (or the sdb/browser/flutter one) is enough in application code: you get
  `PrefsAsync` and the backend factory from a single import.
* Two flavours, pick one and stick to it for a given store:
  * `PrefsAsyncFactory` / `PrefsAsync`: every read and write is a `Future`.
  * `PrefsAsyncWithCacheFactory` / `PrefsAsyncWithCache`: reads are
    synchronous (the whole store is cached in memory when opened), writes stay
    `Future`s. Use it when the UI needs values without `await`.
* Open with `await factory.openPreferences(name, version: , onVersionChanged: )`.
  `name` is the store name (an empty name becomes `default.prefs`; a name with
  `/` acts as a path in the file/document backends). The same name returns the
  same instance until `close()`; reopening with a different `version` throws a
  `StateError`.
* `onVersionChanged(prefs, oldVersion, newVersion)` runs inside the open, before
  `openPreferences` completes: seed defaults or migrate keys there. A fresh
  store has `oldVersion == 0`. Read `prefs.version` afterwards. Without
  `version:`, the version stays `0` and no callback fires.
* `PrefsAsync` reads: `getBool`, `getInt`, `getDouble`, `getString`,
  `getStringList`, `containsKey`, `getKeys()`, `getAll()`. Writes: `setBool`,
  `setInt`, `setDouble`, `setString`, `setStringList`, `remove`, `clear`.
  Setters are non-nullable; use `remove(key)` or the `*OrNull` extensions to
  delete. `clear()` keeps the internal version/signature keys.
* `PrefsAsyncWithCache` exposes the `PrefsSyncRead` side synchronously:
  `getBool`, `getInt`, `getDouble`, `getString`, `containsKey`, `keys` (a
  `Set<String>`), and the same async writers. It has no `getStringList`.
* Extensions (no extra import, they come with `prefs_async.dart`):
  * `PrefsAsyncWriteExt` on any writer: `setIntOrNull`, `setBoolOrNull`,
    `setDoubleOrNull`, `setStringOrNull`, `setMap`, `setMapOrNull`, `setList`,
    `setListOrNull`. Maps and lists are stored json encoded in a string.
  * `PrefsAsyncReadExt` on `PrefsAsync`: `getMap` (a `Model`, i.e. a
    `Map<String, Object?>`) and `getList`, both `Future`s.
  * `PrefsSyncReadExt` on `PrefsAsyncWithCache`: the same `getMap`/`getList`,
    synchronous.
* Type conversion: by default reads are lenient (`getInt` on a stored `'12'` or
  `12.6` returns `12`, `getString` returns `toString()` of whatever is there).
  Call `factory.init(options: PrefsAsyncFactoryOptions(strictType: true))`
  before opening anything to match `shared_preferences` semantics instead: a
  wrong type reads back as `null` and the map/list extensions become
  unreliable. `factory.options.strictType` tells you the current mode.
* `factory.sandbox(path: 'some/dir')` (`PrefsAsyncFactorySandboxExtension`,
  also available on the sync `PrefsFactory`) returns a factory whose stores all
  live under `path`. Sandboxes never nest twice, and a name escaping the root
  (`'../other'`) throws an `ArgumentError`. Handy to isolate a feature, a user,
  or a test from the rest of the app.
* `await factory.deletePreferences(name)` erases the store (including version
  and signature) and closes it. `await prefs.close()` just releases it.
* Testing: `prefsAsyncFactoryMemory` /
  `prefsAsyncWithCacheFactoryMemory` are process-wide singletons that survive
  `close()`, so prefer `newPrefsAsyncFactoryMemory()` /
  `newPrefsAsyncWithCacheFactoryMemory()` per test to start empty. The shared
  conformance suites live in `tekartik_prefs_test`.
* Anti-patterns: holding a `PrefsAsync` after `close()`; calling
  `openPreferences` on every read (it locks and returns the cached instance,
  but the call is still async); storing large blobs — this is preferences
  storage, use sembast/sdb directly for real data.

## Examples

### Open, write and read a memory store

```dart
import 'package:tekartik_prefs/prefs_async.dart';

Future<void> main() async {
  var factory = newPrefsAsyncFactoryMemory();
  var prefs = await factory.openPreferences('settings');

  await prefs.setString('user', 'alex');
  await prefs.setInt('count', 3);
  await prefs.setBoolOrNull('dark', null); // removes the key
  await prefs.setMap('window', {'width': 800, 'height': 600});
  await prefs.setList('recent', ['a', 'b']);

  print(await prefs.getString('user')); // alex
  print(await prefs.getInt('count')); // 3
  print(await prefs.containsKey('dark')); // false
  print((await prefs.getMap('window'))?['width']); // 800
  print(await prefs.getList('recent')); // [a, b]
  print(await prefs.getKeys());
  print(await prefs.getAll());

  await prefs.close();
}
```

### Versioned store with a migration

```dart
import 'package:tekartik_prefs/prefs_async.dart';

Future<PrefsAsync> openSettings(PrefsAsyncFactory factory) async {
  return await factory.openPreferences(
    'settings',
    version: 2,
    onVersionChanged: (prefs, oldVersion, newVersion) async {
      if (oldVersion == 0) {
        // First creation: defaults.
        await prefs.setBool('dark', false);
      }
      if (oldVersion < 2) {
        var legacy = await prefs.getString('userName');
        if (legacy != null) {
          await prefs.setString('user', legacy);
          await prefs.remove('userName');
        }
      }
    },
  );
}

Future<void> main() async {
  var prefs = await openSettings(newPrefsAsyncFactoryMemory());
  print(prefs.version); // 2
  await prefs.close();
}
```

### Synchronous reads with PrefsAsyncWithCache

```dart
import 'package:tekartik_prefs/prefs_async.dart';

class AppSettings {
  final PrefsAsyncWithCache prefs;

  AppSettings(this.prefs);

  static Future<AppSettings> open(PrefsAsyncWithCacheFactory factory) async =>
      AppSettings(await factory.openPreferences('app', version: 1));

  // Synchronous getters, usable from a widget build.
  bool get dark => prefs.getBool('dark') ?? false;
  String get user => prefs.getString('user') ?? 'anonymous';
  Map<String, Object?> get window => prefs.getMap('window') ?? {};

  Future<void> setDark(bool value) => prefs.setBool('dark', value);
}

Future<void> main() async {
  var settings = await AppSettings.open(newPrefsAsyncWithCacheFactoryMemory());
  await settings.setDark(true);
  print(settings.dark); // true
  print(settings.prefs.keys);
}
```

### Sandbox and strict types

```dart
import 'package:tekartik_prefs/prefs_async.dart';

Future<void> main() async {
  var factory = newPrefsAsyncFactoryMemory();
  factory.init(options: PrefsAsyncFactoryOptions(strictType: true));

  // Everything opened here lives under 'user_1/' in the delegate factory.
  var userFactory = factory.sandbox(path: 'user_1');
  var prefs = await userFactory.openPreferences('settings');

  await prefs.setString('count', '12');
  print(await prefs.getInt('count')); // null: strict types, no conversion
  print(await prefs.getString('count')); // 12

  await prefs.close();
  await userFactory.deletePreferences('settings');
}
```

### Depending on the interface, not the implementation

```dart
import 'package:tekartik_prefs/prefs_async.dart';

/// Works with the memory, sembast, sdb, browser and flutter factories.
class TokenStore {
  final PrefsAsyncFactory factory;

  TokenStore(this.factory);

  Future<String?> read() async {
    var prefs = await factory.openPreferences('auth', version: 1);
    try {
      return await prefs.getString('token');
    } finally {
      await prefs.close();
    }
  }

  Future<void> write(String? token) async {
    var prefs = await factory.openPreferences('auth', version: 1);
    try {
      await prefs.setStringOrNull('token', token);
    } finally {
      await prefs.close();
    }
  }
}

Future<void> main() async {
  var store = TokenStore(prefsAsyncFactoryMemory);
  await store.write('abc');
  print(await store.read()); // abc
}
```
