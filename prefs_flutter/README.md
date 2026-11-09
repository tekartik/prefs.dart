# tekartik_prefs_flutter

[tekartik_prefs](../prefs/README.md) stored with the `shared_preferences`
plugin, for Flutter apps on Android, iOS, macOS, Linux, Windows and the web.
Keys are `'<prefs name>/<key>'` in shared preferences.

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_prefs_flutter:
    git:
      url: https://github.com/tekartik/prefs.dart
      path: prefs_flutter
```

```dart
import 'package:flutter/widgets.dart';
import 'package:tekartik_prefs_flutter/prefs_async.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Synchronous reads once opened, async writes.
  var prefs = await prefsAsyncWithCacheFactoryFlutter.openPreferences(
    'settings',
    version: 1,
    onVersionChanged: (prefs, oldVersion, newVersion) async {
      if (oldVersion == 0) {
        await prefs.setBool('dark', false); // first run default
      }
    },
  );
  print(prefs.getBool('dark')); // false
  await prefs.setBool('dark', true);
}
```

## Which factory

| Import | Factory | Backend |
|---|---|---|
| `prefs_async.dart` | `prefsAsyncWithCacheFactoryFlutter` | `SharedPreferencesWithCache`, sync reads |
| `prefs_async.dart` | `prefsAsyncFactoryFlutter` | `SharedPreferencesWithCache` by default, `SharedPreferencesAsync` with `strictType: true` |
| `prefs_light.dart` | `prefsFlutter` (a `PrefsLight`) | legacy `SharedPreferences`, raw keys |
| `prefs.dart` | `prefsFactoryFlutter` (older sync API) | legacy `SharedPreferences` |

## Common pitfalls

* Call `WidgetsFlutterBinding.ensureInitialized()` before opening anything.
* Call `prefsAsyncFactoryFlutter.init(options: ...)` once, before the first
  open: in debug mode switching `strictType` later drops the other backend.
* A prefs owns every key starting with `'<name>/'`: prefs `a` also lists,
  clears and deletes the keys of a prefs named `a/b`. Do not nest prefs names
  and avoid `/` in keys.
* `prefsFlutter` (light) reads strictly: `getString` of an int is null, where
  the light prefs of the other backends return `'1'`.
* Doubles are floats on Android; on the web, values go to local storage.

## Testing

```bash
flutter test
```

The tests run every `tekartik_prefs_test` suite on in memory shared
preferences: `SharedPreferences.setMockInitialValues({})` for the legacy API,
`SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty()`
(from `shared_preferences_platform_interface`) for the async ones (see
`test/prefs_flutter_async_test.dart`).
