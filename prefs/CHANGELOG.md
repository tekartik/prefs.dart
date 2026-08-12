## 1.1.0

- Add `KvStore`, a minimal string key/value store (`KvStoreRead` for
  `getString`, `KvStoreWrite` for `setString`/`remove`), that `PrefsLight`
  implements. A `KvStore` can be built from the 3 methods:
  `KvStore(getString: ..., setString: ..., remove: ...)`.
- `setStringOrNull` moves from `PrefsLightExt` to `KvStoreExt` (no change for
  `PrefsLight` users).

## 1.0.0

- Initial version, created by Stagehand
