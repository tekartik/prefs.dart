library;

import 'package:tekartik_prefs_browser/prefs.dart';
import 'package:tekartik_prefs_browser/src/prefs_all.dart';

import 'package:tekartik_prefs_test/prefs_test.dart' as prefs;
import 'package:test/test.dart';

void main() {
  var factory = checkStorageBrowserIsAvailable()
      ? prefsFactoryBrowser
      : prefsFactoryMemory;
  prefs.runPrefsTests(factory);
  test('factories', () {
    if (checkStorageBrowserIsAvailable()) {
      expect(prefsFactoryBrowserOrNull, factory);
      expect(prefsAsyncFactoryBrowserOrNull, prefsAsyncFactoryBrowser);
    }
  });
}
