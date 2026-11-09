# prefs.dart

Storage agnostic preferences (named, versioned key/value stores) for Dart and
Flutter, with one API and a backend per platform. A pub workspace.

| Package | Folder | What |
|---|---|---|
| `tekartik_prefs` | [`prefs/`](prefs) | The API (`PrefsAsync`, `PrefsAsyncWithCache`, `PrefsLight`, `KvStore`, `Prefs`) and the memory implementation. Start with its [README](prefs/README.md). |
| `tekartik_prefs_flutter` | [`prefs_flutter/`](prefs_flutter) | Flutter, on `shared_preferences`. |
| `tekartik_prefs_browser` | [`prefs_browser/`](prefs_browser) | Browser local storage. |
| `tekartik_prefs_sembast` | [`prefs_sembast/`](prefs_sembast) | On a sembast database (io file, web). |
| `tekartik_prefs_sdb` | [`prefs_sdb/`](prefs_sdb) | On sdb (idb_shim). |
| `tekartik_prefs_test` | [`prefs_test/`](prefs_test) | Shared test suites of a backend. |

Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_prefs_flutter:
    git:
      url: https://github.com/tekartik/prefs.dart
      path: prefs_flutter
```

## Testing

```bash
# from a package folder
dart test # flutter test for prefs_flutter
```
