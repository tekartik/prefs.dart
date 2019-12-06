@TestOn('browser')
library tekartik_db_browser.test.prefs_impl_test;

import 'dart:html';

import 'package:tekartik_prefs_browser/prefs.dart';
import 'package:test/test.dart';

void main() {
  var factory = prefsFactoryBrowser;

  group('prefs_impl', () {
    test('basic_prefs', () async {
      window.localStorage.remove('basic/test');
      final name = 'basic';
      var prefs = await factory.openPreferences(name);

      try {
        prefs.setInt('test', 1);
        expect(prefs.getInt('test'), 1);

        if (factory.hasStorage) {
          await prefs?.close();

          // check prefs
          expect(window.localStorage['basic/test'], '1');
          window.localStorage['basic/test'] = '2';
          prefs = await factory.openPreferences(name);
          expect(prefs.getInt('test'), 2);
        }
      } finally {
        await prefs?.close();
      }
    });

    test('null_prefs', () async {
      window.localStorage.remove('test');
      String name;
      var prefs = await factory.openPreferences(name);

      try {
        prefs.setInt('test', 1);
        expect(prefs.getInt('test'), 1);

        if (factory.hasStorage) {
          await prefs?.close();

          // check prefs
          expect(window.localStorage['test'], '1');
          window.localStorage['test'] = '2';
          prefs = await factory.openPreferences(name);
          expect(prefs.getInt('test'), 2);
        }
      } finally {
        await prefs?.close();
      }
    });
  });
}
