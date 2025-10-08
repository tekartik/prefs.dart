@TestOn('vm')
library;

import 'package:tekartik_prefs_browser/src/prefs_all.dart';
import 'package:test/test.dart';

void main() {
  test('factories', () {
    expect(checkStorageBrowserIsAvailable(), isFalse);
    expect(prefsFactoryBrowserOrNull, isNull);
    expect(prefsAsyncFactoryBrowserOrNull, isNull);
    expect(prefsAsyncWithCacheFactoryBrowserOrNull, isNull);
  });
}
