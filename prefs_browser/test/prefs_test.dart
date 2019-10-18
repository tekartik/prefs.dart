@TestOn('browser')
library tekartik_db_browser.test.prefs_test;

import 'package:tekartik_prefs_test/prefs_test.dart' as prefs;
import 'package:test/test.dart';
import 'package:tekartik_prefs_browser/prefs.dart';

void main() {
  prefs.runTests(prefsFactoryBrowser);
}
