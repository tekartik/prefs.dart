import 'package:pedantic/pedantic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tekartik_prefs_flutter/prefs_mock.dart';
import 'package:test/test.dart';

void main() {
  var factory = PrefsFactoryFlutterMock();
  SharedPreferences sharedPreferences;
  group('prefs_impl', () {
    setUpAll(() async {
      sharedPreferences = await SharedPreferences.getInstance();
    });
    test('basic_prefs', () async {
      unawaited(sharedPreferences.remove('basic/test'));
      String name = 'basic';
      var prefs = await factory.openPreferences(name);

      try {
        prefs.setInt('test', 1);
        expect(prefs.getInt('test'), 1);

        if (factory.hasStorage) {
          await prefs?.close();

          // check prefs
          expect(sharedPreferences.getInt('basic/test'), 1);
          unawaited(sharedPreferences.setInt('basic/test', 2));
          prefs = await factory.openPreferences(name);
          expect(prefs.getInt('test'), 2);
        }
      } finally {
        await prefs?.close();
      }
    });

    test('null_prefs', () async {
      unawaited(sharedPreferences.remove('test'));
      String name;
      var prefs = await factory.openPreferences(name);

      try {
        prefs.setInt('test', 1);
        expect(prefs.getInt('test'), 1);

        if (factory.hasStorage) {
          await prefs?.close();

          // check prefs
          expect(sharedPreferences.getInt('test'), 1);
          unawaited(sharedPreferences.setInt('test', 2));
          prefs = await factory.openPreferences(name);
          expect(prefs.getInt('test'), 2);
        }
      } finally {
        await prefs?.close();
      }
    });
  });
}
