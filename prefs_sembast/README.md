# tekartik_prefs_sembast

[tekartik_prefs](../prefs/README.md) stored in sembast databases, one database
per prefs name under a directory you choose: a file on the Dart VM and Flutter
native (`databaseFactoryIo`), IndexedDB on the web (`sembast_web`), memory in
tests.

## Getting started

Git package, not on pub.dev; add `sembast` to pick the `DatabaseFactory`:

```yaml
dependencies:
  tekartik_prefs_sembast:
    git:
      url: https://github.com/tekartik/prefs.dart
      path: prefs_sembast
  sembast: '>=3.7.4+3'
```

```dart
import 'package:path/path.dart';
import 'package:sembast/sembast_io.dart';
import 'package:tekartik_prefs_sembast/prefs_async.dart';

Future<void> main() async {
  // Database files in .dart_tool/my_app/prefs/<prefs name>
  var factory = getPrefsAsyncFactorySembast(
    databaseFactoryIo,
    join('.dart_tool', 'my_app', 'prefs'),
  );
  var prefs = await factory.openPreferences('settings', version: 1);
  await prefs.setString('user', 'alex');
  print(await prefs.getString('user')); // alex
  await prefs.close();
}
```

Runnable (in memory): [example/main.dart](example/main.dart).

## Factories

| Import | Builder |
|---|---|
| `prefs_async.dart` | `getPrefsAsyncFactorySembast(databaseFactory, path)`, `getPrefsAsyncWithCacheFactorySembast(databaseFactory, path)` |
| `prefs_light.dart` | `getPrefsLightSembast(databaseFactory: , path: )` (one `prefs.db`) |
| `prefs.dart` | `getPrefsFactorySembast(databaseFactory, path)` (older sync API) |

`DatabaseFactory`: `databaseFactoryIo` (`package:sembast/sembast_io.dart`),
`newDatabaseFactoryMemory()` (`package:sembast/sembast_memory.dart`),
`databaseFactoryWeb` (`sembast_web`).

## Common pitfalls

* Build the prefs factory once: each one caches its opened prefs (two
  factories on the same path would open the same database twice).
* Do not import `sembast_io.dart` in code compiled for the web.
* Keep values JSON like: maps with `String` keys only (sembast refuses other
  keys, the background save of the sync prefs then fails).
* The sync `Prefs` writes in the background: `await prefs.save()` or
  `close()` before relying on the file.

## Testing

```bash
dart test -p vm
dart test -p chrome
```

The tests run every `tekartik_prefs_test` suite on memory and io sembast
factories.
