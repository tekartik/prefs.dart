@TestOn('browser')
library;

import 'package:idb_shim/sdb/sdb.dart';
import 'package:tekartik_prefs_sdb/prefs.dart';
import 'package:tekartik_prefs_sdb/prefs_async.dart';
import 'package:tekartik_prefs_sdb/prefs_light.dart';
import 'package:tekartik_prefs_test/prefs_async_test.dart';
import 'package:tekartik_prefs_test/prefs_async_with_cache_test.dart';
import 'package:tekartik_prefs_test/prefs_light_test.dart';
import 'package:tekartik_prefs_test/prefs_test.dart' as prefs;
import 'package:test/test.dart';

void main() {
  prefs.runPrefsTests(
    getPrefsFactorySdb(sdbFactoryWeb.sandbox(path: 'tekartik_prefs_sdb_test')),
  );
  runPrefsAsyncTests(
    getPrefsAsyncFactorySdb(
      sdbFactoryWeb.sandbox(path: 'tekartik_prefs_sdb_test_async'),
    ),
  );
  runPrefsAsyncWithCacheTests(
    getPrefsAsyncWithCacheFactorySdb(
      sdbFactoryWeb.sandbox(path: 'tekartik_prefs_sdb_test_async_with_cache'),
    ),
  );
  runPrefsLightTests(
    getPrefsLightSdb(
      sdbFactoryWeb.sandbox(path: 'tekartik_prefs_sdb_test_light'),
    ),
  );

  group('sandbox', () {
    test('PrefsFactory sdb web sandbox', () async {
      var factory = getPrefsFactorySdb(
        sdbFactoryWeb.sandbox(path: 'tekartik_prefs_sdb_test_sandbox'),
      );
      var sandboxFactory = factory.sandbox(path: 'sub');
      var prefs = await sandboxFactory.openPreferences('test');
      expect(prefs.name, 'test');
      prefs.setBool('val', true);
      await prefs.close();

      var basePrefs = await factory.openPreferences('sub/test');
      expect(basePrefs.getBool('val'), true);
      await basePrefs.close();
    });

    test('PrefsAsyncFactory sdb web sandbox', () async {
      var factory = getPrefsAsyncFactorySdb(
        sdbFactoryWeb.sandbox(path: 'tekartik_prefs_sdb_test_async_sandbox'),
      );
      var sandboxFactory = factory.sandbox(path: 'sub');
      var prefs = await sandboxFactory.openPreferences('test');
      expect(prefs.name, 'test');
      await prefs.setBool('val', true);
      await prefs.close();

      var basePrefs = await factory.openPreferences('sub/test');
      expect(await basePrefs.getBool('val'), true);
      await basePrefs.close();
    });
  });
}
