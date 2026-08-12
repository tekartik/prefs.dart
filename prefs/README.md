## Setup

`pubspec.yaml`:

```yaml
  tekartik_prefs:
    git:
      url: https://github.com/tekartik/prefs.dart
      path: prefs
    version: '>=0.1.0'
```

## KvStore

`KvStore` is the minimal string key/value interface, split in `KvStoreRead`
(`getString`) and `KvStoreWrite` (`setString`, `remove`). Depend on it when all
you need is to read and write strings, instead of a full prefs implementation.

`PrefsLight` implements it, so any prefs (memory, sembast, sdb, browser,
flutter) can be passed where a `KvStore` is expected.

A store can also be built from the 3 methods, without writing a class:

```dart
import 'package:tekartik_prefs/kv_store.dart';

var map = <String, String>{};
var store = KvStore(
  getString: (key) async => map[key],
  setString: (key, value) async => map[key] = value,
  remove: (key) async => map.remove(key),
);

await store.setString('key', 'value');
await store.setStringOrNull('key', null); // remove
```
