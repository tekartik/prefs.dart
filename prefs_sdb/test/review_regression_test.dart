import 'package:idb_shim/sdb/sdb.dart';
import 'package:tekartik_prefs_sdb/prefs.dart';
import 'package:test/test.dart';

void main() {
  group('review regression', () {
    test('two factories, same prefs name, independent prefs', () async {
      // Two prefs factories on different sdb factories, same prefs name.
      var factory1 = getPrefsFactorySdb(newSdbFactoryMemory());
      var factory2 = getPrefsFactorySdb(newSdbFactoryMemory());
      var prefs1 = await factory1.openPreferences('same.prefs');
      var prefs2 = await factory2.openPreferences('same.prefs');
      try {
        expect(prefs2, isNot(same(prefs1)));
        prefs1.setInt('value', 1);
        expect(prefs2.getInt('value'), isNull);
      } finally {
        await prefs1.close();
        await prefs2.close();
      }
      // Each factory reads its own database.
      prefs2 = await factory2.openPreferences('same.prefs');
      expect(prefs2.getInt('value'), isNull);
      await prefs2.close();
    }, timeout: const Timeout(Duration(seconds: 10)));
  });
}
