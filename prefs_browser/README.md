# tekartik_prefs_browser

[tekartik_prefs](../prefs/README.md) stores in the browser local storage
(`window.localStorage`), for Dart web apps (dart2js or dart2wasm). One local
storage entry per key, named `'<prefs name>/<key>'`.

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_prefs_browser:
    git:
      url: https://github.com/tekartik/prefs.dart
      path: prefs_browser
```

```dart
import 'package:tekartik_prefs_browser/prefs_async.dart';

Future<void> main() async {
  // Local storage on the web, memory elsewhere (VM tests).
  var factory = prefsAsyncFactoryBrowserOrNull ?? prefsAsyncFactoryMemory;
  var prefs = await factory.openPreferences('my_app', version: 1);
  await prefs.setBool('dark', true); // localStorage['my_app/dark'] = 'true'
  print(await prefs.getBool('dark')); // true
  await prefs.close();
}
```

A few values without opening anything, `PrefsLight`:

```dart
import 'package:tekartik_prefs_browser/prefs_light.dart';

Future<void> main() async {
  var prefs = getPrefsLightBrowserOrNull(name: 'my_app') ?? PrefsMemory();
  await prefs.setInt('count', 1);
  print(await prefs.getInt('count')); // 1
}
```

## Platforms

Web only. The imports compile everywhere: off the web the `...OrNull`
getters return null and the other getters throw `UnimplementedError`.

| Import | Factory |
|---|---|
| `prefs_async.dart` | `prefsAsyncFactoryBrowser`, `prefsAsyncWithCacheFactoryBrowser` (and `...OrNull`) |
| `prefs_light.dart` | `getPrefsLightBrowser({name})`, `getPrefsLightBrowserOrNull` |
| `prefs.dart` | `prefsFactoryBrowser` (older sync API) |

## Common pitfalls

* A prefs owns every entry starting with `'<name>/'`: prefs `a` also lists,
  clears and deletes the entries of a prefs named `a/b` (a sandbox name), and
  a key `b/x` of `a` is the key `x` of `a/b`. Do not nest prefs names, and
  avoid `/` in keys.
* Do not open the same name with the sync `prefsFactoryBrowser` and an async
  factory: the sync one writes raw strings, the async ones JSON (a non JSON
  value makes the async reads throw `FormatException`).
* Local storage is small (about 5 MB per origin), synchronous and wiped with
  the site data; a full storage makes the sync background save fail. Use
  `tekartik_prefs_sdb` (IndexedDB) for more.
* A prefs instance kept after `deletePreferences(name)` still writes to local
  storage, but the next open wipes those values (no signature).

## Testing

```bash
dart test -p chrome   # dart2js and dart2wasm
dart test -p vm       # the stubs
```

`test/prefs_browser_test.dart` runs every `tekartik_prefs_test` suite on the
browser factories.
