import 'package:tekartik_prefs/prefs.dart';
import 'package:tekartik_prefs/prefs_async.dart';
import 'package:test/test.dart';

void main() {
  group('sandbox', () {
    group('PrefsFactory', () {
      test('basic', () async {
        var baseFactory = newPrefsFactoryMemory();
        var sandboxFactory = baseFactory.sandbox(path: 'my_sandbox');

        expect(sandboxFactory.hasStorage, isFalse);

        var prefs = await sandboxFactory.openPreferences('test1');
        expect(prefs.name, 'test1');
        prefs.setBool('test', true);
        await prefs.close();

        // Check that it was actually opened in the sandbox directory in the delegate
        var basePrefs = await baseFactory.openPreferences('my_sandbox/test1');
        expect(basePrefs.getBool('test'), true);
        await basePrefs.close();

        // Check that it's not present outside the sandbox with standard name
        var basePrefs2 = await baseFactory.openPreferences('test1');
        expect(basePrefs2.getBool('test'), isNull);
        await basePrefs2.close();
      });

      test('nested sandbox', () async {
        var baseFactory = newPrefsFactoryMemory();
        var sandboxFactory1 = baseFactory.sandbox(path: 'dir1');
        var sandboxFactory2 = sandboxFactory1.sandbox(path: 'dir2');

        var prefs = await sandboxFactory2.openPreferences('test1');
        expect(prefs.name, 'test1');
        prefs.setBool('test', true);
        await prefs.close();

        // Check in delegate
        var basePrefs = await baseFactory.openPreferences('dir1/dir2/test1');
        expect(basePrefs.getBool('test'), true);
        await basePrefs.close();
      });

      test('escaping sandbox throws', () async {
        var baseFactory = newPrefsFactoryMemory();
        var sandboxFactory = baseFactory.sandbox(path: 'my_sandbox');

        expect(
          () => sandboxFactory.openPreferences('../other'),
          throwsArgumentError,
        );
        expect(
          () => sandboxFactory.deletePreferences('../other'),
          throwsArgumentError,
        );
      });

      test('onVersionChanged', () async {
        var baseFactory = newPrefsFactoryMemory();
        var sandboxFactory = baseFactory.sandbox(path: 'my_sandbox');

        Prefs? callbackPrefs;
        var prefs = await sandboxFactory.openPreferences(
          'test1',
          version: 1,
          onVersionChanged: (p, oldVersion, newVersion) async {
            callbackPrefs = p;
            expect(p.name, 'test1');
            p.setBool('initialized', true);
          },
        );
        expect(callbackPrefs, isNotNull);
        expect(prefs.getBool('initialized'), true);
        await prefs.close();
      });
    });

    group('PrefsAsyncFactory', () {
      test('basic', () async {
        var baseFactory = newPrefsAsyncFactoryMemory();
        var sandboxFactory = baseFactory.sandbox(path: 'my_sandbox');

        var prefs = await sandboxFactory.openPreferences('test1');
        expect(prefs.name, 'test1');
        await prefs.setBool('test', true);
        await prefs.close();

        // Check that it was actually opened in the sandbox directory in the delegate
        var basePrefs = await baseFactory.openPreferences('my_sandbox/test1');
        expect(await basePrefs.getBool('test'), true);
        await basePrefs.close();

        // Check that it's not present outside the sandbox with standard name
        var basePrefs2 = await baseFactory.openPreferences('test1');
        expect(await basePrefs2.getBool('test'), isNull);
        await basePrefs2.close();
      });

      test('nested sandbox', () async {
        var baseFactory = newPrefsAsyncFactoryMemory();
        var sandboxFactory1 = baseFactory.sandbox(path: 'dir1');
        var sandboxFactory2 = sandboxFactory1.sandbox(path: 'dir2');

        var prefs = await sandboxFactory2.openPreferences('test1');
        expect(prefs.name, 'test1');
        await prefs.setBool('test', true);
        await prefs.close();

        // Check in delegate
        var basePrefs = await baseFactory.openPreferences('dir1/dir2/test1');
        expect(await basePrefs.getBool('test'), true);
        await basePrefs.close();
      });

      test('escaping sandbox throws', () async {
        var baseFactory = newPrefsAsyncFactoryMemory();
        var sandboxFactory = baseFactory.sandbox(path: 'my_sandbox');

        expect(
          () => sandboxFactory.openPreferences('../other'),
          throwsArgumentError,
        );
        expect(
          () => sandboxFactory.deletePreferences('../other'),
          throwsArgumentError,
        );
      });

      test('onVersionChanged', () async {
        var baseFactory = newPrefsAsyncFactoryMemory();
        var sandboxFactory = baseFactory.sandbox(path: 'my_sandbox');

        PrefsAsync? callbackPrefs;
        var prefs = await sandboxFactory.openPreferences(
          'test1',
          version: 1,
          onVersionChanged: (p, oldVersion, newVersion) async {
            callbackPrefs = p;
            expect(p.name, 'test1');
            await p.setBool('initialized', true);
          },
        );
        expect(callbackPrefs, isNotNull);
        expect(await prefs.getBool('initialized'), true);
        await prefs.close();
      });
    });
  });
}
