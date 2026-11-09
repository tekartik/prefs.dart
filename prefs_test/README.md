# tekartik_prefs_test

The shared test suites of [tekartik_prefs](../prefs/README.md): every backend
(memory, browser, flutter, sdb, sembast) runs them, so they all behave the
same. Run them on a new backend, a wrapper or a sandbox.

## Getting started

Git package, not on pub.dev, a dev dependency:

```yaml
dev_dependencies:
  tekartik_prefs_test:
    git:
      url: https://github.com/tekartik/prefs.dart
      path: prefs_test
```

`test/my_prefs_test.dart`:

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
  // Replace the memory factories with the ones under test.
  prefs.runPrefsTests(newPrefsFactoryMemory());
  runPrefsAsyncTests(newPrefsAsyncFactoryMemory());
  runPrefsAsyncWithCacheTests(newPrefsAsyncWithCacheFactoryMemory());
  runPrefsLightTests(PrefsMemory());
  group('kv_store', () {
    runKvStoreTests(newKvStoreMemory());
  });
}
```

## Suites

| Import | Runner |
|---|---|
| `prefs_async_test_runner.dart` | `runPrefsAsyncTests(PrefsAsyncFactory)` (twice: strict and normal types) |
| `prefs_async_with_cache_test_runner.dart` | `runPrefsAsyncWithCacheTests(PrefsAsyncWithCacheFactory)` |
| `prefs_light_test_runner.dart` | `runPrefsLightTests(PrefsLight)` |
| `kv_store_test_runner.dart` | `runKvStoreTests(KvStore)`, `newKvStoreMemory()` |
| `prefs_test_runner.dart` | `runPrefsTests(PrefsFactory)` (older sync API) |

All of them run on the VM, in the browser and in `flutter test`.

## Common pitfalls

* The factory suites create and delete prefs with fixed names (`test.prefs`,
  `version.prefs`...): give them a memory or sandboxed factory, never the
  app's real store.
* `runPrefsAsyncTests` calls `factory.init(options: ...)`: give it a factory
  of its own.
* Call the runners while `main()` declares the tests, never inside a `test`.

## Testing

```bash
dart test # the suites on the memory implementations
```
