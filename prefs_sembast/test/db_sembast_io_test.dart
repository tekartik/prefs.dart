@TestOn('vm')
library;

import 'package:path/path.dart';
import 'package:sembast/sembast_io.dart';
import 'package:tekartik_prefs_sembast/prefs.dart';
import 'package:tekartik_prefs_sembast/prefs_async.dart';
import 'package:tekartik_prefs_test/prefs_async_test.dart';
import 'package:tekartik_prefs_test/prefs_test.dart' as prefs;
import 'package:test/test.dart';

void main() {
  prefs.runPrefsTests(getPrefsFactorySembast(
      databaseFactoryIo, join('.dart_tool', 'tekartik_prefs_sembast', 'test')));
  runPrefsAsyncTests(getPrefsAsyncFactorySembast(databaseFactoryIo,
      join('.dart_tool', 'tekartik_prefs_sembast', 'test_async')));
}
