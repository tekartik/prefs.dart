@TestOn('browser')
library;

import 'package:tekartik_prefs_browser/prefs.dart';
import 'package:test/test.dart';
import 'package:web/web.dart';

void main() {
  var factory = prefsFactoryBrowser;

  group('prefs_impl', () {
    test('basic_prefs', () async {
      window.localStorage.removeItem('basic/test');
      final name = 'basic';
      var prefs = await factory.openPreferences(name);

      try {
        prefs.setInt('test', 1);
        expect(prefs.getInt('test'), 1);

        if (factory.hasStorage) {
          await prefs.close();

          // check prefs
          expect(window.localStorage['basic/test'], '1');
          window.localStorage['basic/test'] = '2';
          prefs = await factory.openPreferences(name);
          expect(prefs.getInt('test'), 2);
        }
      } finally {
        await prefs.close();
      }
    });
  });
}
