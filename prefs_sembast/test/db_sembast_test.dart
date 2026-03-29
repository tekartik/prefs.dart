library;

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_prefs_sembast/prefs.dart';
import 'package:tekartik_prefs_sembast/prefs_async.dart';
import 'package:tekartik_prefs_sembast/prefs_light.dart';
import 'package:tekartik_prefs_test/prefs_async_test.dart';
import 'package:tekartik_prefs_test/prefs_async_with_cache_test.dart';
import 'package:tekartik_prefs_test/prefs_light_test.dart';
import 'package:tekartik_prefs_test/prefs_test.dart' as prefs;

void main() {
  runPrefsAsyncTests(
    getPrefsAsyncFactorySembast(newDatabaseFactoryMemory(), '.'),
  );
  runPrefsAsyncWithCacheTests(
    getPrefsAsyncWithCacheFactorySembast(newDatabaseFactoryMemory(), '.'),
  );
  prefs.runPrefsTests(getPrefsFactorySembast(newDatabaseFactoryMemory(), '.'));
  runPrefsLightTests(
    getPrefsLightSembast(
      databaseFactory: newDatabaseFactoryMemory(),
      path: '.',
    ),
  );
}
