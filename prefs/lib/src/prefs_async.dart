import 'dart:async';

/// Common Prefs interface.
abstract class PrefsAsync {
  /// The name of the prefs.
  String get name;

  /// The version of the prefs.
  int get version;

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

  /// Saves a list of String [value] to persistent storage in the background.
  Future<void> setStringList(String key, List<String> value);

  /// Removes an entry from persistent storage.
  Future<void> remove(String key);

  /// Clear all prefs.
  Future<void> clear();

  /// no more access possible
  Future<void> close();
}

/// Prefs factory.
abstract class PrefsAsyncFactory {
  /// Delete a prefs.
  Future<void> deletePreferences(String name);

  /// Open a prefs.
  Future<PrefsAsync> openPreferences(String name,
      {int? version, PrefsAsyncOnVersionChangedFunction? onVersionChanged});
}

/// Prefs on version changed function
typedef PrefsAsyncOnVersionChangedFunction = FutureOr<void> Function(
    PrefsAsync pref, int oldVersion, int newVersion);
