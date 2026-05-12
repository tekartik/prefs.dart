import 'package:dev_build/package.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';

Future main() async {
  if (dartVersion >= Version(2, 12, 0, pre: '0')) {
    for (var dir in ['prefs', 'prefs_browser', 'prefs_sembast', 'prefs_test']) {
      await packageRunCi(join('..', dir));
    }
  }
}
