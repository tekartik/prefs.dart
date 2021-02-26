import 'package:process_run/shell.dart';
import 'package:path/path.dart';

Future main() async {
  var shell = Shell();

  for (var dir in [
    'prefs',
    'prefs_browser',
    'prefs_sembast',
    'prefs_test',
    'prefs_flutter',
  ]) {
    shell = shell.pushd(join('..', dir));
    await shell.run('''
    
    pub get
    dart tool/travis.dart
    
''');
    shell = shell.popd();
  }
}
