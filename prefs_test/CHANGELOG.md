## 0.4.0

- For `tekartik_prefs` 2.0.0 (`KvStore` in 2 methods): `runKvStoreTests()`
  checks that `setString(key, null)` removes the key, `newKvStoreMemory()` is
  built from the 2 methods. A `PrefsLight` is tested as
  `runKvStoreTests(prefs.kvStore)`.

## 0.3.0

- Add `runKvStoreTests()` (`kv_store_test_runner.dart`) to validate a `KvStore`
  implementation, and `newKvStoreMemory()` as the in memory reference.

## 1.0.0

- Initial version, created by Stagehand
