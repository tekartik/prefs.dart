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
