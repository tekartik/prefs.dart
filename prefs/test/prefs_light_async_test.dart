import 'package:tekartik_prefs/prefs_async.dart';
import 'package:tekartik_prefs/prefs_light.dart';
import 'package:test/test.dart';

void main() {
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
