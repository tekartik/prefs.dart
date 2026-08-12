/// Function returning the value associated with [key], null if not found.
typedef KvStoreGetStringFunction = Future<String?> Function(String key);

/// Function setting the value associated with [key].
typedef KvStoreSetStringFunction =
    Future<void> Function(String key, String value);

/// Function removing the value associated with [key].
typedef KvStoreRemoveFunction = Future<void> Function(String key);

/// Readable string key/value store.
abstract class KvStoreRead {
  /// Returns the value associated with the given [key], null if not found.
  Future<String?> getString(String key);
}

/// Writable string key/value store.
abstract class KvStoreWrite {
  /// Sets the value for the given [key].
  Future<void> setString(String key, String value);

  /// Removes the value associated with the given [key].
  Future<void> remove(String key);
}

/// Minimal string key/value store, the common base of any prefs
/// implementation (`PrefsLight` implements it) and the interface to depend on
/// when all you need is to read and write strings.
abstract class KvStore implements KvStoreRead, KvStoreWrite {
  /// Creates a store from the 3 methods, handy to wrap an existing storage
  /// without writing a class.
  factory KvStore({
    required KvStoreGetStringFunction getString,
    required KvStoreSetStringFunction setString,
    required KvStoreRemoveFunction remove,
  }) {
    return _KvStore(getString, setString, remove);
  }
}

/// Store extension
extension KvStoreExt on KvStore {
  /// Set or remove a string value
  Future<void> setStringOrNull(String key, String? value) =>
      value == null ? remove(key) : setString(key, value);
}

class _KvStore implements KvStore {
  final KvStoreGetStringFunction _getString;
  final KvStoreSetStringFunction _setString;
  final KvStoreRemoveFunction _remove;

  _KvStore(this._getString, this._setString, this._remove);

  @override
  Future<String?> getString(String key) => _getString(key);

  @override
  Future<void> setString(String key, String value) => _setString(key, value);

  @override
  Future<void> remove(String key) => _remove(key);

  @override
  String toString() => 'KvStore()';
}
