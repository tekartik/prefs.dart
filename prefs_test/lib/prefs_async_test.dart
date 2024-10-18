import 'dart:io';

import 'package:cv/cv_json.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_prefs/prefs_async.dart';
import 'package:test/test.dart';

export 'package:tekartik_prefs/prefs_async.dart';

void main() {
  runPrefsAsyncTests(prefsAsyncFactoryMemory);
}

void runPrefsAsyncTests(PrefsAsyncFactory factory) {
  group('strict', () {
    setUpAll(() {
      factory.init(options: PrefsAsyncFactoryOptions(strictType: true));
    });
    _runPrefsAsyncTests(factory);
  });

  group('normal', () {
    setUpAll(() {
      factory.init(options: PrefsAsyncFactoryOptions());
    });
    _runPrefsAsyncTests(factory);
  });
}

void _runPrefsAsyncTests(PrefsAsyncFactory factory) {
  Future<PrefsAsync> deleteAndOpen(String name) async {
    await factory.deletePreferences(name);
    return await factory.openPreferences(name);
  }

  group('prefs', () {
    test('quick', () async {
      var prefs = await deleteAndOpen('quick');
      // devWarning('quick debug code')
      await prefs.close();
    }, skip: true);
    test('double', () async {
      var name = 'double_conversion';
      var prefs = await deleteAndOpen(name);

      await prefs.setDouble('test', 1.0);
      expect(await prefs.getDouble('test'), 1.0);
      await prefs.close();
      prefs = await factory.openPreferences(name);
      expect(await prefs.getDouble('test'), 1.0);
      if (prefs.options.strictType) {
        expect(await prefs.getString('test'), isNull);
      } else {
        if (kDartIsWebJs) {
          print(debugEnvMap.cvToJsonPretty());
          expect(await prefs.getString('test'), '1');
        } else {
          expect(await prefs.getString('test'), '1.0');
        }
      }
    });
    test('basic', () async {
      var name = 'test.prefs';

      var prefs = await deleteAndOpen(name);
      try {
        expect(await prefs.getInt('test'), isNull);
        await prefs.setInt('test', 1);
        expect(await prefs.getInt('test'), 1);

        expect(await prefs.getKeys(), ['test']);
      } finally {
        await prefs.close();
      }
    });
    test('timing serial', () async {
      var name = 'timing_serial';

      var prefs = await deleteAndOpen(name);
      try {
        await prefs.setInt('test', 1);
        expect(await prefs.getInt('test'), 1);
        await prefs.setInt('test', 2);
        expect(await prefs.getInt('test'), 2);
        await prefs.remove('test');
        expect(await prefs.getInt('test'), isNull);
      } finally {
        await prefs.close();
      }
    });
    test('timing async ', () async {
      var name = 'timing_test';

      var prefs = await deleteAndOpen(name);
      try {
        // prefs.setInt('test', 1).unawait();
        //expect(await prefs.getInt('test'), 1); TODO
        var future1 = prefs.getInt('test');
        prefs.setInt('test', 2).unawait();
        var future2 = prefs.getInt('test');
        expect(await Future.wait([future1, future2]), [1, 2]);
        expect(await prefs.getInt('test'), 2);
      } finally {
        await prefs.close();
      }
    }, skip: 'to-fix');

    test('delete', () async {
      var name = 'delete.prefs';

      var prefs = await deleteAndOpen(name);
      await prefs.setInt('test', 1);
      await prefs.close();

      try {
        prefs = await deleteAndOpen(name);
        expect(await prefs.getInt('test'), isNull);
      } finally {
        await prefs.close();
      }
    });
    test('change prefs during version change', () async {
      var name = 'version.prefs';
      await factory.deletePreferences(name);

      Future onVersionChanged1(
          PrefsAsync prefs, int oldVersion, int newVersion) async {
        await prefs.setInt('value', 1);
      }

      var prefs = await factory.openPreferences(name,
          version: 1, onVersionChanged: onVersionChanged1);
      expect(prefs.version, 1);
      expect(await prefs.getInt('value'), 1);
      await prefs.close();

      Future onVersionChanged2(
          PrefsAsync prefs, int oldVersion, int newVersion) async {
        expect(await prefs.getInt('value'), 1);
        await prefs.setInt('value', 2);
      }

      prefs = await factory.openPreferences(name,
          version: 2, onVersionChanged: onVersionChanged2);
      expect(prefs.version, 2);
      expect(await prefs.getInt('value'), 2);
      await prefs.close();

      // clear during version change
      Future onVersionChanged3(
          PrefsAsync prefs, int oldVersion, int newVersion) async {
        await prefs.clear();
        await prefs.setInt('value2', 3);
      }

      prefs = await factory.openPreferences(name,
          version: 3, onVersionChanged: onVersionChanged3);
      expect(prefs.version, 3);
      expect(await prefs.getInt('value'), isNull);
      expect(await prefs.getInt('value2'), 3);
      await prefs.close();
    });
    test('version', () async {
      var name = 'version.prefs';
      await factory.deletePreferences(name);
      var onVersionChangedCalled = false;
      Future onVersionChanged1(
          PrefsAsync prefs, int oldVersion, int newVersion) async {
        expect(oldVersion, 0);
        expect(newVersion, 1);
        expect(prefs.version, 0);
        onVersionChangedCalled = true;
      }

      var prefs = await factory.openPreferences(name,
          version: 1, onVersionChanged: onVersionChanged1);
      expect(prefs.version, 1);
      expect(onVersionChangedCalled, true);
      onVersionChangedCalled = false;
      await prefs.close();
      prefs = await factory.openPreferences(name,
          version: 1, onVersionChanged: onVersionChanged1);
      expect(prefs.version, 1);
      expect(onVersionChangedCalled, false);
      await prefs.close();
      Future onVersionChanged2(
          PrefsAsync prefs, int oldVersion, int newVersion) async {
        expect(oldVersion, 1);
        expect(newVersion, 2);
        expect(prefs.version, 1);
        onVersionChangedCalled = true;
      }

      prefs = await factory.openPreferences(name,
          version: 2, onVersionChanged: onVersionChanged2);
      expect(prefs.version, 2);
      expect(onVersionChangedCalled, true);

      await prefs.close();
    });

    test('orNull', () async {
      var name = 'or_ull.prefs';
      var prefs = await deleteAndOpen(name);
      try {
        await prefs.setIntOrNull('test', 1);
        expect(await prefs.getInt('test'), 1);
        await prefs.setIntOrNull('test', null);
        expect(await prefs.getInt('test'), null);
        await prefs.setDoubleOrNull('test', 1.0);
        expect(await prefs.getDouble('test'), 1.0);
        await prefs.setDoubleOrNull('test', null);
        expect(await prefs.getDouble('test'), null);
        await prefs.setBoolOrNull('test', true);
        expect(await prefs.getBool('test'), true);
        await prefs.setBoolOrNull('test', null);
        expect(await prefs.getBool('test'), null);
        await prefs.setStringOrNull('test', '1');
        expect(await prefs.getString('test'), '1');
        await prefs.setStringOrNull('test', null);
        expect(await prefs.getString('test'), null);
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
      expect(await prefs.getInt('test'), 1);
    });
    test('keys', () async {
      var name = 'persistent.prefs.db';
      var prefs = await deleteAndOpen(name);
      try {
        await prefs.setInt('test', 1);
        expect(await prefs.getKeys(), ['test']);
        expect(await prefs.containsKey('test'), isTrue);
        await prefs.remove('test');

        expect(await prefs.getKeys(), isEmpty);
        expect(await prefs.containsKey('test'), isFalse);
        await prefs.setInt('test', 1);
        expect(await prefs.getKeys(), ['test']);

        await prefs.close();
        prefs = await factory.openPreferences(name);
        expect(await prefs.getKeys(), ['test']);
        expect(await prefs.containsKey('test'), isTrue);

        await prefs.remove('test');

        await prefs.close();
        prefs = await factory.openPreferences(name);
        expect(await prefs.getKeys(), isEmpty);
        expect(await prefs.containsKey('test'), isFalse);
      } finally {
        await prefs.close();
      }
    });

    test('types', () async {
      var name = 'type.prefs';
      var prefs = await deleteAndOpen(name);
      try {
        await prefs.setBool('testBool', true);
        expect(await prefs.getBool('testBool'), true);
        expect(await prefs.getBool('testBool'), true);
        await prefs.setInt('testInt', -2);
        expect(await prefs.getInt('testInt'), -2);
        await prefs.setDouble('testDouble', 1.0);
        expect(await prefs.getDouble('testDouble'), 1.0);
        await prefs.setString('testString', 'text');
        expect(await prefs.getString('testString'), 'text');
        await prefs.setStringList('testList', ['1', 'test2']);
        expect(await prefs.getStringList('testList'), ['1', 'test2']);
        await prefs.close();
        prefs = await factory.openPreferences(name);
        expect(await prefs.getBool('testBool'), true);
        expect(await prefs.getInt('testInt'), -2);
        expect(await prefs.getDouble('testDouble'), 1.0);
        expect(await prefs.getString('testString'), 'text');
        expect(await prefs.getStringList('testList'), ['1', 'test2']);

        // change and reload
        await prefs.setInt('testInt', -1);
        expect(await prefs.getInt('testInt'), -1);

        await prefs.close();
        prefs = await factory.openPreferences(name);
        expect(await prefs.getBool('testBool'), true);
        expect(await prefs.getInt('testInt'), -1);
      } finally {
        await prefs.close();
      }
    });

    test('type_conversion', () async {
      var name = 'type_conversion.prefs';
      var prefs = await deleteAndOpen(name);

      try {
        Future<void> check() async {
          expect(await prefs.getBool('testBool'), true);
          if (prefs.options.strictType) {
            expect(await prefs.getString('testBool'), isNull);
            expect(await prefs.getInt('testBool'), isNull,
                reason: 'int testBool');
            expect(await prefs.getDouble('testBool'), isNull);
            expect(await prefs.getStringList('testBool'), isNull);

            expect(await prefs.getBool('testInt'), isNull);
            expect(await prefs.getString('testInt'), isNull,
                reason: 'testInt as string');
            if (kDartIsWebJs) {
              expect(await prefs.getDouble('testInt'), 1.0,
                  reason: 'double testInt js');
              expect(await prefs.getDouble('testInt2'), -7.0,
                  reason: 'double testInt 2 js');
              expect(await prefs.getDouble('testInt3'), 0);
            } else {
              expect(await prefs.getDouble('testInt'), isNull,
                  reason: 'double testInt');
              expect(await prefs.getDouble('testInt2'), isNull);
              expect(await prefs.getDouble('testInt3'), isNull);
            }

            expect(await prefs.getBool('testInt3'), isNull, reason: 'testInt3');
            expect(await prefs.getString('testInt3'), isNull);

            expect(await prefs.getInt('testDouble2'), isNull,
                reason: 'int testDouble2');
            expect(await prefs.getBool('testDouble'), isNull);
            expect(await prefs.getString('testDouble'), isNull);
            expect(await prefs.getBool('testDouble2'), isNull);

            try {
              expect(await prefs.getString('testList'), isNull);
            } catch (e) {
              if (!kDartIsWeb && Platform.isAndroid) {
                // ok
                print('Error $e ok on Android');
              } else {
                rethrow;
              }
            }
          } else {
            expect(await prefs.getString('testBool'), 'true');
            expect(await prefs.getInt('testBool'), 1, reason: 'int testBool');
            expect(await prefs.getDouble('testBool'), 1.0);
            expect(await prefs.getStringList('testBool'), isNull);

            expect(await prefs.getBool('testInt'), true);
            expect(await prefs.getString('testInt'), '1');
            expect(await prefs.getDouble('testInt'), 1,
                reason: 'double testInt');
            expect(await prefs.getDouble('testInt2'), -7);
            expect(await prefs.getDouble('testInt3'), 0);
            expect(await prefs.getBool('testInt3'), false, reason: 'testInt3');
            expect(await prefs.getString('testInt3'), '0');

            expect(await prefs.getInt('testDouble'), 1,
                reason: 'int testTouble');
            if (kDartIsWebJs) {
              // 1.0 will encoded as an int...
              expect(await prefs.getString('testDouble'), '1');
            } else {
              expect(await prefs.getString('testDouble'), '1.0');
            }
            expect(await prefs.getBool('testDouble'), true);
            expect(await prefs.getInt('testDouble2'), -2,
                reason: 'int testDouble2');
            expect(await prefs.getString('testDouble2'), '-1.5');
            expect(await prefs.getBool('testDouble2'), true);
            expect(await prefs.getBool('testDouble3'), false);

            expect(await prefs.getStringList('testList'), ['test']);
          }

          expect(await prefs.getBool('testBool'), true);
          expect(await prefs.getInt('testInt'), 1, reason: 'int testInt');

          expect(await prefs.getDouble('testDouble'), 1.0, reason: 'double');
          expect(await prefs.getDouble('testDouble2'), -1.5,
              reason: 'double -1.5');

          expect(await prefs.getBool('testList'), isNull);
          expect(await prefs.getInt('testList'), isNull);

          expect(await prefs.getMap('testMap'), {'test': 1});
          expect(await prefs.getList('testRawList'), ['test', 1]);
        }

        await prefs.setBool('testBool', true);

        await prefs.setInt('testInt', 1);
        await prefs.setInt('testInt2', -7);
        await prefs.setInt('testInt3', 0);

        await prefs.setDouble('testDouble', 1.0);
        await prefs.setDouble('testDouble2', -1.5);
        await prefs.setDouble('testDouble3', 0.0);

        await prefs.setStringList('testList', ['test']);

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
        expect(await prefs1.getInt('test'), 1);
        expect(await prefs2.getInt('test'), 2);
        await prefs2.setInt('test', 2);

        await prefs1.close();
        await prefs2.close();
        prefs1 = await factory.openPreferences(name1);
        prefs2 = await factory.openPreferences(name2);
        expect(await prefs1.getInt('test'), 1);
        expect(await prefs2.getInt('test'), 2);
      } finally {
        await prefs1.close();
        await prefs2.close();
      }
    });
  });
}
