import 'dart:async';

export 'src/prefs_memory.dart' show prefsFactoryMemory;

abstract class Prefs {
  String get name;

  int get version;

  bool getBool(String name);

  String getString(String name);

  int getInt(String name);

  double getDouble(String name);

  Map<String, dynamic> getMap(String name);

  List<dynamic> getList(String name);

  void setString(String name, String value);

  void setInt(String name, int value);

  void setMap(String name, Map value);

  void setBool(String name, bool value);

  void setDouble(String name, double value);

  void setList(String name, List<dynamic> value);

  Set<String> get keys;

  // Clear all prefs
  void clear();

  // Force saving the pending changes (set are asynchronously saved) if any
  Future save();

  // no more access possible
  Future close();
}

abstract class PrefsFactory {
  bool get hasStorage; // true if not memory
  Future deletePreferences(String name);

  Future<Prefs> openPreferences(String name,
      {int version,
      Future onVersionChanged(Prefs pref, int oldVersion, int newVersion)});
}
