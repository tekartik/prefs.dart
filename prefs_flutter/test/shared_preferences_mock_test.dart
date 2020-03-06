// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedantic/pedantic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tekartik_prefs_flutter/prefs_mock.dart';

void main() {
  group('mock', () {
    SharedPreferences preferences;

    const kTestValues = <String, dynamic>{
      'String': 'hello world',
      'bool': true,
      'int': 42,
      'double': 3.14159,
      'List': <String>['foo', 'bar'],
    };

    setUp(() async {
      unawaited(initSharedPreferencesMock());
      preferences = await SharedPreferences.getInstance();
    });
    test('empty', () async {
      expect(preferences.getInt('test'), isNull);
      await preferences.setInt('test', 1);
      expect(preferences.getInt('test'), 1);
      await preferences.clear();
      expect(sharedPreferencesMock.data, isEmpty);
      expect(preferences.getInt('test'), isNull);

      await preferences.setInt('test', 1);
      expect(preferences.getInt('test'), 1);

      await preferences.remove('test');
      expect(preferences.getInt('test'), isNull);
    });

    test('reading', () async {
      var preferences = await initSharedPreferencesMock(kTestValues);
      expect(preferences.get('String'), kTestValues['String']);
      expect(preferences.get('bool'), kTestValues['bool']);
      expect(preferences.get('int'), kTestValues['int']);
      expect(preferences.get('double'), kTestValues['double']);
      expect(preferences.get('List'), kTestValues['List']);
      expect(preferences.getString('String'), kTestValues['String']);
      expect(preferences.getBool('bool'), kTestValues['bool']);
      expect(preferences.getInt('int'), kTestValues['int']);
      expect(preferences.getDouble('double'), kTestValues['double']);
      expect(preferences.getStringList('List'), kTestValues['List']);
    });
  });
  group('$SharedPreferences', () {
    const kTestValues = <String, dynamic>{
      'flutter.String': 'hello world',
      'flutter.bool': true,
      'flutter.int': 42,
      'flutter.double': 3.14159,
      'flutter.List': <String>['foo', 'bar'],
    };

    const kTestValues2 = <String, dynamic>{
      'flutter.String': 'goodbye world',
      'flutter.bool': false,
      'flutter.int': 1337,
      'flutter.double': 2.71828,
      'flutter.List': <String>['baz', 'quox'],
    };

    final log = <MethodCall>[];
    SharedPreferences preferences;

    setUp(() async {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'getAll') {
          return kTestValues;
        }
        return null;
      });
      preferences = await SharedPreferences.getInstance();
      log.clear();
    });

    tearDown(() {
      preferences.clear();
    });

    test('reading', () async {
      expect(preferences.get('String'), kTestValues['flutter.String']);
      expect(preferences.get('bool'), kTestValues['flutter.bool']);
      expect(preferences.get('int'), kTestValues['flutter.int']);
      expect(preferences.get('double'), kTestValues['flutter.double']);
      expect(preferences.get('List'), kTestValues['flutter.List']);
      expect(preferences.getString('String'), kTestValues['flutter.String']);
      expect(preferences.getBool('bool'), kTestValues['flutter.bool']);
      expect(preferences.getInt('int'), kTestValues['flutter.int']);
      expect(preferences.getDouble('double'), kTestValues['flutter.double']);
      expect(preferences.getStringList('List'), kTestValues['flutter.List']);
      expect(log, <Matcher>[]);
    });

    test('writing', () async {
      await Future.wait(<Future<bool>>[
        preferences.setString(
            'String', kTestValues2['flutter.String'] as String),
        preferences.setBool('bool', kTestValues2['flutter.bool'] as bool),
        preferences.setInt('int', kTestValues2['flutter.int'] as int),
        preferences.setDouble(
            'double', kTestValues2['flutter.double'] as double),
        preferences.setStringList(
            'List', kTestValues2['flutter.List'] as List<String>)
      ]);
      expect(
        log,
        <Matcher>[
          isMethodCall('setString', arguments: <String, dynamic>{
            'key': 'flutter.String',
            'value': kTestValues2['flutter.String']
          }),
          isMethodCall('setBool', arguments: <String, dynamic>{
            'key': 'flutter.bool',
            'value': kTestValues2['flutter.bool']
          }),
          isMethodCall('setInt', arguments: <String, dynamic>{
            'key': 'flutter.int',
            'value': kTestValues2['flutter.int']
          }),
          isMethodCall('setDouble', arguments: <String, dynamic>{
            'key': 'flutter.double',
            'value': kTestValues2['flutter.double']
          }),
          isMethodCall('setStringList', arguments: <String, dynamic>{
            'key': 'flutter.List',
            'value': kTestValues2['flutter.List']
          }),
        ],
      );
      log.clear();

      expect(preferences.getString('String'), kTestValues2['flutter.String']);
      expect(preferences.getBool('bool'), kTestValues2['flutter.bool']);
      expect(preferences.getInt('int'), kTestValues2['flutter.int']);
      expect(preferences.getDouble('double'), kTestValues2['flutter.double']);
      expect(preferences.getStringList('List'), kTestValues2['flutter.List']);
      expect(log, equals(<MethodCall>[]));
    });

    test('removing', () async {
      const key = 'testKey';

      preferences
        ..setString(key, null) // ignore: unawaited_futures
        ..setBool(key, null) // ignore: unawaited_futures
        ..setInt(key, null) // ignore: unawaited_futures
        ..setDouble(key, null) // ignore: unawaited_futures
        ..setStringList(key, null); // ignore: unawaited_futures
      await preferences.remove(key);
      expect(
          log,
          List<Matcher>.filled(
            6,
            isMethodCall(
              'remove',
              arguments: <String, dynamic>{'key': 'flutter.$key'},
            ),
            growable: true,
          ));
    });

    test('clearing', () async {
      await preferences.clear();
      expect(preferences.getString('String'), null);
      expect(preferences.getBool('bool'), null);
      expect(preferences.getInt('int'), null);
      expect(preferences.getDouble('double'), null);
      expect(preferences.getStringList('List'), null);
      expect(log, <Matcher>[isMethodCall('clear', arguments: null)]);
    });

    test('mocking', () async {
      expect(await channel.invokeMethod('getAll'), kTestValues);
      SharedPreferences.setMockInitialValues(kTestValues2);
      expect(await channel.invokeMethod('getAll'), kTestValues2);
    });
  });
}
