import 'package:tekartik_prefs/src/prefs_mixin.dart';
import 'package:tekartik_common_utils/bool_utils.dart';
import 'package:test/test.dart';

void main() {
  group('prefs_mixin', () {
    test('parseInt', () {
      expect(parseInt(-7), -7);
      expect(parseInt('1'), 1);
      expect(parseInt('False'), 0);
      expect(parseInt('truE'), 1);
      expect(parseInt('dummy'), isNull);
      expect(parseInt('-3'), -3);
      expect(parseInt('-3.2'), -3);
    });

    test('parseBool', () {
      expect(parseBool(false), false);
      expect(parseBool(true), true);
      expect(parseBool(0), false);
      expect(parseBool(1), true);
      expect(parseBool(-2), true);
      expect(parseBool('0'), false);
      expect(parseBool('dummy'), isNull);
    });
  });
}
