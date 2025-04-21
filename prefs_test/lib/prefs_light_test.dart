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

void runPrefsLightTests(Prefs prefs) {
  var keyInt = testKey('int');
  var keyString = testKey('string');
  var keyBool = testKey('bool');
  var keyDouble = testKey('double');

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

    expect(await prefs.getInt(keyDouble), isNull);
    expect(await prefs.getString(keyDouble), isNull);
    expect(await prefs.getBool(keyDouble), isNull);

    await prefs.remove(keyDouble);
    expect(await prefs.getDouble(keyDouble), isNull);
  });
}
