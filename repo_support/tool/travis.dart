import 'package:process_run/shell.dart';
import 'package:path/path.dart';

Future main() async {
  var shell = Shell();

  for (var dir in [
    'prefs',
    'prefs_browser',
    'prefs_sembast',
    'prefs_test',
  ]) {
    shell = shell.pushd(join('..', dir));
    await shell.run('''
    
    dart pub get
    dart tool/travis.dart
    
''');
    shell = shell.popd();
  }

  for (var dir in [
    'prefs_flutter',
  ]) {
    shell = shell.pushd(join('..', dir));
    await shell.run('''
    
    flutter pub get
    dart tool/travis.dart
    
''');
    shell = shell.popd();
  }
}
