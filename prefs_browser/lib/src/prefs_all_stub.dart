import 'package:tekartik_prefs/prefs.dart';
import 'package:tekartik_prefs/prefs_async.dart';

/// Browser prefs factory (throw if not on web)
PrefsFactory get prefsFactoryBrowser =>
    throw UnimplementedError('prefsFactoryBrowser only for the web');

/// Browser async prefs factory or null if not on web
PrefsFactory? get prefsFactoryBrowserOrNull => null;

/// Browser async prefs factory (throw if not on web)
PrefsAsyncFactory get prefsAsyncFactoryBrowser =>
    throw UnimplementedError('prefsFactoryBrowser only for the web');

/// Browser async prefs factory or null if not on web
PrefsFactory? get prefsAsyncFactoryBrowserOrNull => null;

/// Check if the storage browser is available
bool checkStorageBrowserIsAvailable({bool? persistent}) => false; // Only on web
