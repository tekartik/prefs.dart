---
name: tekartik-prefs-flutter-setup
description: >-
  Use when wiring tekartik_prefs into a Flutter app on top of shared_preferences
  with tekartik_prefs_flutter: prefsAsyncFactoryFlutter,
  prefsAsyncWithCacheFactoryFlutter, prefsFactoryFlutter, prefsFlutter, the
  package:tekartik_prefs_flutter/prefs_async.dart, prefs.dart, prefs_light.dart
  and prefs_mock.dart imports, WidgetsFlutterBinding.ensureInitialized, the
  strictType SharedPreferencesAsync vs SharedPreferencesWithCache choice, and
  testing with PrefsFactoryFlutterMock / initSharedPreferencesMock.
---

# tekartik_prefs_flutter: the shared_preferences implementation (tekartik_prefs_flutter)

`tekartik_prefs_flutter` implements the `tekartik_prefs` factories on top of
the `shared_preferences` plugin, so app code depends on the storage agnostic
`PrefsAsync` / `PrefsAsyncWithCache` / `PrefsLight` interfaces and works the
same on Android, iOS, desktop and Flutter web.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_prefs_flutter:
      git:
        url: https://github.com/tekartik/prefs.dart
        path: prefs_flutter
  ```
  It brings `tekartik_prefs` (same repo, `path: prefs`) and
  `shared_preferences`; declare `tekartik_prefs` explicitly when shared,
  non-Flutter code imports the interfaces.
* Imports, each re-exporting its `tekartik_prefs` counterpart:
  * `package:tekartik_prefs_flutter/prefs_async.dart`: `prefsAsyncFactoryFlutter`
    (`PrefsAsyncFactory`) and `prefsAsyncWithCacheFactoryFlutter`
    (`PrefsAsyncWithCacheFactory`). Preferred for new code.
  * `package:tekartik_prefs_flutter/prefs.dart`: `prefsFactoryFlutter`, the
    legacy synchronous `PrefsFactory`.
  * `package:tekartik_prefs_flutter/prefs_light.dart`: `prefsFlutter`, a ready
    to use `PrefsLight` (single store, no factory, no versioning) backed
    directly by `SharedPreferences`.
  * `package:tekartik_prefs_flutter/prefs_mock.dart`: `PrefsFactoryFlutterMock`,
    `initSharedPreferencesMock`, `SharedPreferencesMock`,
    `sharedPreferencesMock` and `channel`, for tests.
* Call `WidgetsFlutterBinding.ensureInitialized()` in `main()` before opening
  anything: every factory lazily calls into the `shared_preferences` plugin.
* All three factories are singletons; open a named store once at startup and
  keep the `PrefsAsync` / `PrefsAsyncWithCache` around (a provider, a
  singleton service). `prefsAsyncWithCacheFactoryFlutter` is the one to use
  when widgets need values synchronously in `build`.
* `prefsAsyncFactoryFlutter` picks its backend from the options: with
  `factory.init(options: PrefsAsyncFactoryOptions(strictType: true))` it uses
  `SharedPreferencesAsync` (no in-memory cache, strict types, a wrong type
  reads back as `null`); by default it uses `SharedPreferencesWithCache` and
  converts types leniently. Call `init` once, before the first
  `openPreferences`.
* Keys are namespaced per prefs name: the underlying `shared_preferences` key
  is `'<prefsName>/<key>'` (on top of the plugin's own platform prefix). Values
  are stored with their native `shared_preferences` type; maps and lists go in
  as json strings.
* Platform notes: on Android doubles are stored as floats; on web
  `shared_preferences` uses local storage, so the same size caveats as
  `tekartik_prefs_browser` apply. Prefer `tekartik_prefs_sembast` or
  `tekartik_prefs_sdb` for anything bigger than settings.
* Testing: `TestWidgetsFlutterBinding.ensureInitialized()` then
  `PrefsFactoryFlutterMock()` (a `PrefsFactory`, it calls
  `initSharedPreferencesMock()` for you) and run
  `runPrefsTests(...)` from
  `package:tekartik_prefs_test/prefs_test_runner.dart`.
  `initSharedPreferencesMock([data])` alone seeds a mocked `SharedPreferences`
  for widget tests. The mock covers the legacy synchronous factory; to test
  code written against `PrefsAsyncFactory` without the plugin, inject
  `prefsAsyncFactoryMemory` instead.
* Anti-patterns: importing `package:shared_preferences/shared_preferences.dart`
  directly in app code next to this package (double bookkeeping on the same
  keys); opening the same prefs name through both the sync and async families;
  calling `openPreferences` on every read instead of caching the store.

## Examples

### App startup with synchronous reads in widgets

```dart
import 'package:flutter/material.dart';
import 'package:tekartik_prefs_flutter/prefs_async.dart';

late final PrefsAsyncWithCache appPrefs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appPrefs = await prefsAsyncWithCacheFactoryFlutter.openPreferences(
    'my_app.prefs',
    version: 1,
    onVersionChanged: (prefs, oldVersion, newVersion) async {
      if (oldVersion == 0) {
        await prefs.setBool('dark', false);
      }
    },
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // No await: the store is cached in memory.
    var dark = appPrefs.getBool('dark') ?? false;
    return MaterialApp(
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => appPrefs.setBool('dark', !dark),
            child: const Text('Toggle theme'),
          ),
        ),
      ),
    );
  }
}
```

### Fully async prefs, strict shared_preferences types

```dart
import 'package:flutter/widgets.dart';
import 'package:tekartik_prefs_flutter/prefs_async.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uses SharedPreferencesAsync, no implicit type conversion.
  prefsAsyncFactoryFlutter.init(
    options: PrefsAsyncFactoryOptions(strictType: true),
  );

  var prefs = await prefsAsyncFactoryFlutter.openPreferences('my_app.prefs');
  await prefs.setString('user', 'alex');
  await prefs.setStringList('recent', ['a', 'b']);
  print(await prefs.getString('user'));
  print(await prefs.getInt('user')); // null: strict types
  print(await prefs.getKeys());
  await prefs.close();
}
```

### The one-liner PrefsLight store

```dart
import 'package:flutter/widgets.dart';
import 'package:tekartik_prefs_flutter/prefs_light.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PrefsLight prefs = prefsFlutter; // global, backed by SharedPreferences
  await prefs.setString('user', 'alex');
  await prefs.setIntOrNull('count', null); // removes the key
  await prefs.setMap('window', {'width': 800.0});
  print(await prefs.getString('user'));
  print(await prefs.getMap('window'));
}
```

### Legacy synchronous factory

```dart
import 'package:flutter/widgets.dart';
import 'package:tekartik_prefs_flutter/prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var prefs = await prefsFactoryFlutter.openPreferences('basic');
  prefs.setInt('test', 1); // shared_preferences key 'basic/test'
  print(prefs.getInt('test')); // 1, synchronous
  await prefs.save(); // flush to shared_preferences
  await prefs.close();
}
```

### Test with the mock factory

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_prefs_flutter/prefs_mock.dart';
import 'package:tekartik_prefs_test/prefs_test_runner.dart' as prefs;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The whole shared tekartik_prefs suite, on a mocked shared_preferences.
  prefs.runPrefsTests(PrefsFactoryFlutterMock());

  test('seeded values', () async {
    await initSharedPreferencesMock({'greeting': 'hello'});
    var factory = PrefsFactoryFlutterMock();
    var myPrefs = await factory.openPreferences('basic');
    myPrefs.setInt('test', 1);
    expect(myPrefs.getInt('test'), 1);
    await myPrefs.close();
  });
}
```
