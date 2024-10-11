import 'package:tekartik_prefs/prefs.dart';
import 'package:test/test.dart';

void main() {
  group('memory', () {
    test('prefsFactoryMemory', () async {
      var prefs = await prefsFactoryMemory.openPreferences('test1');
      prefs.setBool('test', true);
      await prefs.close();
      prefs = await prefsFactoryMemory.openPreferences('test1');
      expect(prefs.getBool('test'), true);
    });
    test('newPrefsFactoryMemory()', () async {
      var prefs = await newPrefsFactoryMemory().openPreferences('test1');
      prefs.setBool('test', true);
      await prefs.close();
      prefs = await newPrefsFactoryMemory().openPreferences('test1');
      expect(prefs.getBool('test'), isNull);
    });
    test('onVersionChanged', () async {
      var prefs = await newPrefsFactoryMemory().openPreferences('test1',
          version: 1, onVersionChanged: (prefs, oldVersion, newVersion) async {
        expect(oldVersion, 0);
        expect(newVersion, 1);
      });
      await prefs.close();
    });
  });
}
