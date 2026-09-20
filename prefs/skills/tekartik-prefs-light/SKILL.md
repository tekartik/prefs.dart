---
name: tekartik-prefs-light
description: >-
  Use when a component only needs a minimal async key/value store instead of a
  full prefs factory: KvStore, KvStoreRead, KvStoreWrite, the KvStore(getString:,
  setString:, remove:) function based constructor, KvStoreExt.setStringOrNull,
  PrefsLight, PrefsLightExt (setIntOrNull, getMap, setMap, getList, setList),
  PrefsMemory, PrefsLightAsync / PrefsLightAsync.lazy wrapping a PrefsAsync, and
  the package:tekartik_prefs/kv_store.dart and
  package:tekartik_prefs/prefs_light.dart imports.
---

# KvStore and PrefsLight (tekartik_prefs)

`KvStore` is the smallest storage contract in `tekartik_prefs`: async
`getString` / `setString` / `remove`, nothing else. `PrefsLight` adds typed
`bool`/`int`/`double` accessors on top of it. Both are single, already-open
stores — no factory, no `openPreferences`, no version — so they are the right
type to accept in a library or a widget that just needs somewhere to persist a
few values.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_prefs:
      git:
        url: https://github.com/tekartik/prefs.dart
        path: prefs
  ```
* Imports: `package:tekartik_prefs/kv_store.dart` for `KvStore` alone,
  `package:tekartik_prefs/prefs_light.dart` for `PrefsLight` (it re-exports
  `kv_store.dart`, so one import is enough).
* `KvStore` splits into `KvStoreRead` (`getString`) and `KvStoreWrite`
  (`setString`, `remove`). Accept the narrowest one your code needs: a
  read-only cache takes a `KvStoreRead`.
* Build a store without writing a class with the
  `KvStore(getString: , setString: , remove: )` factory constructor; the three
  arguments are `KvStoreGetStringFunction`, `KvStoreSetStringFunction` and
  `KvStoreRemoveFunction`, all returning `Future`s. Ideal to wrap an existing
  map, a secure storage plugin or a remote config.
* `KvStoreExt.setStringOrNull(key, value)` writes, or removes when `value` is
  `null`. There is no `getStringOrNull`: `getString` already returns `null`
  when the key is missing.
* `PrefsLight implements KvStore`, so every prefs implementation can be passed
  where a `KvStore` is expected. On top of `getString`/`setString`/`remove` it
  has `getBool`, `getInt`, `getDouble`, `setBool`, `setInt`, `setDouble`.
  There is no `clear`, no key listing and no `close` — use `PrefsAsync` when
  you need those.
* `PrefsLightExt` (on `PrefsLight`) adds `setIntOrNull`, `setBoolOrNull`,
  `setDoubleOrNull`, `getMap` / `setMap` / `setMapOrNull` and `getList` /
  `setList` / `setListOrNull`; maps and lists are json encoded into the string
  value, so they must be json encodable. `getMap` returns a `Model` (a
  `Map<String, Object?>`) and returns `null` rather than throwing when the
  stored string is not json.
* Implementations: `PrefsMemory()` (in memory, from
  `package:tekartik_prefs/prefs_light.dart`), `getPrefsLightSembast(
  databaseFactory: , path: )`, `getPrefsLightSdb(sdbFactory, name: )` and
  `prefsFlutter` (from `package:tekartik_prefs_flutter/prefs_light.dart`,
  backed by `shared_preferences`).
* `PrefsLightAsync(delegate: prefsAsync)` adapts any `PrefsAsync` to
  `PrefsLight`; `PrefsLightAsync.lazy(initDelegate: () async => ...)` defers
  the open until the first access, which is how the sembast and sdb helpers are
  built. Both swallow read errors and return `null` on a type mismatch instead
  of throwing.
* Anti-patterns: using `PrefsLight` when you need `clear()`, key enumeration,
  versioning or several named stores (use the `PrefsAsyncFactory` API);
  assuming `PrefsMemory` persists across runs; storing non json encodable
  objects in `setMap`/`setList`.

## Examples

### Depend on KvStore, not on a prefs implementation

```dart
import 'package:tekartik_prefs/kv_store.dart';

class SessionCache {
  final KvStore store;

  SessionCache(this.store);

  Future<String?> get token => store.getString('token');

  Future<void> setToken(String? token) =>
      store.setStringOrNull('token', token);
}

Future<void> main() async {
  var map = <String, String>{};
  var store = KvStore(
    getString: (key) async => map[key],
    setString: (key, value) async => map[key] = value,
    remove: (key) async => map.remove(key),
  );

  var cache = SessionCache(store);
  await cache.setToken('abc');
  print(await cache.token); // abc
  await cache.setToken(null);
  print(await cache.token); // null
}
```

### In memory PrefsLight with typed and json values

```dart
import 'package:tekartik_prefs/prefs_light.dart';

Future<void> main() async {
  PrefsLight prefs = PrefsMemory();

  await prefs.setString('user', 'alex');
  await prefs.setInt('count', 3);
  await prefs.setBool('dark', true);
  await prefs.setMap('window', {'width': 800, 'height': 600});
  await prefs.setList('recent', ['a', 'b']);

  print(await prefs.getString('user')); // alex
  print(await prefs.getInt('count')); // 3
  print((await prefs.getMap('window'))?['height']); // 600
  print(await prefs.getList('recent')); // [a, b]

  await prefs.setIntOrNull('count', null); // removes the key
  print(await prefs.getInt('count')); // null

  // A PrefsLight is a KvStore.
  KvStore store = prefs;
  print(await store.getString('user')); // alex
}
```

### Adapt a PrefsAsync to PrefsLight

```dart
import 'package:tekartik_prefs/prefs_async.dart';
import 'package:tekartik_prefs/prefs_light.dart';

/// Opens the store on first use only.
PrefsLight lightPrefs(PrefsAsyncFactory factory) => PrefsLightAsync.lazy(
  initDelegate: () async => factory.openPreferences('prefs.db'),
);

Future<void> main() async {
  var factory = newPrefsAsyncFactoryMemory();

  var lazy = lightPrefs(factory);
  await lazy.setString('user', 'alex');
  print(await lazy.getString('user')); // alex

  // Or wrap an already opened one.
  var prefsAsync = await factory.openPreferences('other');
  var prefs = PrefsLightAsync(delegate: prefsAsync);
  await prefs.setDouble('ratio', 1.5);
  print(await prefs.getDouble('ratio')); // 1.5
  await prefsAsync.close();
}
```
