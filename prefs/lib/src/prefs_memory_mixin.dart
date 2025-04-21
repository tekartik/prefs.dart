import 'package:cv/cv.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_prefs/mixin/prefs_async_mixin.dart';
import 'package:tekartik_prefs/src/prefs_async.dart';

import 'prefs_async_mixin.dart';

/// Prefs memory mixin
mixin PrefsMemoryMixin
    implements PrefsCommonPrv, PrefsAsyncWriteKeyValuePrv, PrefsAsyncWrite {
  final _map = newModel();

  /// Test map content
  @visibleForTesting
  Model get map => _map;

  /// Get the value from the map
  T? memoryGetValueNoKeyCheck<T>(String key) {
    return checkValueType(_map[key]);
  }

  /// sync getter
  Map<String, Object?> memoryGetAll() => _map.deepClone()
    ..removeWhere((key, value) {
      return isPrivateKey(key);
    });
  @override
  Future<void> setValueNoKeyCheck<T>(String key, T value) async {
    _map[key] = value;
  }

  @override
  Future<void> clear() async {
    _map.removeWhere((key, value) => !isPrivateKey(key));
  }

  @override
  Future<void> clearForDelete() async {
    _map.clear();
  }

  @override
  Future<void> remove(String key) async => _map.remove(key);

  /// sync getter
  bool memoryContainsKey(String key) => _map.containsKey(key);

  /// sync getter
  Set<String> memoryGetKeys() =>
      Set<String>.of(_map.keys)..removeWhere(isPrivateKey);
}
