import 'dart:async';
import 'dart:io';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_prefs/prefs_async.dart';
import 'package:test/test.dart';
export 'package:tekartik_prefs/prefs_async.dart';

void main() {
  runPrefsAsyncTests(prefsAsyncFactoryMemory);
}

void runPrefsAsyncTests(PrefsAsyncFactory factory) {
  Future<PrefsAsync> deleteAndOpen(String name) async {
    await factory.deletePreferences(name);
    return await factory.openPreferences(name);
  }

  group('prefs', () {
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
          expect(await prefs.getString('testBool'), isNull);
          expect(await prefs.getInt('testBool'), isNull,
              reason: 'int testBool');
          expect(await prefs.getDouble('testBool'), isNull);
          expect(await prefs.getStringList('testBool'), isNull);

          expect(await prefs.getBool('testInt'), isNull);
          expect(await prefs.getInt('testInt'), 1, reason: 'int testInt');
          expect(await prefs.getString('testInt'), isNull);

          expect(await prefs.getDouble('testInt'), 1, reason: 'double testInt');
          expect(await prefs.getDouble('testInt2'), -7);
          expect(await prefs.getDouble('testInt3'), 0);

          expect(await prefs.getInt('testDouble'), 1, reason: 'int testTouble');

          expect(await prefs.getInt('testDouble2'), -2,
              reason: 'int testDouble2');
          expect(await prefs.getBool('testInt3'), isNull, reason: 'testInt3');
          expect(await prefs.getString('testInt3'), isNull);

          expect(await prefs.getDouble('testDouble'), 1.0, reason: 'double');
          expect(await prefs.getBool('testDouble'), isNull);
          expect(await prefs.getString('testDouble'), isNull);

          expect(await prefs.getBool('testDouble2'), isNull);

          expect(await prefs.getBool('testList'), isNull);
          expect(await prefs.getInt('testList'), isNull);
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
          expect(await prefs.getStringList('testList'), ['test']);
        }

        await prefs.setBool('testBool', true);

        await prefs.setInt('testInt', 1);
        await prefs.setInt('testInt2', -7);
        await prefs.setInt('testInt3', 0);

        await prefs.setDouble('testDouble', 1.0);
        await prefs.setDouble('testDouble2', -1.5);

        await prefs.setStringList('testList', ['test']);
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
