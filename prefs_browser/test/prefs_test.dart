library;

import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_prefs_browser/prefs.dart';
import 'package:tekartik_prefs_browser/prefs_light.dart';
import 'package:tekartik_prefs_browser/src/prefs_all.dart';

import 'package:tekartik_prefs_test/prefs_light_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_test_runner.dart' as prefs;
import 'package:test/test.dart';

void main() {
  var factory = checkStorageBrowserIsAvailable()
      ? prefsFactoryBrowser
      : prefsFactoryMemory;
  prefs.runPrefsTests(factory);
  group('light', () {
    if (checkStorageBrowserIsAvailable()) {
      runPrefsLightTests(
        getPrefsLightBrowserOrNull(name: 'tekartik_prefs_test_light') ??
            PrefsMemory(),
      );
    }
  });
  test('factories', () {
    if (checkStorageBrowserIsAvailable()) {
      expect(prefsFactoryBrowserOrNull, factory);
      expect(prefsAsyncFactoryBrowserOrNull, prefsAsyncFactoryBrowser);
    }
    if (!kDartIsWeb) {
      expect(getPrefsLightBrowserOrNull(), isNull);
      expect(() => getPrefsLightBrowser(), throwsUnimplementedError);
    }
  });
}
