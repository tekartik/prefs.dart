library;

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_prefs_sembast/prefs.dart';
import 'package:tekartik_prefs_sembast/prefs_async.dart';
import 'package:tekartik_prefs_test/prefs_async_test.dart';
import 'package:tekartik_prefs_test/prefs_test.dart' as prefs;

void main() {
  runPrefsAsyncTests(getPrefsAsyncFactorySembast(databaseFactoryMemory, '.'));
  prefs.runPrefsTests(getPrefsFactorySembast(databaseFactoryMemory, '.'));
}
