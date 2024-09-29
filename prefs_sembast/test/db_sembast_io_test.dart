@TestOn('vm')
library;

import 'package:path/path.dart';
import 'package:sembast/sembast_io.dart';
import 'package:tekartik_prefs_sembast/prefs.dart';
import 'package:tekartik_prefs_test/prefs_test.dart' as prefs;
import 'package:test/test.dart';

void main() {
  prefs.runTests(getPrefsFactorySembast(
      databaseFactoryIo, join('.dart_tool', 'tekartik_prefs_sembast', 'test')));
}
