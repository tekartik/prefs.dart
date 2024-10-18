import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_prefs_flutter/prefs_mock.dart';
import 'package:tekartik_prefs_test/prefs_test.dart' as prefs;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  prefs.runPrefsTests(PrefsFactoryFlutterMock());
}
