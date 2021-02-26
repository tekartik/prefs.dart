import 'dart:async';

export 'src/prefs_memory.dart' show prefsFactoryMemory;

/// Common Prefs interface.
abstract class Prefs {
  String get name;

  int get version;

  /// Reads a value from persistent storage, throwing an exception if it's not a
  /// bool.
  bool? getBool(String name);

  String? getString(String name);

  /// Reads a value from persistent storage, throwing an exception if it's not
  /// an int.
  int? getInt(String name);

  /// Reads a value from persistent storage, throwing an exception if it's not a
  /// double.
  double? getDouble(String name);

  /// Reads a value from persistent storage, throwing an exception if it's not a
  /// map.
  Map<String, Object?>? getMap(String name);

  /// Reads a value from persistent storage, throwing an exception if it's not a
  /// list.
  List<Object?>? getList(String name);

  /// Saves a string [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  void setString(String name, String? value);

  /// Saves an integer [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  void setInt(String name, int? value);

  /// Saves a map [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  void setMap(String name, Map? value);

  /// Saves a boolean [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  void setBool(String name, bool? value);

  /// Saves a double [value] to persistent storage in the background.
  ///
  /// Android doesn't support storing doubles, so it will be stored as a float.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  void setDouble(String name, double? value);

  /// Saves a list of object [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  void setList(String name, List<Object?>? value);

  /// Removes an entry from persistent storage.
  void remove(String name);

  /// Returns true if persistent storage the contains the given [key].
  bool containsKey(String key);

  /// List of keys.
  Set<String> get keys;

  /// Clear all prefs.
  void clear();

  /// Force saving the pending changes (set are asynchronously saved) if any
  Future save();

  /// no more access possible
  Future close();
}

abstract class PrefsFactory {
  bool get hasStorage; // true if not memory
  Future deletePreferences(String name);

  Future<Prefs> openPreferences(String name,
      {int? version,
      Future Function(Prefs pref, int oldVersion, int newVersion)?
          onVersionChanged});
}
