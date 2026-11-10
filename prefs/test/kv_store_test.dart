import 'package:tekartik_prefs/prefs.dart';
import 'package:tekartik_prefs/prefs_async.dart';
import 'package:tekartik_prefs/prefs_light.dart';
import 'package:test/test.dart';

/// Creates a memory store from the 2 methods.
KvStore newKvStoreMemory(Map<String, String> map) => KvStore(
  getString: (key) async => map[key],
  setString: (key, value) async {
    if (value == null) {
      map.remove(key);
    } else {
      map[key] = value;
    }
  },
);

void main() {
  group('kv_store', () {
    test('function based store', () async {
      var map = <String, String>{};
      var store = newKvStoreMemory(map);

      expect(await store.getString('key'), isNull);

      await store.setString('key', 'value');
      expect(await store.getString('key'), 'value');
      expect(map, {'key': 'value'});

      await store.remove('key');
      expect(await store.getString('key'), isNull);
      expect(map, isEmpty);
    });

    test('set null removes', () async {
      var map = <String, String>{};
      var store = newKvStoreMemory(map);

      await store.setString('key', 'value');
      expect(await store.getString('key'), 'value');

      await store.setString('key', null);
      expect(await store.getString('key'), isNull);
      expect(map, isEmpty);
    });

    test('setStringOrNull', () async {
      var store = newKvStoreMemory(<String, String>{});

      // ignore: deprecated_member_use_from_same_package
      await store.setStringOrNull('key', 'value');
      expect(await store.getString('key'), 'value');

      // ignore: deprecated_member_use_from_same_package
      await store.setStringOrNull('key', null);
      expect(await store.getString('key'), isNull);
    });

    test('read/write interfaces', () async {
      var store = newKvStoreMemory(<String, String>{});
      expect(store, isA<KvStoreRead>());
      expect(store, isA<KvStoreWrite>());

      // remove is available on the write side alone.
      KvStoreWrite write = store;
      await write.setString('key', 'value');
      await write.remove('key');
      expect(await store.getString('key'), isNull);
    });

    test('PrefsLight as a KvStore', () async {
      var prefs = PrefsMemory();
      expect(prefs, isNot(isA<KvStore>()));

      var store = prefs.kvStore;
      await store.setString('key', 'value');
      expect(await store.getString('key'), 'value');
      expect(await prefs.getString('key'), 'value');

      /// Written by the prefs, read by the store.
      await prefs.setString('other', 'text');
      expect(await store.getString('other'), 'text');

      await store.setString('key', null);
      expect(await prefs.getString('key'), isNull);
      await store.remove('other');
      expect(await prefs.getString('other'), isNull);
    });

    test('PrefsAsync as a KvStore', () async {
      var prefs = await newPrefsAsyncFactoryMemory().openPreferences('test');
      var store = prefs.kvStore;

      await store.setString('key', 'value');
      expect(await store.getString('key'), 'value');
      expect(await prefs.getString('key'), 'value');

      await store.setString('key', null);
      expect(await prefs.containsKey('key'), isFalse);
      await prefs.close();
    });

    test('Prefs as a KvStore', () async {
      var prefs = await newPrefsFactoryMemory().openPreferences('test');
      var store = prefs.kvStore;

      await store.setString('key', 'value');
      expect(await store.getString('key'), 'value');
      expect(prefs.getString('key'), 'value');

      await store.setString('key', null);
      expect(prefs.containsKey('key'), isFalse);
      await prefs.close();
    });
  });
}
