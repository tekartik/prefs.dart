// ignore_for_file: avoid_print

import 'package:idb_shim/sdb/sdb.dart';
import 'package:tekartik_prefs_sdb/prefs_async.dart';

/// Versioned prefs on sdb: sdbFactoryWeb (IndexedDB) on the web, sdbFactoryIo
/// on the VM, memory here.
Future<void> main() async {
  var factory = getPrefsAsyncWithCacheFactorySdb(newSdbFactoryMemory());
  var prefs = await factory.openPreferences(
    'settings',
    version: 1,
    onVersionChanged: (prefs, oldVersion, newVersion) async {
      // Runs in the open transaction: only await this prefs here.
      if (oldVersion == 0) {
        await prefs.setBool('dark', false);
      }
    },
  );
  print(prefs.getBool('dark')); // false, synchronous read
  await prefs.setBool('dark', true);
  await prefs.setMap('window', {'width': 800});
  print(prefs.getMap('window')); // {width: 800}
  await prefs.close();
}
