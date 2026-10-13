import 'package:tekartik_prefs/prefs_async.dart';
import 'package:tekartik_prefs/prefs_light.dart';
import 'package:test/test.dart';

void main() {
  test('errors', () async {
    // Same policy as lazy: reads return null and writes are ignored.
    for (var prefs in [
      PrefsLightAsync(
        delegate: await newPrefsAsyncFactoryMemory().openPreferences('light'),
      ),
      PrefsLightAsync.lazy(
        initDelegate: () =>
            newPrefsAsyncFactoryMemory().openPreferences('light'),
      ),
    ]) {
      // Invalid key.
      await prefs.setString('_key', 'value');
      await prefs.setInt('_key', 1);
      await prefs.setBool('_key', true);
      await prefs.setDouble('_key', 1.5);
      expect(await prefs.getString('_key'), isNull);
      await prefs.remove('_key');
    }
  });
  group('lazy', () {
    test('delegate', () async {
      var prefs = PrefsLightAsync.lazy(
        initDelegate: () =>
            newPrefsAsyncFactoryMemory().openPreferences('light'),
      );
      await prefs.setInt('int', 1);
      expect(await prefs.getInt('int'), 1);
      await prefs.remove('int');
      expect(await prefs.getInt('int'), isNull);
    });
    test('open failure', () async {
      var prefs = PrefsLightAsync.lazy(
        initDelegate: () async => throw StateError('no storage'),
      );
      expect(await prefs.getString('key'), isNull);
      expect(await prefs.getInt('key'), isNull);
      await prefs.setString('key', 'value');
      await prefs.remove('key');
    });
  });
}
