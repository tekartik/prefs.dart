import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tekartik_prefs_flutter/prefs_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var factory = PrefsFactoryFlutterMock();
  late SharedPreferences sharedPreferences;
  group('prefs_impl', () {
    setUpAll(() async {
      sharedPreferences = await SharedPreferences.getInstance();
    });
    test('basic_prefs', () async {
      unawaited(sharedPreferences.remove('basic/test'));
      var name = 'basic';
      var prefs = await factory.openPreferences(name);

      try {
        prefs.setInt('test', 1);
        expect(prefs.getInt('test'), 1);

        if (factory.hasStorage) {
          await prefs.close();

          // check prefs
          expect(sharedPreferences.getInt('basic/test'), 1);
          unawaited(sharedPreferences.setInt('basic/test', 2));
          prefs = await factory.openPreferences(name);
          expect(prefs.getInt('test'), 2);
        }
      } finally {
        await prefs.close();
      }
    });
  });
}
