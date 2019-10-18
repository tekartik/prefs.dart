@TestOn('vm')
library tekartik_db_browser.test.all_test;

import 'package:path/path.dart';
import 'package:tekartik_prefs_test/prefs_test.dart' as prefs;
import 'package:tekartik_prefs_sembast/prefs.dart';
import 'package:sembast/sembast_io.dart';
import 'package:test/test.dart';

void main() {
  prefs.runTests(getPrefsFactorySembast(
      databaseFactoryIo, join('.dart_tool', 'tekartik_prefs_sembast', 'test')));
}
