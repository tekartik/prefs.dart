// ignore_for_file: avoid_print

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_prefs_sembast/prefs_async.dart';

/// Versioned prefs on sembast: databaseFactoryIo and a directory on the VM,
/// memory here.
Future<void> main() async {
  var factory = getPrefsAsyncFactorySembast(newDatabaseFactoryMemory(), '.');
  var prefs = await factory.openPreferences(
    'settings',
    version: 1,
    onVersionChanged: (prefs, oldVersion, newVersion) async {
      if (oldVersion == 0) {
        await prefs.setString('theme', 'dark'); // first run default
      }
    },
  );
  print(await prefs.getString('theme')); // dark
  await prefs.setInt('count', 1);
  print(await prefs.getKeys()); // {count, theme}
  await prefs.close();
}
