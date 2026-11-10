/// Function returning the value associated with [key], null if not found.
typedef KvStoreGetStringFunction = Future<String?> Function(String key);

/// Function setting the value associated with [key], removing it when [value]
/// is null.
typedef KvStoreSetStringFunction =
    Future<void> Function(String key, String? value);

/// Readable string key/value store.
abstract class KvStoreRead {
  /// Returns the value associated with the given [key], null if not found.
  Future<String?> getString(String key);
}

/// Writable string key/value store.
abstract class KvStoreWrite {
  /// Sets the value for the given [key], removes it when [value] is null.
  ///
  /// Removing a missing key is not an error.
  Future<void> setString(String key, String? value);
}

/// Minimal string key/value store: [getString] and [setString], where a null
/// value removes the key. The interface to depend on when all you need is to
/// read and write strings.
///
/// A prefs is not a [KvStore] but gives one (`PrefsLight.kvStore`,
/// `PrefsAsync.kvStore`, `Prefs.kvStore`).
abstract class KvStore implements KvStoreRead, KvStoreWrite {
  /// Creates a store from the 2 methods, handy to wrap an existing storage
  /// without writing a class.
  ///
  /// [getString] returns the value of a key, null when missing. [setString]
  /// writes the value of a key and must remove the key when the value is null.
  factory KvStore({
    required KvStoreGetStringFunction getString,
    required KvStoreSetStringFunction setString,
  }) {
    return _KvStore(getString, setString);
  }
}

/// Store extension
extension KvStoreExt on KvStoreWrite {
  /// Removes the value associated with the given [key], same as
  /// `setString(key, null)`.
  Future<void> remove(String key) => setString(key, null);

  /// Set or remove a string value
  @Deprecated('Use setString, a null value removes the key')
  Future<void> setStringOrNull(String key, String? value) =>
      setString(key, value);
}

class _KvStore implements KvStore {
  final KvStoreGetStringFunction _getString;
  final KvStoreSetStringFunction _setString;

  _KvStore(this._getString, this._setString);

  @override
  Future<String?> getString(String key) => _getString(key);

  @override
  Future<void> setString(String key, String? value) => _setString(key, value);

  @override
  String toString() => 'KvStore()';
}
