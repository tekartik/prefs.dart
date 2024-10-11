import 'dart:async';

import 'package:synchronized/synchronized.dart';
import 'package:tekartik_prefs/prefs.dart';
import 'package:tekartik_prefs/src/prefs_mixin.dart';

/// In memory prefs
class PrefsMemory extends Object with PrefsMixin implements Prefs {
  @override
  final String name;

  @override
  int version = 0;

  /// Create a memory prefs with a name
  PrefsMemory(this.name);

  @override
  Future close() async {
    // Do nothing
  }

  // by default it is null
  @override
  dynamic getSourceValue(String name) => null;
}

/// In memory prefs factory
class PrefsFactoryMemory extends Object
    with PrefsFactoryMixin
    implements PrefsFactory {
  final Map<String, PrefsMemory> _allPrefs = <String, PrefsMemory>{};

  final _lock = Lock();

  @override
  Future<Prefs> openPreferences(String name,
      {int? version,
      Future Function(Prefs pref, int oldVersion, int newVersion)?
          onVersionChanged}) async {
    return await _lock.synchronized(() async {
      var prefs = _allPrefs[name] ??= PrefsMemory(name);

      await prefs.handleMigration(
          version: version, onVersionChanged: onVersionChanged);
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

PrefsFactoryMemory? _prefsFactoryMemory;

/// Global in memory prefs
PrefsFactory get prefsFactoryMemory =>
    _prefsFactoryMemory ??= PrefsFactoryMemory();

/// New empty memory prefs factory in memory
PrefsFactory newPrefsFactoryMemory() => PrefsFactoryMemory();
