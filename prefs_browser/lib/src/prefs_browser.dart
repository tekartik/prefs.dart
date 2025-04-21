import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_prefs/prefs.dart';
import 'package:tekartik_prefs/src/prefs_mixin.dart'; // ignore: implementation_imports
import 'package:web/web.dart' show window, Storage;

const _internalId = 'tekartik_prefs_enabled_vKltV99p1fy0NGj7bD1C';
const _internalValue = 'X';

bool? _storageBrowserIsAvailableOrNull;

/// Check if storage is available (read, write check if persistent)
bool checkStorageBrowserIsAvailable({bool? persistent}) =>
    _storageBrowserIsAvailableOrNull ??= _checkStorageBrowserIsAvailable(
      persistent: persistent,
    );

/// Check if storage is available (read, write check if persistent)
bool _checkStorageBrowserIsAvailable({bool? persistent}) {
  persistent ??= false;
  try {
    var value = window.localStorage.getItem(_internalId);
    if (value == _internalValue) {
      return true;
    }
    if (!persistent) {
      return true;
    }
    window.localStorage.setItem(_internalId, _internalValue);
    value = window.localStorage.getItem(_internalId);
    if (value == _internalValue) {
      return true;
    }
  } catch (_) {
    // False if error
  }
  return false;
}

/// Global storage used not exported
@protected
Storage get storage => window.localStorage;
Iterable<String> get _nativeStorageKeys {
  var keys = <String>[];
  for (var i = 0; i < storage.length; i++) {
    keys.add(storage.key(i)!);
  }
  return keys;
}

class _PrefsBrowser extends Object with PrefsMixin implements Prefs {
  final _PrefsFactoryBrowser prefsFactoryBrowser;

  @override
  final String name;
  @override
  int version = 0;

  _PrefsBrowser(this.prefsFactoryBrowser, this.name);

  String getKey(String name) => '${this.name}/$name';

  @override
  Future save() async {
    if (changes.isNotEmpty) {
      var changes = Map<String, Object?>.from(this.changes);
      importChanges();
      if (pendingClear) {
        pendingClear = false;
        storage.clear();
      }
      changes.forEach((String name, value) {
        // devPrint('saving $name: $value');
        var key = getKey(name);
        if (value == null) {
          storage.removeItem(key);
        } else if (value is num || value is bool || value is String) {
          storage.setItem(key, value.toString());
        } else {
          storage.setItem(key, encodeJson(value)!);
        }
      });
    }
  }

  @override
  Future close() async {
    _allPrefs.remove(name);
    await save();
  }

  @override
  dynamic getSourceValue(String name) {
    var key = getKey(name);
    var value = storage.getItem(key);
    // devPrint('loading $name: $value ${value?.runtimeType}');
    return value;
  }

  @override
  Set<String> get keys {
    var keys = <String>{};
    for (var key in _nativeStorageKeys) {
      if (key.startsWith('$name/')) {
        keys.add(key.substring(name.length + 1));
      }
    }
    return keys..addAll(super.keys);
  }
}

final _allPrefs = <String, _PrefsBrowser>{};

class _PrefsFactoryBrowser extends Object
    with PrefsFactoryMixin
    implements PrefsFactory {
  final lock = Lock();

  @override
  Future<Prefs> openPreferences(
    String name, {
    final int? version,
    PrefsOnVersionChangedFunction? onVersionChanged,
  }) async {
    return await lock.synchronized(() async {
      var prefs = _allPrefs[name] ??= _PrefsBrowser(this, name);

      await prefs.handleMigration(
        version: version,
        onVersionChanged: onVersionChanged,
      );

      return prefs;
    });
  }

  @override
  Future deletePreferences(String name) async {
    _allPrefs.remove(name);
    var list = List<String>.from(_nativeStorageKeys);
    for (final key in list) {
      if (key.startsWith('$name/')) {
        storage.removeItem(key);
      }
    }
  }

  @override
  bool get hasStorage => true;
}

_PrefsFactoryBrowser? _prefsFactoryBrowser;

/// Always not null of the web
PrefsFactory? get prefsFactoryBrowserOrNull {
  try {
    return prefsFactoryBrowser;
  } catch (_) {
    return null;
  }
}

/// Throw if not on the web
PrefsFactory get prefsFactoryBrowser =>
    _prefsFactoryBrowser ??= _PrefsFactoryBrowser();
