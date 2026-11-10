## 2.0.0

Breaking: `KvStore` is 2 methods, `getString` and `setString`.

- `KvStoreWrite.setString(String key, String? value)`: a null value removes
  the key. `remove(key)` becomes an extension (`KvStoreExt`, now on
  `KvStoreWrite`: same as `setString(key, null)`) and
  `KvStoreExt.setStringOrNull` is deprecated (use `setString`). A class
  implementing `KvStore` handles null in `setString` and no longer overrides
  `remove`.
- `KvStore(getString: ..., setString: ...)`: no more `remove:` argument.
  `KvStoreSetStringFunction` takes a `String?` value, `KvStoreRemoveFunction`
  is removed.
- `PrefsLight` no longer implements `KvStore` (its `setString` keeps a non
  null value): pass `prefs.kvStore` where a `KvStore` is expected. The same
  getter exists on `PrefsAsync` and `Prefs`.
- `setStringOrNull` is back in `PrefsLightExt`.
- `prefs.dart` and `prefs_async.dart` export `kv_store.dart`.

## 1.1.1

- `PrefsLightAsync.lazy` no longer throws when opening the delegate fails
  (storage not available): reads return null and writes are ignored, as for
  any other error.

## 1.1.0

- Add `KvStore`, a minimal string key/value store (`KvStoreRead` for
  `getString`, `KvStoreWrite` for `setString`/`remove`), that `PrefsLight`
  implements. A `KvStore` can be built from the 3 methods:
  `KvStore(getString: ..., setString: ..., remove: ...)`.
- `setStringOrNull` moves from `PrefsLightExt` to `KvStoreExt` (no change for
  `PrefsLight` users).

## 1.0.0

- Initial version, created by Stagehand
