import 'package:dev_test/package.dart';
import 'package:path/path.dart';

Future main() async {
  for (var dir in [
    'prefs',
    'prefs_browser',
    'prefs_sembast',
    'prefs_test',
    'prefs_flutter',
  ]) {
    await packageRunCi(join('..', dir));
  }
}
