## Setup

`pubspec.yaml`:

```yaml
  tekartik_prefs_browser:
    git:
      url: https://github.com/tekartik/prefs.dart
      path: prefs_browser
    version: '>=0.1.0'
```
## Light prefs

`PrefsLight` (a `KvStore` with typed getters/setters, no factory, no need to
open or close), backed by local storage:

```dart
import 'package:tekartik_prefs_browser/prefs_light.dart';

// Browser local storage on the web, memory elsewhere.
var prefs = getPrefsLightBrowserOrNull(name: 'my_app') ?? PrefsMemory();
await prefs.setBool('dark', true); // localStorage['my_app/dark'] = 'true'
print(await prefs.getBool('dark'));
```

## Testing

    webdev serve test --live-reload
    start chrome http://localhost:8080/all_test_.html
