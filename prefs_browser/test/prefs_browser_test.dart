@TestOn('browser')
library;

import 'package:tekartik_prefs_browser/prefs.dart';
import 'package:tekartik_prefs_browser/prefs_async.dart';
import 'package:tekartik_prefs_browser/prefs_light.dart';
import 'package:tekartik_prefs_test/kv_store_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_async_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_async_with_cache_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_light_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_test_runner.dart' as prefs;
import 'package:test/test.dart';
import 'package:web/web.dart' show window;

void main() {
  prefs.runPrefsTests(prefsFactoryBrowser);
  runPrefsAsyncTests(prefsAsyncFactoryBrowser);
  runPrefsAsyncWithCacheTests(prefsAsyncWithCacheFactoryBrowser);
  group('light', () {
    runPrefsLightTests(
      getPrefsLightBrowser(name: 'tekartik_prefs_browser_test_light'),
    );
    group('kv_store', () {
      runKvStoreTests(
        getPrefsLightBrowser(name: 'tekartik_prefs_browser_test_kv_store'),
      );
    });
    test('storage', () async {
      var prefs = getPrefsLightBrowser(
        name: 'tekartik_prefs_browser_test_light_storage',
      );
      await prefs.setInt('int', 1);
      await prefs.setString('string', 'text');
      expect(
        window.localStorage.getItem(
          'tekartik_prefs_browser_test_light_storage/int',
        ),
        '1',
      );
      expect(
        window.localStorage.getItem(
          'tekartik_prefs_browser_test_light_storage/string',
        ),
        '"text"',
      );
      // Another instance reads the same storage
      prefs = getPrefsLightBrowser(
        name: 'tekartik_prefs_browser_test_light_storage',
      );
      expect(await prefs.getInt('int'), 1);
      await prefs.remove('int');
      expect(
        window.localStorage.getItem(
          'tekartik_prefs_browser_test_light_storage/int',
        ),
        isNull,
      );
    });
  });
  test('factories', () {
    expect(prefsFactoryBrowserOrNull, prefsFactoryBrowser);
    expect(prefsAsyncFactoryBrowserOrNull, prefsAsyncFactoryBrowser);
    expect(getPrefsLightBrowserOrNull(), isNotNull);
  });
}
