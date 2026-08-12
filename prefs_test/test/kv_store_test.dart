import 'package:tekartik_prefs/prefs_light.dart';
import 'package:tekartik_prefs_test/kv_store_test_runner.dart' as kv_store;
import 'package:test/test.dart';

void main() {
  group('memory', () {
    kv_store.runKvStoreTests(kv_store.newKvStoreMemory());
  });
  group('prefs_memory', () {
    kv_store.runKvStoreTests(PrefsMemory());
  });
}
