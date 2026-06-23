import 'package:idb_shim/sdb/sdb.dart' as sdb;
import 'package:tekartik_prefs/prefs_light.dart';
import 'package:tekartik_prefs_sdb/prefs_async.dart';

/// PrefsLight implementation for Sdb.
PrefsLight getPrefsLightSdb(
  sdb.SdbFactory sdbFactory, {

  /// Default to prefs.db
  String? name,
}) {
  var prefsName = name ?? 'prefs.db';
  var prefsAsyncFactory = getPrefsAsyncFactorySdb(sdbFactory);
  return PrefsLightAsync.lazy(
    initDelegate: () async {
      var prefsAsync = await prefsAsyncFactory.openPreferences(prefsName);
      return prefsAsync;
    },
  );
}
