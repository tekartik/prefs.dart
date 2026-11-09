import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tekartik_prefs_flutter/prefs_async.dart';
import 'package:tekartik_prefs_flutter/prefs_light.dart';
import 'package:tekartik_prefs_test/kv_store_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_async_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_async_with_cache_test_runner.dart';
import 'package:tekartik_prefs_test/prefs_light_test_runner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // In memory shared_preferences: SharedPreferencesAsync and
  // SharedPreferencesWithCache (async factories), SharedPreferences (light).
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  group('async', () {
    runPrefsAsyncTests(prefsAsyncFactoryFlutter);
  });
  group('async_with_cache', () {
    runPrefsAsyncWithCacheTests(prefsAsyncWithCacheFactoryFlutter);
  });
  group('light', () {
    runPrefsLightTests(prefsFlutter);
    group('kv_store', () {
      runKvStoreTests(prefsFlutter);
    });
  });
}
