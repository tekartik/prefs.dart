library tekartik_db_browser.test.all_test;

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_prefs_sembast/prefs.dart';
import 'package:tekartik_prefs_test/prefs_test.dart' as prefs;

void main() {
  prefs.runTests(getPrefsFactorySembast(databaseFactoryMemory, '.'));
}
