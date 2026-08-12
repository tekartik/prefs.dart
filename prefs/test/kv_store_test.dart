import 'package:tekartik_prefs/prefs_light.dart';
import 'package:test/test.dart';

/// Creates a memory store from the 3 methods.
KvStore newKvStoreMemory(Map<String, String> map) => KvStore(
  getString: (key) async => map[key],
  setString: (key, value) async => map[key] = value,
  remove: (key) async => map.remove(key),
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

    test('setStringOrNull', () async {
      var store = newKvStoreMemory(<String, String>{});

      await store.setStringOrNull('key', 'value');
      expect(await store.getString('key'), 'value');

      await store.setStringOrNull('key', null);
      expect(await store.getString('key'), isNull);
    });

    test('read/write interfaces', () {
      var store = newKvStoreMemory(<String, String>{});
      expect(store, isA<KvStoreRead>());
      expect(store, isA<KvStoreWrite>());
    });

    test('PrefsLight is a KvStore', () async {
      var prefs = PrefsMemory();
      expect(prefs, isA<KvStore>());

      var store = prefs as KvStore;
      await store.setString('key', 'value');
      expect(await store.getString('key'), 'value');

      /// The extension is available on both.
      await prefs.setStringOrNull('key', null);
      expect(await store.getString('key'), isNull);
    });
  });
}
