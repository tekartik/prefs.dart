import 'package:tekartik_prefs/prefs_light.dart';

import 'prefs_async_browser.dart';

const _nameDefault = 'prefs';

/// [PrefsLight] on top of the browser local storage.
///
/// Values are json encoded in `'<name>/<key>'` entries, [name] defaults to
/// `prefs`.
PrefsLight getPrefsLightBrowser({String? name}) {
  var prefsName = name ?? _nameDefault;
  return PrefsLightAsync.lazy(
    initDelegate: () => prefsAsyncFactoryBrowser.openPreferences(prefsName),
  );
}

/// [PrefsLight] on top of the browser local storage, null if not on web.
PrefsLight? getPrefsLightBrowserOrNull({String? name}) =>
    getPrefsLightBrowser(name: name);
