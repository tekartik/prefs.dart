import 'package:tekartik_prefs/prefs.dart';
import 'package:tekartik_prefs/prefs_async.dart';
import 'package:tekartik_prefs/prefs_light.dart';

/// Browser prefs factory (throw if not on web)
PrefsFactory get prefsFactoryBrowser =>
    throw UnimplementedError('prefsFactoryBrowser only for the web');

/// Browser async prefs factory or null if not on web
PrefsFactory? get prefsFactoryBrowserOrNull => null;

/// Browser async prefs factory (throw if not on web)
PrefsAsyncFactory get prefsAsyncFactoryBrowser =>
    throw UnimplementedError('prefsFactoryBrowser only for the web');

/// Browser async prefs factory or null if not on web
PrefsAsyncFactory? get prefsAsyncFactoryBrowserOrNull => null;

/// Browser async prefs factory (throw if not on web)
PrefsAsyncWithCacheFactory get prefsAsyncWithCacheFactoryBrowser =>
    throw UnimplementedError('prefsFactoryBrowser only for the web');

/// Browser async prefs factory or null if not on web
PrefsAsyncWithCacheFactory? get prefsAsyncWithCacheFactoryBrowserOrNull => null;

/// Check if the storage browser is available
bool checkStorageBrowserIsAvailable({bool? persistent}) => false; // Only on web

/// Browser light prefs (throw if not on web)
PrefsLight getPrefsLightBrowser({String? name}) =>
    throw UnimplementedError('getPrefsLightBrowser only for the web');

/// Browser light prefs or null if not on web
PrefsLight? getPrefsLightBrowserOrNull({String? name}) => null;
