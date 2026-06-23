@TestOn('vm')
library;

import 'package:idb_shim/sdb/sdb.dart';
import 'package:path/path.dart';
import 'package:tekartik_prefs_sdb/prefs.dart';
import 'package:tekartik_prefs_sdb/prefs_async.dart';
import 'package:tekartik_prefs_sdb/prefs_light.dart';
import 'package:tekartik_prefs_test/prefs_async_test.dart';
import 'package:tekartik_prefs_test/prefs_async_with_cache_test.dart';
import 'package:tekartik_prefs_test/prefs_light_test.dart';
import 'package:tekartik_prefs_test/prefs_test.dart' as prefs;
import 'package:test/test.dart';

void main() {
  var sdbFactory = sdbFactoryIo.sandbox(
    path: join('.dart_tool', 'tekartik_prefs_sdb', 'test'),
  );
  prefs.runPrefsTests(getPrefsFactorySdb(sdbFactory.sandbox(path: 'test')));
  runPrefsAsyncTests(
    getPrefsAsyncFactorySdb(sdbFactory.sandbox(path: 'test_async')),
  );
  runPrefsAsyncWithCacheTests(
    getPrefsAsyncWithCacheFactorySdb(
      sdbFactory.sandbox(path: 'test_async_with_cache'),
    ),
  );
  runPrefsLightTests(getPrefsLightSdb(sdbFactory.sandbox(path: 'test_light')));

  group('sandbox', () {
    test('PrefsFactory sdb io sandbox', () async {
      var factory = getPrefsFactorySdb(
        sdbFactory.sandbox(path: 'test_sandbox'),
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

    test('PrefsAsyncFactory sdb io sandbox', () async {
      var factory = getPrefsAsyncFactorySdb(
        sdbFactory.sandbox(path: 'test_async_sandbox'),
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
