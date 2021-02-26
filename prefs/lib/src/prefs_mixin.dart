import 'dart:async';

import 'package:tekartik_common_utils/bool_utils.dart';
import 'package:tekartik_common_utils/json_utils.dart';
import 'package:tekartik_prefs/prefs.dart';

const String signatureKey = '_signature';
const String prefsVersionKey = '_version';
const String signatureValue = 'tekartik_prefs';

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

abstract class PrefsFactoryMixin {
  String fixName(String name) {
    if (name == null || name.isEmpty) {
      return 'default.prefs';
    }
    return name;
  }
}

abstract class PrefsMixin implements Prefs {
  final data = <String, Object?>{};
  final changes = <String, Object?>{};

  dynamic getSourceValue(String name) => null;

  void revertChanges() => changes.clear();

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

  void setValue(String name, dynamic value) {
    checkName(name);
    checkValue(value);
    setDirty();
    changes[name] = value;
  }

  void setDirty() {
    if (changes.isEmpty) {
      scheduleMicrotask(() async {
        await save();
      });
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
    void _add(String name, dynamic value) {
      if (value != null && name != prefsVersionKey && name != signatureKey) {
        keys.add(name);
      }
    }

    data.forEach(_add);
    changes.forEach(_add);
    return keys;
  }

  @override
  void clear() {
    setDirty();
    changes.clear();
    data.forEach((String name, dynamic value) {
      changes[name] = null;
    });
  }

  // to call after saving
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

  void checkName(String name) {
    if (name == null || name.isEmpty) {
      throw ArgumentError.notNull('prefs key name cannot be null or empty');
    }
    if (name.startsWith('_')) {
      throw ArgumentError('prefs key name cannot start with _');
    }
  }

  void checkValue(dynamic value) {
    dynamic testedValue = value;
    void _checkValue(dynamic value) {
      if (value == null || value is String || value is num || value is bool) {
        // ok
      } else if (value is List) {
        value.forEach((dynamic v) => _checkValue(v));
      } else if (value is Map) {
        value.forEach((dynamic k, dynamic v) => _checkValue(v));
      } else {
        throw ArgumentError(
            '$value type ${value.runtimeType} in ${testedValue} not supported');
      }
    }

    _checkValue(value);
  }

  @override
  void remove(String name) {
    setValue(name, null);
  }
}
