import 'dart:async';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tekartik_prefs_flutter/src/prefs.dart';
export 'package:tekartik_prefs/prefs.dart';

class PrefsFactoryFlutterMock extends PrefsFactoryFlutter {
  static bool _inited = false;
  PrefsFactoryFlutterMock() {
    if (!_inited) {
      _inited = true;
      initSharedPreferencesMock();
    }
  }
/*
  @override
  bool get hasStorage => false;
  */
}

const MethodChannel channel = MethodChannel(
  'plugins.flutter.io/shared_preferences',
);

class SharedPreferencesMock {
  SharedPreferencesMock() {
    init();
  }

  final Map<String?, Object?> data = {};

  bool _set(MethodCall methodCall) {
    var argumentsMap = methodCall.arguments as Map;
    var key = argumentsMap['key'] as String?;
    dynamic value = argumentsMap['value'];
    data[key] = value;
    return true;
  }

  bool _remove(MethodCall methodCall) {
    var argumentsMap = methodCall.arguments as Map;
    var key = argumentsMap['key'] as String?;
    data.remove(key);
    return true;
  }

  Future _handler(MethodCall methodCall) async {
    if (methodCall.method == 'getAll') {
      return data;
    } else if (methodCall.method == 'setInt') {
      return _set(methodCall);
    } else if (methodCall.method == 'setBool') {
      return _set(methodCall);
    } else if (methodCall.method == 'setString') {
      return _set(methodCall);
    } else if (methodCall.method == 'setDouble') {
      return _set(methodCall);
    } else if (methodCall.method == 'setStringList') {
      return _set(methodCall);
    } else if (methodCall.method == 'clear') {
      data.clear();
      return true;
    } else if (methodCall.method == 'remove') {
      return _remove(methodCall);
    } else {
      throw 'invalid $methodCall';
    }
  }

  void init() {
    channel.setMethodCallHandler(_handler);
  }
}

Future<SharedPreferences> initSharedPreferencesMock(
    [Map<String, Object?>? data]) async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(<String, Object>{});
  sharedPreferencesMock = SharedPreferencesMock();
  var preferences = await SharedPreferences.getInstance();
  await preferences.clear();
  if (data != null) {
    for (var entry in data.entries) {
      dynamic value = entry.value;
      if (value is int) {
        await preferences.setInt(entry.key, value);
      } else if (value is int) {
        await preferences.setInt(entry.key, value);
      } else if (value is double) {
        await preferences.setDouble(entry.key, value);
      } else if (value is String) {
        await preferences.setString(entry.key, value);
      } else if (value is bool) {
        await preferences.setBool(entry.key, value);
      } else if (value is List) {
        await preferences.setStringList(entry.key, value.cast<String>());
      } else if (value == null) {
        await preferences.remove(entry.key);
      }
    }
  }
  return preferences;
}

late SharedPreferencesMock sharedPreferencesMock;
