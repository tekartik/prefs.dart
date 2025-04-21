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
}

/// Prefs factory.
abstract class PrefsAsyncWithCacheFactory {
  /// Global options
  PrefsAsyncFactoryOptions get options;

  /// Delete a prefs.
  Future<void> deletePreferences(String name);

  /// Open a prefs.
  Future<PrefsAsync> openPreferences(
    String name, {
    int? version,
    PrefsAsyncOnVersionChangedFunction? onVersionChanged,
  });
}
