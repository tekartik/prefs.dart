import 'dart:convert';

import 'package:cv/cv_json.dart';

/// Prefs interface (light)
abstract class PrefsLight {
  /// Returns the value associated with the given [key].
  Future<String?> getString(String key);

  /// Returns the value associated with the given [key].
  Future<bool?> getBool(String key);

  /// Returns the value associated with the given [key].
  Future<int?> getInt(String key);

  /// Returns the value associated with the given [key].
  Future<double?> getDouble(String key);

  /// Sets the value for the given [key].
  Future<void> setString(String key, String value);

  /// Sets the value for the given [key].
  Future<void> setBool(String key, bool value);

  /// Sets the value for the given [key].
  Future<void> setDouble(String key, double value);

  /// Sets the value for the given [key].
  Future<void> setInt(String key, int value);

  /// Removes the value associated with the given [key].
  Future<void> remove(String key);
}

/// Prefs extension
extension PrefsLightExt on PrefsLight {
  /// Set or remove an int value
  Future<void> setIntOrNull(String key, int? value) =>
      value == null ? remove(key) : setInt(key, value);

  /// Set or remove an a bool value
  Future<void> setBoolOrNull(String key, bool? value) =>
      value == null ? remove(key) : setBool(key, value);

  /// Set or remove a string value
  Future<void> setStringOrNull(String key, String? value) =>
      value == null ? remove(key) : setString(key, value);

  /// Set or remove a double value
  Future<void> setDoubleOrNull(String key, double? value) =>
      value == null ? remove(key) : setDouble(key, value);

  /// Get a map value
  Future<Model?> getMap(String key) async =>
      cvAnyToJsonObjectOrNull(await getString(key));

  /// Set a map value (json encodable)
  Future<void> setMap(String key, Map value) =>
      setString(key, jsonEncode(value));

  /// Set or remove a map value (json encodable)
  Future<void> setMapOrNull(String key, Map? value) =>
      value == null ? remove(key) : setMap(key, value);

  /// Get a list value
  Future<List?> getList(String key) async =>
      cvAnyToJsonArrayOrNull(await getString(key));

  /// Set a list value (json encodable)
  Future<void> setList(String key, List value) =>
      setString(key, jsonEncode(value));

  /// Set or remove a list value (json encodable)
  Future<void> setListOrNull(String key, List? value) =>
      value == null ? remove(key) : setList(key, value);
}
