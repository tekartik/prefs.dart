// ignore_for_file: avoid_print

import 'package:tekartik_prefs/prefs_light.dart';
import 'package:test/test.dart';

export 'package:tekartik_prefs/prefs_async.dart';

void main() {
  runPrefsLightTests(PrefsMemory());
}

var _keyPrefix = 'prefs_light_test';
String testKey(String key) {
  return '$_keyPrefix.$key';
}

void runPrefsLightTests(PrefsLight prefs) {
  var keyInt = testKey('int');
  var keyString = testKey('string');
  var keyBool = testKey('bool');
  var keyDouble = testKey('double');
  var keyMap = testKey('map');
  var keyList = testKey('list');

  test('int', () async {
    await prefs.setInt(keyInt, 1);
    expect(await prefs.getInt(keyInt), 1);

    await prefs.remove(keyInt);
    expect(await prefs.getInt(keyInt), isNull);
  });
  test('string', () async {
    await prefs.setString(keyString, 'test');
    expect(await prefs.getString(keyString), 'test');

    await prefs.remove(keyString);
    expect(await prefs.getString(keyString), isNull);

    await prefs.setStringOrNull(keyString, 'test');
    expect(await prefs.getString(keyString), 'test');
    await prefs.setStringOrNull(keyString, null);
    expect(await prefs.getString(keyString), isNull);
  });
  test('bool', () async {
    await prefs.setBool(keyBool, true);
    expect(await prefs.getBool(keyBool), true);

    await prefs.remove(keyBool);
    expect(await prefs.getBool(keyBool), isNull);
  });
  test('double', () async {
    await prefs.setDouble(keyDouble, 1.1);
    expect(await prefs.getDouble(keyDouble), 1.1);

    try {
      expect(await prefs.getInt(keyDouble), isNull);
    } catch (e) {
      expect(await prefs.getInt(keyDouble), 1);
      print('Error: $e');
    }

    try {
      expect(await prefs.getString(keyDouble), isNull);
    } catch (e) {
      expect(await prefs.getString(keyDouble), '1.1');
      print('Error: $e');
    }

    try {
      expect(await prefs.getBool(keyDouble), isNull);
    } catch (e) {
      expect(await prefs.getBool(keyDouble), true);
      print('Error: $e');
    }

    await prefs.remove(keyDouble);
    expect(await prefs.getDouble(keyDouble), isNull);
  });

  test('null', () async {
    await prefs.setStringOrNull(keyString, 'test');
    expect(await prefs.getString(keyString), 'test');
    await prefs.setStringOrNull(keyString, null);
    expect(await prefs.getString(keyString), isNull);

    await prefs.setBoolOrNull(keyBool, true);
    expect(await prefs.getBool(keyBool), true);
    await prefs.setBoolOrNull(keyBool, null);
    expect(await prefs.getBool(keyBool), isNull);

    await prefs.setIntOrNull(keyInt, 1);
    expect(await prefs.getInt(keyInt), 1);
    await prefs.setIntOrNull(keyInt, null);
    expect(await prefs.getInt(keyInt), isNull);

    await prefs.setDoubleOrNull(keyDouble, 1.1);
    expect(await prefs.getDouble(keyDouble), 1.1);
    await prefs.setDoubleOrNull(keyDouble, null);
    expect(await prefs.getDouble(keyDouble), isNull);

    var map = {'test': 1};
    await prefs.setMapOrNull(keyMap, map);
    expect(await prefs.getMap(keyMap), map);
    await prefs.setMapOrNull(keyMap, null);
    expect(await prefs.getMap(keyMap), isNull);

    var list = ['test', 1];
    await prefs.setListOrNull(keyList, list);
    expect(await prefs.getList(keyList), list);
    await prefs.setListOrNull(keyList, null);
    expect(await prefs.getList(keyList), isNull);
  });
}
