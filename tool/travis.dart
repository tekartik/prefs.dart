import 'travis_common.dart' as common;
import 'travis_flutter.dart' as flutter;

Future main() async {
  await common.main();
  await flutter.main();
}
