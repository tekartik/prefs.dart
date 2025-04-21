import 'package:tekartik_prefs/prefs_light.dart';
import 'package:tekartik_prefs/src/prefs_async.dart';
import 'package:tekartik_prefs/src/prefs_utils.dart';

/// Prefs light based on PrefsAsync
abstract class PrefsLightAsync implements PrefsLight {
  /// Constructs a [PrefsLightAsync] instance with the given [delegate].
  factory PrefsLightAsync({required PrefsAsync delegate}) {
    return _PrefsLightAsync(delegate: delegate);
  }

  /// Constructs a [PrefsLightAsync] instance with the given [delegate].
  factory PrefsLightAsync.lazy({
    required Future<PrefsAsync> Function() initDelegate,
  }) {
    return _PrefsLightAsyncLazy(initDelegate: initDelegate);
  }
}

class _PrefsLightAsync implements PrefsLightAsync {
  final PrefsAsync delegate;

  _PrefsLightAsync({required this.delegate});

  Future<T?> _wrap<T>(Future<T?> Function() action) async {
    try {
      var result = await action();
      return checkValueType<T>(result);
    } catch (e) {
      // ignore: avoid_print
      // print('Error: $e');
      return null;
    }
  }

  @override
  Future<bool?> getBool(String key) => _wrap(() => delegate.getBool(key));

  @override
  Future<double?> getDouble(String key) => _wrap(() => delegate.getDouble(key));

  @override
  Future<int?> getInt(String key) => _wrap(() => delegate.getInt(key));

  @override
  Future<String?> getString(String key) => _wrap(() => delegate.getString(key));

  @override
  Future<void> remove(String key) => _wrap(() => delegate.remove(key));

  @override
  Future<void> setBool(String key, bool value) => delegate.setBool(key, value);

  @override
  Future<void> setDouble(String key, double value) =>
      delegate.setDouble(key, value);

  @override
  Future<void> setInt(String key, int value) => delegate.setInt(key, value);

  @override
  Future<void> setString(String key, String value) =>
      delegate.setString(key, value);
}

class _PrefsLightAsyncLazy implements PrefsLightAsync {
  final Future<PrefsAsync> Function() initDelegate;
  late final Future<PrefsAsync> delegate = initDelegate();

  _PrefsLightAsyncLazy({required this.initDelegate});

  Future<T?> _wrap<T>(Future<T?> Function(PrefsAsync delegate) action) async {
    var delegate = await this.delegate;
    try {
      var result = await action(delegate);
      return checkValueType<T>(result);
    } catch (e) {
      // ignore: avoid_print
      // print('Error: $e');
      return null;
    }
  }

  @override
  Future<bool?> getBool(String key) =>
      _wrap((delegate) => delegate.getBool(key));

  @override
  Future<double?> getDouble(String key) =>
      _wrap((delegate) => delegate.getDouble(key));

  @override
  Future<int?> getInt(String key) => _wrap((delegate) => delegate.getInt(key));

  @override
  Future<String?> getString(String key) =>
      _wrap((delegate) => delegate.getString(key));

  @override
  Future<void> remove(String key) => _wrap((delegate) => delegate.remove(key));

  @override
  Future<void> setBool(String key, bool value) =>
      _wrap((delegate) => delegate.setBool(key, value));

  @override
  Future<void> setDouble(String key, double value) =>
      _wrap((delegate) => delegate.setDouble(key, value));

  @override
  Future<void> setInt(String key, int value) =>
      _wrap((delegate) => delegate.setInt(key, value));

  @override
  Future<void> setString(String key, String value) =>
      _wrap((delegate) => delegate.setString(key, value));
}
