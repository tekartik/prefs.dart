import 'dart:async';

import 'package:synchronized/synchronized.dart';
import 'package:tekartik_prefs/prefs.dart';
import 'package:tekartik_prefs/src/prefs_mixin.dart';

class PrefsMemory extends Object with PrefsMixin implements Prefs {
  @override
  final String name;

  @override
  int version = 0;

  PrefsMemory(this.name);

  @override
  Future close() async {
    _allPrefs.remove(name);
  }

  // by default it is null
  @override
  dynamic getSourceValue(String name) => null;
}

final Map<String, PrefsMemory> _allPrefs = <String, PrefsMemory>{};

class PrefsFactoryMemory extends Object
    with PrefsFactoryMixin
    implements PrefsFactory {
  final lock = Lock();

  @override
  Future<Prefs> openPreferences(String name,
      {int version,
      Future Function(Prefs pref, int oldVersion, int newVersion)
          onVersionChanged}) async {
    return await lock.synchronized(() async {
      var prefs = _allPrefs[name] ??= PrefsMemory(name);

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
  }

  @override
  bool get hasStorage => false;
}

PrefsFactoryMemory _prefsFactoryMemory;

PrefsFactory get prefsFactoryMemory =>
    _prefsFactoryMemory ??= PrefsFactoryMemory();
