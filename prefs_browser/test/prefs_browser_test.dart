@TestOn('browser')
library;

import 'package:tekartik_prefs_browser/prefs.dart';
import 'package:tekartik_prefs_browser/prefs_async.dart';
import 'package:tekartik_prefs_test/prefs_async_test.dart';
import 'package:tekartik_prefs_test/prefs_test.dart' as prefs;
import 'package:test/test.dart';

void main() {
  prefs.runPrefsTests(prefsFactoryBrowser);
  runPrefsAsyncTests(prefsAsyncFactoryBrowser);
  test('factories', () {
    expect(prefsFactoryBrowserOrNull, prefsFactoryBrowser);
    expect(prefsAsyncFactoryBrowserOrNull, prefsAsyncFactoryBrowser);
  });
}
