import 'package:tekartik_prefs/kv_store.dart';
import 'package:test/test.dart';

export 'package:tekartik_prefs/kv_store.dart';

void main() {
  runKvStoreTests(newKvStoreMemory());
}

var _keyPrefix = 'kv_store_test';

/// Test key, prefixed to avoid clashing with other tests on a shared store.
String testKey(String key) {
  return '$_keyPrefix.$key';
}

/// In memory store built from the 2 methods, used as the reference
/// implementation.
KvStore newKvStoreMemory() {
  var map = <String, String>{};
  return KvStore(
    getString: (key) async => map[key],
    setString: (key, value) async {
      if (value == null) {
        map.remove(key);
      } else {
        map[key] = value;
      }
    },
  );
}

/// Run the [KvStore] tests on a given [store].
void runKvStoreTests(KvStore store) {
  var keyString = testKey('string');
  var keyOther = testKey('other');

  tearDown(() async {
    await store.remove(keyString);
    await store.remove(keyOther);
  });

  test('read/write interfaces', () {
    expect(store, isA<KvStoreRead>());
    expect(store, isA<KvStoreWrite>());
  });

  test('missing', () async {
    expect(await store.getString(testKey('missing')), isNull);
  });

  test('string', () async {
    await store.setString(keyString, 'test');
    expect(await store.getString(keyString), 'test');

    await store.remove(keyString);
    expect(await store.getString(keyString), isNull);
  });

  test('overwrite', () async {
    await store.setString(keyString, 'test1');
    await store.setString(keyString, 'test2');
    expect(await store.getString(keyString), 'test2');
  });

  test('remove missing', () async {
    await store.remove(testKey('missing'));
    // Removing twice should not throw either.
    await store.setString(keyString, 'test');
    await store.remove(keyString);
    await store.remove(keyString);
    expect(await store.getString(keyString), isNull);
  });

  test('keys are independent', () async {
    await store.setString(keyString, 'test1');
    await store.setString(keyOther, 'test2');
    expect(await store.getString(keyString), 'test1');
    expect(await store.getString(keyOther), 'test2');

    await store.remove(keyString);
    expect(await store.getString(keyString), isNull);
    expect(await store.getString(keyOther), 'test2');
  });

  test('empty string', () async {
    await store.setString(keyString, '');
    expect(await store.getString(keyString), '');
  });

  test('multi line string', () async {
    var value = 'line1\nline2é';
    await store.setString(keyString, value);
    expect(await store.getString(keyString), value);
  });

  test('set null removes', () async {
    await store.setString(keyString, 'test');
    await store.setString(keyOther, 'other');
    expect(await store.getString(keyString), 'test');

    await store.setString(keyString, null);
    expect(await store.getString(keyString), isNull);
    // The other keys are kept.
    expect(await store.getString(keyOther), 'other');

    // Setting null on a missing key should not throw.
    await store.setString(keyString, null);
    await store.setString(testKey('missing'), null);
    expect(await store.getString(keyString), isNull);

    // A removed key can be set again.
    await store.setString(keyString, 'again');
    expect(await store.getString(keyString), 'again');
  });
}
