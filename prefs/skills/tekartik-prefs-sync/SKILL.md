---
name: tekartik-prefs-sync
description: >-
  Use when reading or writing preferences through the legacy synchronous
  tekartik_prefs API: Prefs, PrefsFactory, PrefsSyncRead, PrefsSyncReadExt,
  openPreferences/deletePreferences, prefsFactoryMemory, newPrefsFactoryMemory,
  PrefsOnVersionChangedFunction, hasStorage, the void setString/setInt/setBool/
  setDouble/setMap/setList setters with save(), sandbox(path:), and the
  package:tekartik_prefs/prefs.dart import used by prefsFactoryFlutter,
  prefsFactoryBrowser, getPrefsFactorySembast and getPrefsFactorySdb.
---

# Synchronous prefs (tekartik_prefs)

`package:tekartik_prefs/prefs.dart` is the original, synchronous prefs API:
the whole store is loaded when it is opened, reads are plain getters and
writes are queued and flushed in the background. It is still implemented by
every backend, but new code should prefer the async API
(`prefs_async.dart`, see the `tekartik-prefs-async` skill), which is the one
the implementations keep extending.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_prefs:
      git:
        url: https://github.com/tekartik/prefs.dart
        path: prefs
  ```
* Import `package:tekartik_prefs/prefs.dart`; implementation packages re-export
  it next to their factory (`prefsFactoryMemory` here,
  `prefsFactoryFlutter`, `prefsFactoryBrowser`,
  `getPrefsFactorySembast(...)`, `getPrefsFactorySdb(...)` elsewhere).
* `PrefsFactory` has `openPreferences(name, {version, onVersionChanged})`,
  `deletePreferences(name)` and `hasStorage` (`false` for the memory factory,
  handy to skip persistence-dependent code paths).
* `Prefs` reads are synchronous: `getString`, `getInt`, `getDouble`,
  `getBool`, `containsKey`, `keys` (a `Set<String>`), plus `getMap` and
  `getList` from `PrefsSyncReadExt` (json decoded from the stored string,
  `null` when absent or not json). Depend on `PrefsSyncRead` in code that only
  reads.
* `Prefs` writes return `void` and are persisted in the background:
  `setString`, `setInt`, `setDouble`, `setBool`, `setMap`, `setList`,
  `remove`, `clear`. All the setters take a nullable value and removing is
  just passing `null`. Await `prefs.save()` when you need the write on disk
  now (before exiting, before a test assertion on the underlying storage), and
  `await prefs.close()` when done.
* Key names are validated: empty or starting with `_` throws an
  `ArgumentError` (`_`-prefixed names are reserved for the internal version and
  signature keys). Values must be json-ish: `String`, `num`, `bool`, `null`, or
  `List`/`Map` of those; anything else throws an `ArgumentError`.
* `version:` + `onVersionChanged(prefs, oldVersion, newVersion)`
  (`PrefsOnVersionChangedFunction`) run during the open, with `oldVersion == 0`
  on a fresh store; the callback receives the same `Prefs` and can write
  defaults synchronously. `prefs.name` and `prefs.version` describe the store.
* `factory.sandbox(path: 'dir')` (`PrefsFactorySandboxExtension`) returns a
  factory whose stores live under `path`; sandboxes do not nest twice and a
  name escaping the root throws an `ArgumentError`.
* Use `newPrefsFactoryMemory()` in tests (a fresh, empty factory) rather than
  the `prefsFactoryMemory` singleton, which keeps its content for the whole
  process even after `close()`.
* Anti-patterns: expecting a `void` setter to be durable without `save()` or
  `close()`; mixing the sync `Prefs` and the async `PrefsAsync` on the same
  store name — the two families do not share the same storage layout.

## Examples

### Open, write, read

```dart
import 'package:tekartik_prefs/prefs.dart';

Future<void> main() async {
  var factory = newPrefsFactoryMemory();
  var prefs = await factory.openPreferences('settings');

  prefs.setString('user', 'alex');
  prefs.setInt('count', 3);
  prefs.setBool('dark', null); // same as remove('dark')
  prefs.setMap('window', {'width': 800, 'height': 600});
  prefs.setList('recent', ['a', 'b']);

  // Reads are synchronous.
  print(prefs.getString('user')); // alex
  print(prefs.getInt('count')); // 3
  print(prefs.containsKey('dark')); // false
  print(prefs.getMap('window')?['width']); // 800
  print(prefs.getList('recent')); // [a, b]
  print(prefs.keys);

  await prefs.save(); // flush pending writes
  await prefs.close();
}
```

### Versioned store and read-only dependency

```dart
import 'package:tekartik_prefs/prefs.dart';

/// Only needs to read.
String describe(PrefsSyncRead prefs) =>
    '${prefs.getString('user')} (${prefs.getBool('dark') ?? false})';

Future<Prefs> openSettings(PrefsFactory factory) => factory.openPreferences(
  'settings',
  version: 1,
  onVersionChanged: (prefs, oldVersion, newVersion) {
    if (oldVersion == 0) {
      prefs.setString('user', 'anonymous');
      prefs.setBool('dark', false);
    }
  },
);

Future<void> main() async {
  var prefs = await openSettings(newPrefsFactoryMemory());
  print(prefs.version); // 1
  print(describe(prefs)); // anonymous (false)
  await prefs.close();
}
```

### Sandbox a factory, and skip work when there is no storage

```dart
import 'package:tekartik_prefs/prefs.dart';

Future<void> main() async {
  var factory = newPrefsFactoryMemory();
  print(factory.hasStorage); // false for memory

  // Everything opened below lives under 'user_1' in the delegate factory.
  var userFactory = factory.sandbox(path: 'user_1');
  var prefs = await userFactory.openPreferences('settings');
  prefs.setString('user', 'alex');
  await prefs.close();

  // Not visible under the plain name outside the sandbox.
  var other = await factory.openPreferences('settings');
  print(other.getString('user')); // null
  await other.close();

  await userFactory.deletePreferences('settings');
}
```
