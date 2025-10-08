import 'package:cv/cv_json.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_prefs/prefs_async.dart';
import 'package:test/test.dart';

export 'package:tekartik_prefs/prefs_async.dart';

void main() {
  runPrefsAsyncWithCacheTests(prefsAsyncWithCacheFactoryMemory);
}

void runPrefsAsyncWithCacheTests(PrefsAsyncWithCacheFactory factory) {
  _runPrefsAsyncWithCacheTests(factory);
}

void _runPrefsAsyncWithCacheTests(PrefsAsyncWithCacheFactory factory) {
  Future<PrefsAsyncWithCache> deleteAndOpen(String name) async {
    // print('factory: ${factory.runtimeType}');
    await factory.deletePreferences(name);
    return await factory.openPreferences(name);
  }

  group('prefs', () {
    test('quick', () async {
      var prefs = await deleteAndOpen('quick');
      // devWarning('quick debug code')
      await prefs.close();
    }, skip: true);

    test('bad type', () async {
      var prefs = await deleteAndOpen('bad_type');
      await prefs.setInt('test', 1);
      expect(prefs.getString('test'), '1');

      await prefs.setString('test', 'dummy');
      expect(prefs.getInt('dummy'), isNull);
      // devWarning('quick debug code')
      await prefs.close();
    });
    test('double', () async {
      var name = 'double_conversion';
      var prefs = await deleteAndOpen(name);

      await prefs.setDouble('test', 1.0);
      expect(prefs.getDouble('test'), 1.0);
      await prefs.close();
      prefs = await factory.openPreferences(name);
      expect(prefs.getDouble('test'), 1.0);
      if (kDartIsWebJs) {
        print(debugEnvMap.cvToJsonPretty());
        expect(prefs.getString('test'), '1');
      } else {
        expect(prefs.getString('test'), '1.0');
      }

      await prefs.close();
    });
    test('basic', () async {
      var name = 'test.prefs';

      var prefs = await deleteAndOpen(name);
      try {
        expect(prefs.getInt('test'), isNull);
        await prefs.setInt('test', 1);
        expect(prefs.getInt('test'), 1);

        expect(prefs.keys, ['test']);
      } finally {
        await prefs.close();
      }
    });
    test('timing serial', () async {
      var name = 'timing_serial';

      var prefs = await deleteAndOpen(name);
      try {
        await prefs.setInt('test', 1);
        expect(prefs.getInt('test'), 1);
        await prefs.setInt('test', 2);
        expect(prefs.getInt('test'), 2);
        await prefs.remove('test');
        expect(prefs.getInt('test'), isNull);
      } finally {
        await prefs.close();
      }
    });

    test('delete', () async {
      var name = 'delete.prefs';

      var prefs = await deleteAndOpen(name);
      await prefs.setInt('test', 1);
      await prefs.close();

      try {
        prefs = await deleteAndOpen(name);
        expect(prefs.getInt('test'), isNull);
      } finally {
        await prefs.close();
      }
    });
    test('first version no migration', () async {
      // print('factory: ${factory.runtimeType} $factory');
      var name = 'clear.prefs';
      await factory.deletePreferences(name);
      var openedPrefs = await factory.openPreferences(name, version: 1);
      await openedPrefs.setBool('test', true);
      await openedPrefs.close();
    });
    test('first migration clear', () async {
      // print('factory: ${factory.runtimeType} $factory');
      var name = 'clear.prefs';
      await factory.deletePreferences(name);
      var openedPrefs = await factory.openPreferences(
        name,
        version: 1,
        onVersionChanged: (prefs, oldVersion, newVersion) async {
          await prefs.setBool('test', true);
        },
      );
      await openedPrefs.setBool('test', true);
      await openedPrefs.close();
    });
    test('change prefs during version change', () async {
      var name = 'version.prefs';
      await factory.deletePreferences(name);

      Future onVersionChanged1(
        PrefsAsyncWithCache prefs,
        int oldVersion,
        int newVersion,
      ) async {
        await prefs.setInt('value', 1);
      }

      var prefs = await factory.openPreferences(
        name,
        version: 1,
        onVersionChanged: onVersionChanged1,
      );
      expect(prefs.version, 1);
      expect(prefs.getInt('value'), 1);
      await prefs.close();

      Future onVersionChanged2(
        PrefsAsyncWithCache prefs,
        int oldVersion,
        int newVersion,
      ) async {
        expect(prefs.getInt('value'), 1);
        await prefs.setInt('value', 2);
      }

      prefs = await factory.openPreferences(
        name,
        version: 2,
        onVersionChanged: onVersionChanged2,
      );
      expect(prefs.version, 2);
      expect(prefs.getInt('value'), 2);
      await prefs.close();

      // clear during version change
      Future onVersionChanged3(
        PrefsAsyncWithCache prefs,
        int oldVersion,
        int newVersion,
      ) async {
        await prefs.clear();
        await prefs.setInt('value2', 3);
      }

      prefs = await factory.openPreferences(
        name,
        version: 3,
        onVersionChanged: onVersionChanged3,
      );
      expect(prefs.version, 3);
      expect(prefs.getInt('value'), isNull);
      expect(prefs.getInt('value2'), 3);
      await prefs.close();
    });
    test('version', () async {
      // devPrint('factory: ${factory.runtimeType} $factory');
      var name = 'version.prefs';
      await factory.deletePreferences(name);
      var onVersionChangedCalled = false;
      Future onVersionChanged1(
        PrefsAsyncWithCache prefs,
        int oldVersion,
        int newVersion,
      ) async {
        expect(oldVersion, 0);
        expect(newVersion, 1);
        expect(prefs.version, 0);
        onVersionChangedCalled = true;
      }

      var prefs = await factory.openPreferences(
        name,
        version: 1,
        onVersionChanged: onVersionChanged1,
      );
      expect(prefs.version, 1);
      expect(onVersionChangedCalled, true);
      onVersionChangedCalled = false;
      await prefs.close();
      prefs = await factory.openPreferences(
        name,
        version: 1,
        onVersionChanged: onVersionChanged1,
      );
      expect(prefs.version, 1);
      expect(onVersionChangedCalled, false);
      await prefs.close();
      Future onVersionChanged2(
        PrefsAsyncWithCache prefs,
        int oldVersion,
        int newVersion,
      ) async {
        expect(oldVersion, 1);
        expect(newVersion, 2);
        expect(prefs.version, 1);
        onVersionChangedCalled = true;
      }

      prefs = await factory.openPreferences(
        name,
        version: 2,
        onVersionChanged: onVersionChanged2,
      );
      expect(prefs.version, 2);
      expect(onVersionChangedCalled, true);

      await prefs.close();
    });

    test('orNull', () async {
      var name = 'or_null.prefs';
      var prefs = await deleteAndOpen(name);
      try {
        await prefs.setIntOrNull('test', 1);
        expect(prefs.getInt('test'), 1);
        await prefs.setIntOrNull('test', null);
        expect(prefs.getInt('test'), null);
        await prefs.setDoubleOrNull('test', 1.0);
        expect(prefs.getDouble('test'), 1.0);
        await prefs.setDoubleOrNull('test', null);
        expect(prefs.getDouble('test'), null);
        await prefs.setBoolOrNull('test', true);
        expect(prefs.getBool('test'), true);
        await prefs.setBoolOrNull('test', null);
        expect(prefs.getBool('test'), null);
        await prefs.setStringOrNull('test', '1');
        expect(prefs.getString('test'), '1');
        await prefs.setStringOrNull('test', null);
        expect(prefs.getString('test'), null);
      } finally {
        await prefs.close();
      }
    });
    test('persistent', () async {
      var name = 'persistent.prefs.db';
      var prefs = await deleteAndOpen(name);

      await prefs.setInt('test', 1);
      await prefs.close();
      prefs = await factory.openPreferences(name);
      expect(prefs.getInt('test'), 1);
    });
    test('keys', () async {
      var name = 'persistent.prefs.db';
      var prefs = await deleteAndOpen(name);
      try {
        await prefs.setInt('test', 1);
        expect(prefs.keys, ['test']);
        expect(prefs.containsKey('test'), isTrue);
        await prefs.remove('test');

        expect(prefs.keys, isEmpty);
        expect(prefs.containsKey('test'), isFalse);
        await prefs.setInt('test', 1);
        expect(prefs.keys, ['test']);

        await prefs.close();
        prefs = await factory.openPreferences(name);
        expect(prefs.keys, ['test']);
        expect(prefs.containsKey('test'), isTrue);

        await prefs.remove('test');

        await prefs.close();
        prefs = await factory.openPreferences(name);
        expect(prefs.keys, isEmpty);
        expect(prefs.containsKey('test'), isFalse);
      } finally {
        await prefs.close();
      }
    });

    test('types', () async {
      var name = 'type.prefs';
      var prefs = await deleteAndOpen(name);
      try {
        await prefs.setBool('testBool', true);
        expect(prefs.getBool('testBool'), true);
        expect(prefs.getBool('testBool'), true);
        await prefs.setInt('testInt', -2);
        expect(prefs.getInt('testInt'), -2);
        await prefs.setDouble('testDouble', 1.0);
        expect(prefs.getDouble('testDouble'), 1.0);
        await prefs.setString('testString', 'text');
        expect(prefs.getString('testString'), 'text');
        await prefs.setList('testList', ['1', 'test2']);
        expect(prefs.getList('testList'), ['1', 'test2']);
        await prefs.close();
        prefs = await factory.openPreferences(name);
        expect(prefs.getBool('testBool'), true);
        expect(prefs.getInt('testInt'), -2);
        expect(prefs.getDouble('testDouble'), 1.0);
        expect(prefs.getString('testString'), 'text');
        expect(prefs.getList('testList'), ['1', 'test2']);

        // change and reload
        await prefs.setInt('testInt', -1);
        expect(prefs.getInt('testInt'), -1);

        await prefs.close();
        prefs = await factory.openPreferences(name);
        expect(prefs.getBool('testBool'), true);
        expect(prefs.getInt('testInt'), -1);
      } finally {
        await prefs.close();
      }
    });

    test('type_conversion', () async {
      var name = 'type_conversion.prefs';
      var prefs = await deleteAndOpen(name);

      try {
        Future<void> check() async {
          expect(prefs.getBool('testBool'), true);

          expect(prefs.getString('testBool'), 'true');
          expect(prefs.getInt('testBool'), 1, reason: 'int testBool');
          expect(prefs.getDouble('testBool'), 1.0);
          expect(prefs.getList('testBool'), isNull);

          expect(prefs.getBool('testInt'), true);
          expect(prefs.getString('testInt'), '1');
          expect(prefs.getDouble('testInt'), 1, reason: 'double testInt');
          expect(prefs.getDouble('testInt2'), -7);
          expect(prefs.getDouble('testInt3'), 0);
          expect(prefs.getBool('testInt3'), false, reason: 'testInt3');
          expect(prefs.getString('testInt3'), '0');

          expect(prefs.getInt('testDouble'), 1, reason: 'int testTouble');
          if (kDartIsWebJs) {
            // 1.0 will encoded as an int...
            expect(prefs.getString('testDouble'), '1');
          } else {
            expect(prefs.getString('testDouble'), '1.0');
          }
          expect(prefs.getBool('testDouble'), true);
          expect(prefs.getInt('testDouble2'), -2, reason: 'int testDouble2');
          expect(prefs.getString('testDouble2'), '-1.5');
          expect(prefs.getBool('testDouble2'), true);
          expect(prefs.getBool('testDouble3'), false);

          expect(prefs.getList('testList'), ['test']);

          expect(prefs.getBool('testBool'), true);
          expect(prefs.getInt('testInt'), 1, reason: 'int testInt');

          expect(prefs.getDouble('testDouble'), 1.0, reason: 'double');
          expect(prefs.getDouble('testDouble2'), -1.5, reason: 'double -1.5');

          expect(prefs.getBool('testList'), isNull);
          expect(prefs.getInt('testList'), isNull);

          expect(prefs.getMap('testMap'), {'test': 1});
          expect(prefs.getList('testRawList'), ['test', 1]);
        }

        await prefs.setBool('testBool', true);

        await prefs.setInt('testInt', 1);
        await prefs.setInt('testInt2', -7);
        await prefs.setInt('testInt3', 0);

        await prefs.setDouble('testDouble', 1.0);
        await prefs.setDouble('testDouble2', -1.5);
        await prefs.setDouble('testDouble3', 0.0);

        await prefs.setList('testList', ['test']);

        var map = {'test': 1};
        var list = ['test', 1];
        await prefs.setMap('testMap', map);
        await prefs.setList('testRawList', list);
        await check();

        await prefs.close();
        prefs = await factory.openPreferences(name);
        await check();
      } finally {
        await prefs.close();
      }
    });

    test('two_prefs', () async {
      var name1 = 'multi_1.prefs.db';
      var name2 = 'multi_2.prefs.db';
      var prefs1 = await deleteAndOpen(name1);
      var prefs2 = await deleteAndOpen(name2);
      try {
        await prefs1.setInt('test', 1);
        await prefs2.setInt('test', 2);
        expect(prefs1.getInt('test'), 1);
        expect(prefs2.getInt('test'), 2);
        await prefs2.setInt('test', 2);

        await prefs1.close();
        await prefs2.close();
        prefs1 = await factory.openPreferences(name1);
        prefs2 = await factory.openPreferences(name2);
        expect(prefs1.getInt('test'), 1);
        expect(prefs2.getInt('test'), 2);
      } finally {
        await prefs1.close();
        await prefs2.close();
      }
    });
  });
}
