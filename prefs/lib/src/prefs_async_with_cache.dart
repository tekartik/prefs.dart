import 'dart:async';

import 'package:tekartik_prefs/src/prefs.dart';
import 'package:tekartik_prefs/src/prefs_async.dart';

/// Common Prefs interface.
abstract class PrefsAsyncWithCache implements PrefsSyncRead, PrefsAsyncWrite {
  /// The name of the prefs.
  String get name;

  /// The version of the prefs.
  int get version;

  /// no more access possible
  Future<void> close();

  /// The options
  PrefsAsyncWithCacheFactoryOptions get options;
}

/// Prefs factory.
abstract class PrefsAsyncWithCacheFactory {
  /// Global options
  PrefsAsyncWithCacheFactoryOptions get options;

  /// Delete a prefs.
  Future<void> deletePreferences(String name);

  /// Open a prefs.
  Future<PrefsAsyncWithCache> openPreferences(
    String name, {
    int? version,
    PrefsAsyncWithCacheOnVersionChangedFunction? onVersionChanged,
  });

  /// Initialize the factory
  void init({PrefsAsyncWithCacheFactoryOptions? options});
}

/// Prefs on version changed function
typedef PrefsAsyncWithCacheOnVersionChangedFunction =
    FutureOr<void> Function(
      PrefsAsyncWithCache pref,
      int oldVersion,
      int newVersion,
    );

/// Async factory options
class PrefsAsyncWithCacheFactoryOptions {
  /// Default constructor
  PrefsAsyncWithCacheFactoryOptions();
}
