import 'package:sembast/sembast.dart' as sembast;
import 'package:tekartik_prefs/prefs_light.dart';
import 'package:tekartik_prefs_sembast/prefs_async.dart';

/// Placeholder not optiomized as not targetted.
PrefsLight getPrefsLightSembast({
  required sembast.DatabaseFactory databaseFactory,
  required String path,
}) {
  var prefsAsyncFactory = getPrefsAsyncFactorySembast(databaseFactory, path);
  return PrefsLightAsync.lazy(
    initDelegate: () async {
      var prefsAsync = await prefsAsyncFactory.openPreferences('prefs.db');
      return prefsAsync;
    },
  );
}
