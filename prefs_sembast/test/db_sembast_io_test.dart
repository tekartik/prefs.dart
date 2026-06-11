@TestOn('vm')
library;

import 'package:path/path.dart';
import 'package:sembast/sembast_io.dart';
import 'package:tekartik_prefs_sembast/prefs.dart';
import 'package:tekartik_prefs_sembast/prefs_async.dart';
import 'package:tekartik_prefs_sembast/prefs_light.dart';
import 'package:tekartik_prefs_test/prefs_async_test.dart';
import 'package:tekartik_prefs_test/prefs_async_with_cache_test.dart';
import 'package:tekartik_prefs_test/prefs_light_test.dart';
import 'package:tekartik_prefs_test/prefs_test.dart' as prefs;
import 'package:test/test.dart';

void main() {
  prefs.runPrefsTests(
    getPrefsFactorySembast(
      databaseFactoryIo,
      join('.dart_tool', 'tekartik_prefs_sembast', 'test'),
    ),
  );
  runPrefsAsyncTests(
    getPrefsAsyncFactorySembast(
      databaseFactoryIo,
      join('.dart_tool', 'tekartik_prefs_sembast', 'test_async'),
    ),
  );
  runPrefsAsyncWithCacheTests(
    getPrefsAsyncWithCacheFactorySembast(
      databaseFactoryIo,
      join('.dart_tool', 'tekartik_prefs_sembast', 'test_async_with_cache'),
    ),
  );
  runPrefsLightTests(
    getPrefsLightSembast(
      databaseFactory: databaseFactoryIo,
      path: join('.dart_tool', 'tekartik_prefs_sembast', 'test_light'),
    ),
  );

  group('sandbox', () {
    test('PrefsFactory sembast io sandbox', () async {
      var factory = getPrefsFactorySembast(
        databaseFactoryIo,
        join('.dart_tool', 'tekartik_prefs_sembast', 'test_sandbox'),
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

    test('PrefsAsyncFactory sembast io sandbox', () async {
      var factory = getPrefsAsyncFactorySembast(
        databaseFactoryIo,
        join('.dart_tool', 'tekartik_prefs_sembast', 'test_async_sandbox'),
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
