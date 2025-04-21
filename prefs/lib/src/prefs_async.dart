import 'dart:async';
import 'dart:convert';

import 'package:cv/cv_json.dart';

/// Common Prefs interface.
abstract class PrefsAsync implements PrefsAsyncRead, PrefsAsyncWrite {
  /// The name of the prefs.
  String get name;

  /// The version of the prefs.
  int get version;

  /// The options
  PrefsAsyncFactoryOptions get options;

  /// Reads a value from persistent storage, null if it's not a
  /// Avoid
  /// Saves a list of String [value] to persistent storage in the background.
  // @Deprecated('Avoid use string and json instead')
  Future<void> setStringList(String key, List<String> value);

  /// no more access possible
  Future<void> close();
}

/// Common Prefs interface.
abstract class PrefsAsyncWrite {
  /// Saves a string [value] to persistent storage in the background.
  ///
  Future<void> setString(String key, String value);

  /// Saves an integer [value] to persistent storage in the background.
  ///
  Future<void> setInt(String key, int value);

  /// Saves a boolean [value] to persistent storage in the background.
  ///
  Future<void> setBool(String key, bool value);

  /// Saves a double [value] to persistent storage in the background.
  ///
  Future<void> setDouble(String key, double value);

  /// Removes an entry from persistent storage.
  Future<void> remove(String key);

  /// Clear all prefs.
  Future<void> clear();
}

/// Prefs async read interface
abstract class PrefsAsyncRead {
  /// Reads a value from persistent storage, null if it's not a
  /// bool.
  Future<bool?> getBool(String key);

  /// Reads a string value from persistent storage. null if not a string.
  Future<String?> getString(String key);

  /// Reads a value from persistent storage, null if it's not
  /// an int, rounded if double
  Future<int?> getInt(String key);

  /// Reads a value from persistent storage, null if it's not a
  /// double, int converted to double if needed
  Future<double?> getDouble(String key);

  /// Reads a value from persistent storage, null if it's not a
  /// string list.
  Future<List<String>?> getStringList(String key);

  /// Returns true if persistent storage the contains the given [key].
  Future<bool> containsKey(String key);

  /// List of keys.
  Future<Set<String>> getKeys();

  /// Return all keys and values
  Future<Map<String, Object?>> getAll();
}

/// Prefs extension
extension PrefsAsyncExt on PrefsAsync {
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

  /// Set a map value (json encodable)
  Future<void> setMap(String key, Map value) =>
      setString(key, jsonEncode(value));

  /// Set or remove a map value (json encodable)
  Future<void> setMapOrNull(String key, Map? value) =>
      value == null ? remove(key) : setMap(key, value);

  /// Set or remove a map value
  Future<Model?> getMap(String key) async =>
      cvAnyToJsonObjectOrNull(await getString(key));

  /// Set or remove a list value (json encodable)
  Future<void> setList(String key, List value) =>
      setString(key, jsonEncode(value));

  /// Set or remove a list value (json encodable)
  Future<void> setListOrNull(String key, List? value) =>
      value == null ? remove(key) : setList(key, value);

  /// Set or remove a list value
  Future<List<Object?>?> getList(String key) async =>
      cvAnyToJsonArrayOrNull(await getString(key));
}

/// Prefs factory.
abstract class PrefsAsyncFactory {
  /// Global options
  PrefsAsyncFactoryOptions get options;

  /// Delete a prefs.
  Future<void> deletePreferences(String name);

  /// Open a prefs.
  Future<PrefsAsync> openPreferences(String name,
      {int? version, PrefsAsyncOnVersionChangedFunction? onVersionChanged});

  /// Initialize the factory
  void init({PrefsAsyncFactoryOptions? options});
}

/// Async factory options
abstract class PrefsAsyncFactoryOptions {
  /// No implied conversion between types, matches shared_preferences flutter but not preferred by default
  /// and disable extension to generic list and maps
  bool get strictType;

  /// Default constructor
  factory PrefsAsyncFactoryOptions({bool? strictType}) =>
      _PrefsAsyncFactoryOptions(strictType: strictType);
}

class _PrefsAsyncFactoryOptions implements PrefsAsyncFactoryOptions {
  @override
  final bool strictType;

  _PrefsAsyncFactoryOptions({bool? strictType})
      : strictType = strictType ?? false;

  Model toDebugMap() => asModel({
        if (strictType) 'strictType': strictType,
      });

  @override
  String toString() => 'PrefsOptions(${toDebugMap()})';
}

/// Prefs on version changed function
typedef PrefsAsyncOnVersionChangedFunction = FutureOr<void> Function(
    PrefsAsync pref, int oldVersion, int newVersion);
