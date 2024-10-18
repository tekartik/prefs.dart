import 'dart:async';

import 'package:tekartik_prefs/prefs.dart';
import 'package:test/test.dart';
export 'package:tekartik_prefs/prefs.dart';

void main() {
  runPrefsTests(prefsFactoryMemory);
}

void runPrefsTests(PrefsFactory factory) {
  Future<Prefs> deleteAndOpen(String name) async {
    await factory.deletePreferences(name);
    return await factory.openPreferences(name);
  }

  group('prefs_async', () {
    test('basic', () async {
      var name = 'test.prefs';

      var prefs = await deleteAndOpen(name);
      try {
        expect(prefs.getInt('test'), isNull);
        prefs.setInt('test', 1);
        expect(prefs.getInt('test'), 1);

        expect(prefs.keys, ['test']);
      } finally {
        await prefs.close();
      }
    });

    test('delete', () async {
      var name = 'delete.prefs';

      var prefs = await deleteAndOpen(name);
      prefs.setInt('test', 1);
      await prefs.close();

      try {
        prefs = await deleteAndOpen(name);
        expect(prefs.getInt('test'), isNull);
      } finally {
        await prefs.close();
      }
    });
    test('change prefs during version change', () async {
      var name = 'version.prefs';
      await factory.deletePreferences(name);

      Future onVersionChanged1(
          Prefs prefs, int oldVersion, int newVersion) async {
        prefs.setInt('value', 1);
      }

      var prefs = await factory.openPreferences(name,
          version: 1, onVersionChanged: onVersionChanged1);
      expect(prefs.version, 1);
      expect(prefs.getInt('value'), 1);
      await prefs.close();

      Future onVersionChanged2(
          Prefs prefs, int oldVersion, int newVersion) async {
        expect(prefs.getInt('value'), 1);
        prefs.setInt('value', 2);
      }

      prefs = await factory.openPreferences(name,
          version: 2, onVersionChanged: onVersionChanged2);
      expect(prefs.version, 2);
      expect(prefs.getInt('value'), 2);
      await prefs.close();

      // clear during version change
      Future onVersionChanged3(
          Prefs prefs, int oldVersion, int newVersion) async {
        prefs.clear();
        prefs.setInt('value2', 3);
      }

      prefs = await factory.openPreferences(name,
          version: 3, onVersionChanged: onVersionChanged3);
      expect(prefs.version, 3);
      expect(prefs.getInt('value'), isNull);
      expect(prefs.getInt('value2'), 3);
      await prefs.close();
    });
    test('version', () async {
      var name = 'version.prefs';
      await factory.deletePreferences(name);
      var onVersionChangedCalled = false;
      Future onVersionChanged1(
          Prefs prefs, int oldVersion, int newVersion) async {
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
          Prefs prefs, int oldVersion, int newVersion) async {
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
      try {
        if (factory.hasStorage) {
          prefs.setInt('test', 1);
          await prefs.close();
          prefs = await factory.openPreferences(name);
          expect(prefs.getInt('test'), 1);
        }
      } finally {
        await prefs.close();
      }
    });

    test('keys', () async {
      var name = 'persistent.prefs.db';
      var prefs = await deleteAndOpen(name);
      try {
        prefs.setInt('test', 1);
        expect(prefs.keys, ['test']);
        expect(prefs.containsKey('test'), isTrue);
        prefs.setInt('test', null);
        expect(prefs.keys, isEmpty);
        expect(prefs.containsKey('test'), isFalse);
        prefs.setInt('test', 1);
        expect(prefs.keys, ['test']);
        if (factory.hasStorage) {
          await prefs.close();
          prefs = await factory.openPreferences(name);
          expect(prefs.keys, ['test']);
          expect(prefs.containsKey('test'), isTrue);

          prefs.remove('test');

          await prefs.close();
          prefs = await factory.openPreferences(name);
          expect(prefs.keys, isEmpty);
          expect(prefs.containsKey('test'), isFalse);
        }
      } finally {
        await prefs.close();
      }
    });

    test('types', () async {
      var name = 'type.prefs';
      var prefs = await deleteAndOpen(name);
      try {
        prefs.setBool('testBool', true);
        expect(prefs.getBool('testBool'), true);
        prefs.setInt('testInt', -2);
        expect(prefs.getInt('testInt'), -2);
        prefs.setDouble('testDouble', 1.0);
        expect(prefs.getDouble('testDouble'), 1.0);
        prefs.setString('testString', 'text');
        expect(prefs.getString('testString'), 'text');
        prefs.setMap('testMap', {'sub': 1});
        expect(prefs.getMap('testMap'), {'sub': 1});
        prefs.setList('testList', [1, 2]);
        expect(prefs.getList('testList'), [1, 2]);
        const map = {
          'int': 1,
          'double': 2.0,
          'bool': true,
          'String': 'String',
          'list': [
            1,
            [
              1,
              {
                'map': {'int': 3}
              }
            ]
          ],
          'map': {
            'sub': {
              'list': [5, 6]
            },
            'list': [1]
          }
        };
        prefs.setMap('testComplex', map);
        expect(prefs.getMap('testComplex'), map);

        if (factory.hasStorage) {
          await prefs.close();
          prefs = await factory.openPreferences(name);
          expect(prefs.getBool('testBool'), true);
          expect(prefs.getInt('testInt'), -2);
          expect(prefs.getDouble('testDouble'), 1.0);
          expect(prefs.getString('testString'), 'text');
          expect(prefs.getMap('testMap'), {'sub': 1});
          expect(prefs.getList('testList'), [1, 2]);
          expect(prefs.getMap('testComplex'), map);

          // change and reload
          prefs.setInt('testInt', -1);
          expect(prefs.getInt('testInt'), -1);

          await prefs.close();
          prefs = await factory.openPreferences(name);
          expect(prefs.getBool('testBool'), true);
          expect(prefs.getInt('testInt'), -1);
          expect(prefs.getMap('testComplex'), map);
        }
      } finally {
        await prefs.close();
      }
    });

    test('type_conversion', () async {
      var name = 'type_conversion.prefs';
      var prefs = await deleteAndOpen(name);
      try {
        void check() {
          expect(prefs.getBool('testBool'), true);
          expect(prefs.getString('testBool'), 'true');
          expect(prefs.getInt('testBool'), 1, reason: 'int testBool');
          expect(prefs.getDouble('testBool'), isNull);
          expect(prefs.getMap('testBool'), isNull);
          expect(prefs.getList('testBool'), isNull);

          expect(prefs.getBool('testInt'), true);
          expect(prefs.getString('testInt'), '1');
          expect(prefs.getDouble('testInt'), 1.0);
          expect(prefs.getBool('testInt2'), true);
          expect(prefs.getString('testInt2'), '-7');
          expect(prefs.getDouble('testInt2'), -7.0);
          expect(prefs.getBool('testInt3'), false, reason: 'testInt3');
          expect(prefs.getString('testInt3'), '0');
          expect(prefs.getDouble('testInt3'), 0.0);

          expect(prefs.getBool('testDouble'), true);
          var doubleStringValue = prefs.getString('testDouble');
          expect(doubleStringValue == '1.0' || doubleStringValue == '1', isTrue,
              reason: '$doubleStringValue');
          expect(prefs.getInt('testDouble'), 1, reason: 'int testTouble');

          var double2StringValue = prefs.getString('testDouble2');
          expect(double2StringValue == '-1.5', isTrue,
              reason: '$double2StringValue');
          expect(prefs.getBool('testDouble2'), true);
          expect(prefs.getInt('testDouble2'), -1);

          expect(prefs.getBool('testMap'), isNull);
          expect(prefs.getInt('testMap'), isNull);
          expect(prefs.getString('testMap'), '{"test":1}');

          expect(prefs.getBool('testList'), isNull);
          expect(prefs.getInt('testList'), isNull);
          expect(prefs.getString('testList'), '["test"]');
        }

        prefs.setBool('testBool', true);

        prefs.setInt('testInt', 1);
        prefs.setInt('testInt2', -7);
        prefs.setInt('testInt3', 0);

        prefs.setDouble('testDouble', 1.0);
        prefs.setDouble('testDouble2', -1.5);

        prefs.setMap('testMap', {'test': 1});
        prefs.setList('testList', ['test']);
        check();

        if (factory.hasStorage) {
          await prefs.close();
          prefs = await factory.openPreferences(name);
          check();
        }
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
        prefs1.setInt('test', 1);
        prefs2.setInt('test', 2);
        expect(prefs1.getInt('test'), 1);
        expect(prefs2.getInt('test'), 2);
        prefs2.setInt('test', 2);

        if (factory.hasStorage) {
          await prefs1.close();
          await prefs2.close();
          prefs1 = await factory.openPreferences(name1);
          prefs2 = await factory.openPreferences(name2);
          expect(prefs1.getInt('test'), 1);
          expect(prefs2.getInt('test'), 2);
        }
      } finally {
        await prefs1.close();
        await prefs2.close();
      }
    });
  });
}
