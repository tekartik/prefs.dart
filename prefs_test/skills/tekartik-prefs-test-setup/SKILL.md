---
name: tekartik-prefs-test-setup
description: >-
  Use when validating a tekartik_prefs implementation against the shared
  conformance suites with tekartik_prefs_test: runPrefsTests(PrefsFactory),
  runPrefsAsyncTests(PrefsAsyncFactory),
  runPrefsAsyncWithCacheTests(PrefsAsyncWithCacheFactory),
  runPrefsLightTests(PrefsLight), runKvStoreTests(KvStore), newKvStoreMemory,
  testKey, and the prefs_test_runner.dart, prefs_async_test_runner.dart,
  prefs_async_with_cache_test_runner.dart, prefs_light_test_runner.dart and
  kv_store_test_runner.dart imports, including the dart:io / browser caveat.
---

# Shared prefs test suites (tekartik_prefs_test)

`tekartik_prefs_test` holds the conformance suites every `tekartik_prefs`
backend is validated with. A new implementation (or a wrapper, a sandbox, a
mock) is considered correct when it passes `run*Tests(...)` with its own
factory, exactly like `tekartik_prefs_sembast`, `tekartik_prefs_sdb`,
`tekartik_prefs_browser` and `tekartik_prefs_flutter` do.

## Guidelines

* Dev dependency (git, not on pub.dev):
  ```yaml
  dev_dependencies:
    tekartik_prefs_test:
      git:
        url: https://github.com/tekartik/prefs.dart
        path: prefs_test
  ```
  It depends on `package:test` (a regular dependency, not a dev one), so only
  import it from `test/` files or a test app; never from `lib/`.
* One runner per flavour, each library re-exporting the matching
  `tekartik_prefs` library so a test file usually needs no extra import:
  * `package:tekartik_prefs_test/prefs_test_runner.dart` →
    `runPrefsTests(PrefsFactory factory)` (legacy synchronous API).
  * `package:tekartik_prefs_test/prefs_async_test_runner.dart` →
    `runPrefsAsyncTests(PrefsAsyncFactory factory)`.
  * `package:tekartik_prefs_test/prefs_async_with_cache_test_runner.dart` →
    `runPrefsAsyncWithCacheTests(PrefsAsyncWithCacheFactory factory)`.
  * `package:tekartik_prefs_test/prefs_light_test_runner.dart` →
    `runPrefsLightTests(PrefsLight prefs)`.
  * `package:tekartik_prefs_test/kv_store_test_runner.dart` →
    `runKvStoreTests(KvStore store)`, plus `newKvStoreMemory()`, the reference
    map-based implementation.
* Call the runners at the top level of `main()`, outside any `group`, or inside
  a `group(...)` of your own; they declare their own `group`/`test`/`setUpAll`
  and must run while the test file is being loaded, not inside a `test`.
* The factory-based runners open, migrate and **delete** prefs under fixed
  names (`basic`, `delete`, `version`, `keys`, `types`, `two_prefs`, ...).
  Always pass a factory pointing at a scratch location — a memory factory, a
  sandboxed one (`factory.sandbox(path: 'test')`, or the backend's own path /
  `SdbFactory` / `DatabaseFactory` sandbox) — never the app's real store.
* `runPrefsAsyncTests` runs the whole suite twice, in a `strict` group and a
  `normal` group, calling
  `factory.init(options: PrefsAsyncFactoryOptions(strictType: true))` and
  `factory.init(options: PrefsAsyncFactoryOptions())` in `setUpAll`. Give it a
  factory instance of its own: it mutates the global options of that factory.
* `runPrefsLightTests` and `runKvStoreTests` take an already opened store, not
  a factory. They namespace their keys (`prefs_light_test.*`,
  `kv_store_test.*`, both built with the exported `testKey(key)` helper) and
  the `KvStore` suite removes its keys in `tearDown`, so they can run against a
  shared or persistent store. `testKey` is declared in both libraries: prefix
  one import if you need to call it.
* `package:tekartik_prefs_test/prefs_async_test_runner.dart` imports `dart:io`
  today, so it compiles on the VM and on Flutter but **not** for a browser
  test: in a `@TestOn('browser')` file use `runPrefsTests` and
  `runPrefsAsyncWithCacheTests` only.
* A runner library re-exports its `tekartik_prefs` library, but importing it
  with a prefix (`as prefs`, as the repo tests do to keep `runPrefsTests`
  distinguishable) hides those re-exports: add an explicit
  `import 'package:tekartik_prefs/prefs.dart';` (or `prefs_light.dart`, which
  is the only source of `PrefsMemory` and `PrefsLight` since no runner
  re-exports it) when you need the types unprefixed.
* Each runner library also declares its own `main()` running the suite against
  the in-memory implementation, so it can be executed directly
  (`dart test test/...`) and is the reference for the expected behaviour.
* In Flutter, call `TestWidgetsFlutterBinding.ensureInitialized()` before the
  runners (a `flutter_test` file), or run them from a real app with
  `WidgetsFlutterBinding.ensureInitialized()` when the backend needs plugins.
* Anti-patterns: running a suite against a production store; sharing one
  factory instance between `runPrefsAsyncTests` and other tests that rely on
  the options; wrapping a runner in `test(...)`; adding
  `tekartik_prefs_test` to `dependencies` instead of `dev_dependencies`.

## Examples

### Validate a full backend (all flavours)

```dart
import 'package:tekartik_prefs/prefs.dart';
import 'package:tekartik_prefs/prefs_light.dart';
import 'package:tekartik_prefs_test/kv_store_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_async_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_async_with_cache_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_light_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_test_runner.dart' as prefs;
import 'package:test/test.dart';

void main() {
  // Replace the memory factories with the ones of the implementation under
  // test, e.g. getPrefsAsyncFactorySembast(newDatabaseFactoryMemory(), '.').
  prefs.runPrefsTests(newPrefsFactoryMemory());
  runPrefsAsyncTests(newPrefsAsyncFactoryMemory());
  runPrefsAsyncWithCacheTests(newPrefsAsyncWithCacheFactoryMemory());
  runPrefsLightTests(PrefsMemory());

  group('kv_store', () {
    runKvStoreTests(newKvStoreMemory());
  });
}
```

### Same suite on several platforms, from one shared file

```dart
// test/prefs_test_common.dart
import 'package:tekartik_prefs/prefs.dart';
import 'package:tekartik_prefs_test/prefs_async_with_cache_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_test_runner.dart' as prefs;

/// Called by the vm, browser and flutter test entry points, each passing its
/// own factories.
void defineTests({
  required PrefsFactory factory,
  required PrefsAsyncWithCacheFactory asyncWithCacheFactory,
}) {
  prefs.runPrefsTests(factory);
  runPrefsAsyncWithCacheTests(asyncWithCacheFactory);
}
```

### Browser entry point (no dart:io runner)

```dart
@TestOn('browser')
library;

import 'package:tekartik_prefs/prefs.dart';
import 'package:tekartik_prefs_test/prefs_async_with_cache_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_test_runner.dart' as prefs;
import 'package:test/test.dart';

void main() {
  // prefsFactoryBrowser / prefsAsyncWithCacheFactoryBrowser in a real backend
  // test; runPrefsAsyncTests is not usable here (it imports dart:io).
  prefs.runPrefsTests(newPrefsFactoryMemory());
  runPrefsAsyncWithCacheTests(newPrefsAsyncWithCacheFactoryMemory());
}
```

### Validate your own KvStore implementation

```dart
import 'package:tekartik_prefs_test/kv_store_test_runner.dart';
import 'package:test/test.dart';

/// A store of your own, here a trivial map based one.
class MyKvStore implements KvStore {
  final _map = <String, String>{};

  @override
  Future<String?> getString(String key) async => _map[key];

  @override
  Future<void> setString(String key, String value) async => _map[key] = value;

  @override
  Future<void> remove(String key) async => _map.remove(key);
}

void main() {
  group('my_store', () {
    runKvStoreTests(MyKvStore());
  });

  test('reference implementation', () {
    expect(newKvStoreMemory(), isA<KvStore>());
  });
}
```
