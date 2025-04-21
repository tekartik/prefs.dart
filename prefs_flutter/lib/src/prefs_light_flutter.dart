import 'package:shared_preferences/shared_preferences.dart' as impl;
import 'package:tekartik_prefs/prefs_light.dart';

abstract class PrefsFlutter implements Prefs {}

class _PrefsFlutter implements PrefsFlutter {
  final Future<impl.SharedPreferences> _sharedPreferences =
      impl.SharedPreferences.getInstance();

  @override
  Future<void> setString(String key, String value) async {
    final sharedPreferences = await _sharedPreferences;
    await sharedPreferences.setString(key, value);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    final sharedPreferences = await _sharedPreferences;
    await sharedPreferences.setBool(key, value);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    final sharedPreferences = await _sharedPreferences;
    await sharedPreferences.setDouble(key, value);
  }

  @override
  Future<void> setInt(String key, int value) async {
    final sharedPreferences = await _sharedPreferences;
    await sharedPreferences.setInt(key, value);
  }

  @override
  Future<void> remove(String key) async {
    final sharedPreferences = await _sharedPreferences;
    await sharedPreferences.remove(key);
  }

  @override
  Future<String?> getString(String key) async {
    final sharedPreferences = await _sharedPreferences;
    try {
      return sharedPreferences.getString(key);
    } catch (e) {
      // Handle the error if needed
      return null;
    }
  }

  @override
  Future<bool?> getBool(String key) async {
    final sharedPreferences = await _sharedPreferences;
    try {
      return sharedPreferences.getBool(key);
    } catch (e) {
      // Handle the error if needed
      return null;
    }
  }

  @override
  Future<double?> getDouble(String key) async {
    final sharedPreferences = await _sharedPreferences;
    try {
      return sharedPreferences.getDouble(key);
    } catch (e) {
      // Handle the error if needed
      return null;
    }
  }

  @override
  Future<int?> getInt(String key) async {
    final sharedPreferences = await _sharedPreferences;
    try {
      return sharedPreferences.getInt(key);
    } catch (_) {
      // Handle the error if needed
      return null;
    }
  }
}

final Prefs prefsFlutter = _PrefsFlutter();
