import 'dart:html';

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_prefs/prefs.dart';
import 'package:tekartik_prefs/src/prefs_mixin.dart'; // ignore: implementation_imports

Storage get storage => window.localStorage;

class PrefsBrowser extends Object with PrefsMixin implements Prefs {
  final PrefsFactoryBrowser prefsFactoryBrowser;
  @override
  final String name;
  @override
  int version = 0;

  PrefsBrowser(this.prefsFactoryBrowser, this.name);

  String getKey(String name) => '${this.name}/$name';

  @override
  Future save() async {
    if (changes.isNotEmpty) {
      var changes = Map<String, Object?>.from(this.changes);
      importChanges();

      changes.forEach((String name, value) {
        // devPrint('saving $name: $value');
        var key = getKey(name);
        if (value == null) {
          storage.remove(key);
        } else if (value is num || value is bool || value is String) {
          storage[key] = value.toString();
        } else {
          storage[key] = encodeJson(value)!;
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
    var value = storage[key];
    // devPrint('loading $name: $value ${value?.runtimeType}');
    return value;
  }

  @override
  Set<String> get keys {
    var keys = <String>{};
    for (var key in storage.keys) {
      if (key.startsWith('$name/')) {
        keys.add(key.substring(name.length + 1));
      }
    }
    return keys..addAll(super.keys);
  }
}

final _allPrefs = <String, PrefsBrowser>{};

class PrefsFactoryBrowser extends Object
    with PrefsFactoryMixin
    implements PrefsFactory {
  final lock = Lock();

  @override
  Future<Prefs> openPreferences(String name,
      {int? version,
      Future Function(Prefs pref, int oldVersion, int newVersion)?
          onVersionChanged}) async {
    return await lock.synchronized(() async {
      var prefs = _allPrefs[name] ??= PrefsBrowser(this, name);

      final oldVersion = prefs.version;
      if (version != null && version != oldVersion) {
        if (onVersionChanged != null) {
          await onVersionChanged(prefs, oldVersion, version);
        }
        prefs.version = version;
      }
      return prefs;
    });
  }

  @override
  Future deletePreferences(String name) async {
    _allPrefs.remove(name);
    var list = List<String>.from(storage.keys);
    for (final key in list) {
      if (key.startsWith('$name/')) {
        storage.remove(key);
      }
    }
  }

  @override
  bool get hasStorage => true;
}

PrefsFactoryBrowser? _prefsFactoryBrowser;

PrefsFactory get prefsFactoryBrowser =>
    _prefsFactoryBrowser ??= PrefsFactoryBrowser();
