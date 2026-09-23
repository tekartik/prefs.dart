---
name: tekartik-prefs-browser-setup
description: >-
  Use when persisting tekartik_prefs preferences in a browser (local storage)
  with tekartik_prefs_browser: prefsFactoryBrowser, prefsFactoryBrowserOrNull,
  prefsAsyncFactoryBrowser, prefsAsyncFactoryBrowserOrNull,
  prefsAsyncWithCacheFactoryBrowser, prefsAsyncWithCacheFactoryBrowserOrNull,
  getPrefsLightBrowser, getPrefsLightBrowserOrNull, the
  package:tekartik_prefs_browser/prefs.dart, prefs_async.dart and
  prefs_light.dart imports,
  falling back to the memory factory off the web, the window.localStorage key
  layout, and running the tekartik_prefs_test suites under @TestOn('browser').
---

# tekartik_prefs_browser: the local storage implementation (tekartik_prefs_browser)

`tekartik_prefs_browser` implements the `tekartik_prefs` factories on top of
the browser `window.localStorage`. The libraries are safe to import from
shared code: off the web (Dart VM, Flutter native) the conditional import
resolves to a stub where the `*OrNull` getters return `null` and the non-null
getters throw `UnimplementedError`.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_prefs_browser:
      git:
        url: https://github.com/tekartik/prefs.dart
        path: prefs_browser
  ```
  It brings `tekartik_prefs` (same repo, `path: prefs`), which holds the API
  itself; declare `tekartik_prefs` explicitly too if shared code imports it.
* Imports, each re-exporting its `tekartik_prefs` counterpart so a single
  import is enough:
  * `package:tekartik_prefs_browser/prefs.dart`: the synchronous API plus
    `prefsFactoryBrowser` and `prefsFactoryBrowserOrNull` (`PrefsFactory`).
  * `package:tekartik_prefs_browser/prefs_async.dart`: the async API plus
    `prefsAsyncFactoryBrowser` / `prefsAsyncFactoryBrowserOrNull`
    (`PrefsAsyncFactory`) and `prefsAsyncWithCacheFactoryBrowser` /
    `prefsAsyncWithCacheFactoryBrowserOrNull`
    (`PrefsAsyncWithCacheFactory`).
  * `package:tekartik_prefs_browser/prefs_light.dart`:
    `getPrefsLightBrowser({String? name})` and `getPrefsLightBrowserOrNull`,
    a ready to use `PrefsLight` (so a `KvStore`: no factory, no open/close,
    reads never throw) on top of the async implementation, `name` defaulting
    to `prefs`.
* Always prefer the `*OrNull` getters in code that also runs off the web:
  `prefsAsyncFactoryBrowserOrNull ?? prefsAsyncFactoryMemory` compiles and
  runs everywhere. The non-`OrNull` getters are for code already guarded by a
  `@TestOn('browser')`, a web-only entry point or a conditional import.
* All factories are process-wide singletons; there is no `newPrefsFactory...`
  variant. `hasStorage` is `true` for the sync browser factory.
* Storage layout: one local storage entry per key, named
  `'<prefsName>/<key>'` in the current origin. The sync implementation writes
  `value.toString()` for `num`/`bool`/`String` and json for maps and lists;
  the async implementations (and the light one) json encode every value.
  Consequence: never open the same prefs name through both the sync and the
  async family, and pick a prefs name unlikely to collide with the other
  local storage users of the origin.
* Local storage is per origin and synchronous under the hood: keep the stored
  data small, and expect it to be wiped by private browsing or by the user
  clearing site data. `deletePreferences(name)` removes every `'<name>/'`
  entry.
* When local storage may be unavailable (some embedded webviews, blocked
  cookies), fall back to `prefsFactoryMemory` / `prefsAsyncFactoryMemory`
  rather than letting the open throw.
* Testing: mark the test `@TestOn('browser')` and run with
  `dart test -p chrome`, or serve it with
  `webdev serve test --live-reload`. Run the shared suites from
  `tekartik_prefs_test` (dev dependency, `path: prefs_test`):
  `runPrefsTests(prefsFactoryBrowser)` and
  `runPrefsAsyncWithCacheTests(prefsAsyncWithCacheFactoryBrowser)`. Note that
  `package:tekartik_prefs_test/prefs_async_test_runner.dart` imports
  `dart:io` today, so it only compiles for the VM/Flutter, not for a browser
  test.
* Anti-patterns: touching `prefsFactoryBrowser` in code shared with the VM
  without the `OrNull` guard; assuming a fresh store between tests (the same
  origin keeps its local storage, so `deletePreferences` in `setUp`);
  storing large blobs in preferences instead of IndexedDB
  (`tekartik_prefs_sdb`).

## Examples

### Pick the browser factory, fall back to memory elsewhere

```dart
import 'package:tekartik_prefs_browser/prefs_async.dart';

/// Browser local storage on the web, in memory on the VM.
PrefsAsyncFactory get prefsAsyncFactory =>
    prefsAsyncFactoryBrowserOrNull ?? prefsAsyncFactoryMemory;

Future<void> main() async {
  var prefs = await prefsAsyncFactory.openPreferences('my_app.prefs');
  await prefs.setString('user', 'alex');
  await prefs.setMap('window', {'width': 800, 'height': 600});
  print(await prefs.getString('user'));
  await prefs.close();
}
```

### Light prefs for a few settings

```dart
import 'package:tekartik_prefs_browser/prefs_light.dart';

// Local storage on the web, memory on the VM.
final PrefsLight prefs =
    getPrefsLightBrowserOrNull(name: 'my_app') ?? PrefsMemory();

Future<void> main() async {
  await prefs.setBool('dark', true); // localStorage['my_app/dark'] = 'true'
  print(await prefs.getBool('dark')); // true
  await prefs.setMap('window', {'width': 800});
}
```

### Synchronous reads in a web app with the cached factory

```dart
import 'package:tekartik_prefs_browser/prefs_async.dart';

class AppSettings {
  final PrefsAsyncWithCache prefs;

  AppSettings(this.prefs);

  static Future<AppSettings> open() async => AppSettings(
    await (prefsAsyncWithCacheFactoryBrowserOrNull ??
            prefsAsyncWithCacheFactoryMemory)
        .openPreferences('my_app.prefs', version: 1),
  );

  // No await needed once opened.
  bool get dark => prefs.getBool('dark') ?? false;

  Future<void> setDark(bool value) => prefs.setBool('dark', value);
}

Future<void> main() async {
  var settings = await AppSettings.open();
  await settings.setDark(true);
  print(settings.dark); // true
}
```

### Legacy synchronous prefs in local storage

```dart
import 'package:tekartik_prefs_browser/prefs.dart';

Future<void> main() async {
  var factory = prefsFactoryBrowserOrNull ?? prefsFactoryMemory;
  var prefs = await factory.openPreferences('basic');

  prefs.setInt('test', 1); // stored as localStorage['basic/test'] = '1'
  print(prefs.getInt('test')); // 1

  await prefs.save(); // flush the background write
  await prefs.close();
}
```

### Browser test running the shared suites

```dart
@TestOn('browser')
library;

import 'package:tekartik_prefs_browser/prefs.dart';
import 'package:tekartik_prefs_browser/prefs_async.dart';
import 'package:tekartik_prefs_test/prefs_async_with_cache_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_test_runner.dart' as prefs;
import 'package:test/test.dart';

void main() {
  prefs.runPrefsTests(prefsFactoryBrowser);
  runPrefsAsyncWithCacheTests(prefsAsyncWithCacheFactoryBrowser);

  test('factories', () {
    expect(prefsFactoryBrowserOrNull, prefsFactoryBrowser);
    expect(prefsAsyncFactoryBrowserOrNull, prefsAsyncFactoryBrowser);
  });
}
```
