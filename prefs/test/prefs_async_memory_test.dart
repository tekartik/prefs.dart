import 'package:tekartik_prefs/prefs_async.dart';
import 'package:tekartik_prefs/src/prefs_async_memory.dart'
    show PrefsAsyncFactoryMemory, PrefsAsyncMemory;
import 'package:test/test.dart';

void main() {
  group('memory', () {
    test('prefsFactoryMemory', () async {
      var prefs = await prefsAsyncFactoryMemory.openPreferences('test1');
      await prefs.setBool('test', true);

      await prefs.close();
      prefs = await prefsAsyncFactoryMemory.openPreferences('test1');
      expect(await prefs.getBool('test'), true);
    });
    test('newPrefsFactoryMemory()', () async {
      var prefsFactory = newPrefsAsyncFactoryMemory();
      var prefs = await prefsFactory.openPreferences('test1');
      expect(prefs.name, 'test1');
      expect(prefs.version, 0);
      await prefs.setBool('test', true);
      var prefsMemory = prefs as PrefsAsyncMemory;
      expect(prefsMemory.map, {
        '__tekartik_prefs_signature__': 'tekartik_prefs',
        '__tekartik_prefs_version__': 0,
        'test': true,
      });
      var prefsFactoryMemory = prefsFactory as PrefsAsyncFactoryMemory;
      expect(prefsFactoryMemory.allPrefs, {'test1': prefs});
      expect(prefsFactoryMemory.persistentsPrefs, {'test1': prefs});
      await prefs.close();
      expect(prefsFactoryMemory.allPrefs, isEmpty);
      expect(prefsFactoryMemory.persistentsPrefs, {'test1': prefs});
      prefs = await prefsFactory.openPreferences('test1');
      expect(await prefs.getBool('test'), true);
      prefs = await newPrefsAsyncFactoryMemory().openPreferences('test1');
      expect(await prefs.getBool('test'), isNull);
    });
    test('onVersionChanged', () async {
      var prefs = await newPrefsAsyncFactoryMemory().openPreferences(
        'test1',
        version: 1,
        onVersionChanged: (prefs, oldVersion, newVersion) async {
          expect(oldVersion, 0);
          expect(newVersion, 1);
        },
      );
      expect(prefs.name, 'test1');
      expect(prefs.version, 1);
      await prefs.close();
    });
  });
}
