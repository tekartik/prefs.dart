@TestOn('browser')
library;

import 'package:tekartik_prefs_browser/prefs.dart';
import 'package:tekartik_prefs_browser/prefs_async.dart';
import 'package:tekartik_prefs_test/prefs_async_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_async_with_cache_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_test_runner.dart' as prefs;
import 'package:test/test.dart';

void main() {
  prefs.runPrefsTests(prefsFactoryBrowser);
  runPrefsAsyncTests(prefsAsyncFactoryBrowser);
  runPrefsAsyncWithCacheTests(prefsAsyncWithCacheFactoryBrowser);
  test('factories', () {
    expect(prefsFactoryBrowserOrNull, prefsFactoryBrowser);
    expect(prefsAsyncFactoryBrowserOrNull, prefsAsyncFactoryBrowser);
  });
}
