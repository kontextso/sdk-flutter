import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/device_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceScreen.empty', () {
    test('zeros width/height/dpr and defaults to portrait + light mode', () {
      final s = DeviceScreen.empty();
      expect(s.width, 0);
      expect(s.height, 0);
      expect(s.dpr, 0);
      expect(s.orientation, ScreenOrientation.portrait);
      expect(s.darkMode, false);
    });

    test('toJson emits every field using enum name for orientation', () {
      final json = DeviceScreen.empty().toJson();
      expect(json['width'], 0);
      expect(json['height'], 0);
      expect(json['dpr'], 0);
      expect(json['orientation'], 'portrait');
      expect(json['darkMode'], false);
    });
  });

  group('DeviceScreen.init', () {
    test('does not throw under the test binding and returns non-negative dimensions', () {
      final s = DeviceScreen.init();
      expect(s.width >= 0, isTrue);
      expect(s.height >= 0, isTrue);
      expect(s.dpr >= 0, isTrue);
      expect(s.orientation, anyOf(ScreenOrientation.portrait, ScreenOrientation.landscape));
      // Under the test binding, the brightness is accessible without throwing.
      expect(s.darkMode, anyOf(true, false));
    });

    test('toJson on the live instance emits all expected keys', () {
      final json = DeviceScreen.init().toJson();
      expect(json.keys, containsAll(['width', 'height', 'dpr', 'orientation', 'darkMode']));
    });
  });
}
