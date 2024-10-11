import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_prefs/prefs.dart';

/// signature key
const String prefsSignatureKey = '__tekartik_prefs_signature__';

/// prefs version key
const String prefsVersionKey = '__tekartik_prefs_version__';

/// signature value
const String prefsSignatureValue = 'tekartik_prefs';

Map<String, Object?>? _parseJsonObject(dynamic source) {
  if (source is Map) {
    return source.cast<String, Object?>();
  } else if (source is String) {
    return parseJsonObject(source)?.cast<String, Object?>();
  }
  return null;
}

List<Object?>? _parseJsonArray(dynamic source) {
  if (source is List) {
    return source.cast<Object?>();
  } else if (source is String) {
    dynamic decoded = parseJson(source);
    if (decoded is List) {
      return decoded.cast<Object?>();
    }
  }
  return null;
}

/// Parse an int value
int? parseInt(dynamic source) {
  if (source is num) {
    return source.toInt();
  } else if (source is String) {
    final value = int.tryParse(source);
    if (value != null) {
      return value;
    }
    if (source.toLowerCase() == 'true') {
      return 1;
    } else if (source.toLowerCase() == 'false') {
      return 0;
    }
    // Handle double value
    final numValue = num.tryParse(source);
    if (numValue != null) {
      return numValue.toInt();
    }
  } else if (source is bool) {
    return source ? 1 : 0;
  }
  return null;
}

double? _parseDouble(dynamic source) {
  if (source is num) {
    return source.toDouble();
  } else if (source is String) {
    return double.tryParse(source);
  }
  return null;
}

/// Prefs mixin
abstract mixin class PrefsFactoryMixin {
  /// Fix the name
  String fixName(String name) {
    if (name.isEmpty) {
      return 'default.prefs';
    }
    return name;
  }
}

/// Prefs mixin
abstract mixin class PrefsMixin implements Prefs {
  /// Pending clear in progress
  var pendingClear = false;
  set version(int version);

  /// The data
  final data = <String, Object?>{};

  /// The changes
  final changes = <String, Object?>{};

  /// Get the source value
  dynamic getSourceValue(String name) => null;

  /// Revert changes
  void revertChanges() => changes.clear();

  /// Get the value
  dynamic getValue(String name) {
    if (changes.containsKey(name)) {
      return changes[name];
    }
    if (data.containsKey(name)) {
      return data[name];
    }
    dynamic value = data[name] = getSourceValue(name);
    return value;
  }

  /// Set a value
  void setValue(String name, Object? value, {bool noCheckName = false}) {
    if (!noCheckName) {
      checkName(name);
    }
    checkValue(value);
    setDirty();
    changes[name] = value;
  }

  /// True if dirty
  bool get isDirty => changes.isNotEmpty;

  /// Set dirty
  void setDirty() {
    if (!isDirty) {
      scheduleMicrotask(() async {
        await save();
      });
    }
  }

  /// Handle migration
  Future<void> handleMigration(
      {final int? version,
      PrefsOnVersionChangedFunction? onVersionChanged}) async {
    var signature = getString(prefsSignatureKey);
    if (signature == prefsSignatureValue) {
      clear();
      setValue(prefsSignatureKey, prefsSignatureValue, noCheckName: true);
      setValue(prefsVersionKey, 0, noCheckName: true);
    }
    final prefsNewVersion = version;
    final prefsOldVersion = getInt(prefsVersionKey) ?? 0;
    this.version = prefsOldVersion;
    if (prefsNewVersion != null && prefsNewVersion != prefsOldVersion) {
      if (onVersionChanged != null) {
        await onVersionChanged(this, prefsOldVersion, prefsNewVersion);
      }
      setValue(prefsVersionKey, prefsNewVersion, noCheckName: true);
      this.version = prefsNewVersion;
    }
    if (isDirty) {
      await save();
    }
  }

  @override
  bool? getBool(String name) => parseBool(getValue(name));

  @override
  int? getInt(String name) => parseInt(getValue(name));

  @override
  Map<String, Object?>? getMap(String name) => _parseJsonObject(getValue(name));

  @override
  List<Object?>? getList(String name) => _parseJsonArray(getValue(name));

  @override
  String? getString(String name) {
    // for list and map, convert to json
    dynamic value = getValue(name);
    if (value is Iterable) {
      return encodeJson(value);
    } else if (value is Map) {
      return encodeJson(value);
    }
    return value?.toString();
  }

  @override
  void setInt(String name, int? value) => setValue(name, value);

  @override
  void setMap(String name, Map? value) => setValue(name, value);

  @override
  void setString(String name, String? value) => setValue(name, value);

  @override
  double? getDouble(String name) => _parseDouble(getValue(name));

  @override
  void setBool(String name, bool? value) => setValue(name, value);

  @override
  void setDouble(String name, double? value) => setValue(name, value);

  @override
  void setList(String name, List<Object?>? value) => setValue(name, value);

  @override
  Set<String> get keys {
    var keys = <String>{};
    void add(String name, dynamic value) {
      if (value != null &&
          name != prefsVersionKey &&
          name != prefsSignatureKey) {
        keys.add(name);
      }
    }

    data.forEach(add);
    changes.forEach(add);
    return keys;
  }

  @override
  void clear() {
    pendingClear = true;
    setDirty();
    changes.clear();
    data.forEach((String name, Object? value) {
      if (name != prefsVersionKey && name != prefsSignatureKey) {
        changes[name] = null;
      }
    });
  }

  /// to call after saving
  void importChanges() {
    data.addAll(changes);
    changes.clear();
  }

  @override
  Future save() async {
    if (changes.isNotEmpty) {
      importChanges();
    }
  }

  @override
  bool containsKey(String key) {
    return keys.contains(key);
  }

  /// Check the name
  void checkName(String name) {
    if (name.isEmpty) {
      throw ArgumentError.notNull('prefs key name cannot be empty');
    }
    if (name.startsWith('_')) {
      throw ArgumentError('prefs key name cannot start with _');
    }
  }

  /// Check the value
  void checkValue(dynamic value) {
    dynamic testedValue = value;
    void checkValue(dynamic value) {
      if (value == null || value is String || value is num || value is bool) {
        // ok
      } else if (value is List) {
        for (var v in value) {
          checkValue(v);
        }
      } else if (value is Map) {
        value.forEach((dynamic k, dynamic v) => checkValue(v));
      } else {
        throw ArgumentError(
            '$value type ${value.runtimeType} in $testedValue not supported');
      }
    }

    checkValue(value);
  }

  @override
  void remove(String name) {
    setValue(name, null);
  }
}

/// Prefs on version changed function
typedef PrefsOnVersionChangedFunction = Future<Object?> Function(
    Prefs pref, int oldVersion, int newVersion);
