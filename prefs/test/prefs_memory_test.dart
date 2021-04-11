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
  });
}
