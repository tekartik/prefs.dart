library;

import 'package:idb_shim/sdb/sdb.dart';
import 'package:tekartik_prefs_sdb/prefs.dart';
import 'package:tekartik_prefs_sdb/prefs_async.dart';
import 'package:tekartik_prefs_sdb/prefs_light.dart';
import 'package:tekartik_prefs_test/kv_store_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_async_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_async_with_cache_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_light_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_test_runner.dart' as prefs;
import 'package:test/test.dart';

void main() {
  runPrefsAsyncTests(getPrefsAsyncFactorySdb(newSdbFactoryMemory()));
  runPrefsAsyncWithCacheTests(
    getPrefsAsyncWithCacheFactorySdb(newSdbFactoryMemory()),
  );
  prefs.runPrefsTests(getPrefsFactorySdb(newSdbFactoryMemory()));
  runPrefsLightTests(getPrefsLightSdb(newSdbFactoryMemory()));
  group('kv_store', () {
    runKvStoreTests(getPrefsLightSdb(newSdbFactoryMemory()));
  });
}
