import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:tekartik_common_utils/bool_utils.dart';

bool get runningOnTravis => parseBool(Platform.environment['TRAVIS']) == true;

Future main() async {
  var shell = Shell();

  await shell.run('''

flutter analyze
# flutter test

''');

  if (!runningOnTravis) {
    // Skip test on travis
    await shell.run('flutter test');
  }
}
