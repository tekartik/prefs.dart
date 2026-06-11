import 'dart:async';
import 'package:path/path.dart' as p;
import 'prefs.dart';
import 'prefs_async.dart';
import 'prefs_mixin.dart';

/// Prefs factory sandbox extension.
extension PrefsFactorySandboxExtension on PrefsFactory {
  /// Prefs factory sandboxing.
  ///
  /// Every preference opened, deleted or checked through the returned factory
  /// is located below [path] in the original factory.
  ///
  /// If the factory is already a sandbox, the tree is sanitized (i.e. never 2
  /// levels of sandboxing).
  ///
  /// Works with any [PrefsFactory] implementation (io, memory, web).
  PrefsFactory sandbox({required String path}) {
    var self = this;
    if (self is _PrefsFactorySandbox) {
      return _PrefsFactorySandbox(
        delegate: self.delegate,
        rootPath: self.delegatePath(path),
      );
    }
    return _PrefsFactorySandbox(delegate: this, rootPath: path);
  }
}

/// Prefs async factory sandbox extension.
extension PrefsAsyncFactorySandboxExtension on PrefsAsyncFactory {
  /// Prefs async factory sandboxing.
  ///
  /// Every preference opened, deleted or checked through the returned factory
  /// is located below [path] in the original factory.
  ///
  /// If the factory is already a sandbox, the tree is sanitized (i.e. never 2
  /// levels of sandboxing).
  ///
  /// Works with any [PrefsAsyncFactory] implementation (io, memory, web).
  PrefsAsyncFactory sandbox({required String path}) {
    var self = this;
    if (self is _PrefsAsyncFactorySandbox) {
      return _PrefsAsyncFactorySandbox(
        delegate: self.delegate,
        rootPath: self.delegatePath(path),
      );
    }
    return _PrefsAsyncFactorySandbox(delegate: this, rootPath: path);
  }
}

class _PrefsFactorySandbox implements PrefsFactory {
  _PrefsFactorySandbox({required this.delegate, required String rootPath})
    : rootPath = p.normalize(rootPath);

  /// The wrapped factory.
  final PrefsFactory delegate;

  /// The root path of the sandbox in the delegate factory.
  final String rootPath;

  /// Converts a path in the sandboxed factory to a path in the delegate
  /// factory. Throws an [ArgumentError] if the path escapes the sandbox.
  String delegatePath(String path) {
    var relativePath = p.isAbsolute(path)
        ? p.relative(path, from: p.rootPrefix(path))
        : path;
    var fullPath = p.normalize(p.join(rootPath, relativePath));
    if (!p.isWithin(rootPath, fullPath)) {
      throw ArgumentError.value(
        path,
        'path',
        'Path is outside of the sandbox root $rootPath',
      );
    }
    return fullPath;
  }

  @override
  bool get hasStorage => delegate.hasStorage;

  @override
  Future deletePreferences(String name) =>
      delegate.deletePreferences(delegatePath(name));

  @override
  Future<Prefs> openPreferences(
    String name, {
    int? version,
    PrefsOnVersionChangedFunction? onVersionChanged,
  }) async {
    var delegateName = delegatePath(name);
    _PrefsSandbox? wrappedPrefs;
    PrefsOnVersionChangedFunction? wrappedOnVersionChanged;
    if (onVersionChanged != null) {
      wrappedOnVersionChanged =
          (Prefs delegatePrefs, int oldVersion, int newVersion) {
            wrappedPrefs ??= _PrefsSandbox(delegatePrefs, name);
            return onVersionChanged(wrappedPrefs!, oldVersion, newVersion);
          };
    }
    var delegatePrefs = await delegate.openPreferences(
      delegateName,
      version: version,
      onVersionChanged: wrappedOnVersionChanged,
    );
    return wrappedPrefs ??= _PrefsSandbox(delegatePrefs, name);
  }

  @override
  String toString() => 'sandbox($delegate, $rootPath)';
}

class _PrefsSandbox implements Prefs {
  final Prefs delegate;
  @override
  final String name;

  _PrefsSandbox(this.delegate, this.name);

  @override
  int get version => delegate.version;

  @override
  bool? getBool(String name) => delegate.getBool(name);

  @override
  String? getString(String name) => delegate.getString(name);

  @override
  int? getInt(String name) => delegate.getInt(name);

  @override
  double? getDouble(String name) => delegate.getDouble(name);

  @override
  bool containsKey(String key) => delegate.containsKey(key);

  @override
  Set<String> get keys => delegate.keys;

  @override
  void setString(String name, String? value) => delegate.setString(name, value);

  @override
  void setInt(String name, int? value) => delegate.setInt(name, value);

  @override
  void setMap(String name, Map? value) => delegate.setMap(name, value);

  @override
  void setBool(String name, bool? value) => delegate.setBool(name, value);

  @override
  void setDouble(String name, double? value) => delegate.setDouble(name, value);

  @override
  void setList(String name, List<Object?>? value) =>
      delegate.setList(name, value);

  @override
  void remove(String name) => delegate.remove(name);

  @override
  void clear() => delegate.clear();

  @override
  Future save() => delegate.save();

  @override
  Future close() => delegate.close();

  @override
  String toString() => 'Prefs($name, $delegate)';
}

class _PrefsAsyncFactorySandbox implements PrefsAsyncFactory {
  _PrefsAsyncFactorySandbox({required this.delegate, required String rootPath})
    : rootPath = p.normalize(rootPath);

  /// The wrapped factory.
  final PrefsAsyncFactory delegate;

  /// The root path of the sandbox in the delegate factory.
  final String rootPath;

  /// Converts a path in the sandboxed factory to a path in the delegate
  /// factory. Throws an [ArgumentError] if the path escapes the sandbox.
  String delegatePath(String path) {
    var relativePath = p.isAbsolute(path)
        ? p.relative(path, from: p.rootPrefix(path))
        : path;
    var fullPath = p.normalize(p.join(rootPath, relativePath));
    if (!p.isWithin(rootPath, fullPath)) {
      throw ArgumentError.value(
        path,
        'path',
        'Path is outside of the sandbox root $rootPath',
      );
    }
    return fullPath;
  }

  @override
  PrefsAsyncFactoryOptions get options => delegate.options;

  @override
  void init({PrefsAsyncFactoryOptions? options}) =>
      delegate.init(options: options);

  @override
  Future<void> deletePreferences(String name) =>
      delegate.deletePreferences(delegatePath(name));

  @override
  Future<PrefsAsync> openPreferences(
    String name, {
    int? version,
    PrefsAsyncOnVersionChangedFunction? onVersionChanged,
  }) async {
    var delegateName = delegatePath(name);
    _PrefsAsyncSandbox? wrappedPrefs;
    PrefsAsyncOnVersionChangedFunction? wrappedOnVersionChanged;
    if (onVersionChanged != null) {
      wrappedOnVersionChanged =
          (PrefsAsync delegatePrefs, int oldVersion, int newVersion) {
            wrappedPrefs ??= _PrefsAsyncSandbox(delegatePrefs, name);
            return onVersionChanged(wrappedPrefs!, oldVersion, newVersion);
          };
    }
    var delegatePrefs = await delegate.openPreferences(
      delegateName,
      version: version,
      onVersionChanged: wrappedOnVersionChanged,
    );
    return wrappedPrefs ??= _PrefsAsyncSandbox(delegatePrefs, name);
  }

  @override
  String toString() => 'sandbox($delegate, $rootPath)';
}

class _PrefsAsyncSandbox implements PrefsAsync {
  final PrefsAsync delegate;
  @override
  final String name;

  _PrefsAsyncSandbox(this.delegate, this.name);

  @override
  int get version => delegate.version;

  @override
  PrefsAsyncFactoryOptions get options => delegate.options;

  @override
  Future<void> setStringList(String key, List<String> value) =>
      delegate.setStringList(key, value);

  @override
  Future<void> close() => delegate.close();

  @override
  Future<void> setString(String key, String value) =>
      delegate.setString(key, value);

  @override
  Future<void> setInt(String key, int value) => delegate.setInt(key, value);

  @override
  Future<void> setBool(String key, bool value) => delegate.setBool(key, value);

  @override
  Future<void> setDouble(String key, double value) =>
      delegate.setDouble(key, value);

  @override
  Future<void> remove(String key) => delegate.remove(key);

  @override
  Future<void> clear() => delegate.clear();

  @override
  Future<bool?> getBool(String key) => delegate.getBool(key);

  @override
  Future<String?> getString(String key) => delegate.getString(key);

  @override
  Future<int?> getInt(String key) => delegate.getInt(key);

  @override
  Future<double?> getDouble(String key) => delegate.getDouble(key);

  @override
  Future<List<String>?> getStringList(String key) =>
      delegate.getStringList(key);

  @override
  Future<bool> containsKey(String key) => delegate.containsKey(key);

  @override
  Future<Set<String>> getKeys() => delegate.getKeys();

  @override
  Future<Map<String, Object?>> getAll() => delegate.getAll();

  @override
  String toString() => 'PrefsAsync($name, $delegate)';
}
