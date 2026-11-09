// ignore_for_file: avoid_print

/// Versioned preferences, in memory.
///
/// An app passes a backend factory to `run` instead:
/// `prefsAsyncFactoryFlutter` (tekartik_prefs_flutter),
/// `prefsAsyncFactoryBrowser` (tekartik_prefs_browser),
/// `getPrefsAsyncFactorySembast(...)` (tekartik_prefs_sembast).
library;

import 'package:tekartik_prefs/prefs_async.dart';

Future<void> run(PrefsAsyncFactory factory) async {
  var prefs = await factory.openPreferences(
    'settings',
    version: 2,
    onVersionChanged: (prefs, oldVersion, newVersion) async {
      // Runs during the open: seed or migrate.
      if (oldVersion < 1) {
        await prefs.setString('theme', 'dark');
      }
      if (oldVersion < 2) {
        await prefs.setInt('fontSize', 14);
      }
    },
  );
  print('version ${prefs.version}'); // version 2
  print(await prefs.getString('theme')); // dark
  await prefs.setIntOrNull('fontSize', null); // removes it
  await prefs.setList('recent', ['a.txt', 'b.txt']);
  print(await prefs.getList('recent')); // [a.txt, b.txt]
  print(await prefs.getKeys()); // {theme, recent}
  await prefs.close();
}

Future<void> main() async {
  // A sandbox keeps the stores of a feature (or a test) apart.
  await run(newPrefsAsyncFactoryMemory().sandbox(path: 'my_feature'));
}
