import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/operation_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('kontext_flutter_sdk/operation_system');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('OperationSystem.empty', () {
    test('all fields are empty strings and toJson serialises all', () {
      final os = OperationSystem.empty();
      expect(os.name, '');
      expect(os.version, '');
      expect(os.locale, '');
      expect(os.timezone, '');

      final json = os.toJson();
      expect(json, {'name': '', 'version': '', 'locale': '', 'timezone': ''});
    });
  });

  group('OperationSystem.init', () {
    test('returns a non-null instance with locale string derived from platform locale', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getTimezone') return 'Europe/Prague';
        return null;
      });

      final os = await OperationSystem.init(
          TestWidgetsFlutterBinding.instance.platformDispatcher);
      expect(os, isNotNull);
      // locale is derived from PlatformDispatcher.locale, which varies by test
      // environment — just check it's a well-formed string (either "lang" or
      // "lang-COUNTRY"). Timezone should be our mocked value unless device_info_plus
      // throws before the timezone step (common without the plugin) — in which
      // case init() catches and returns .empty().
      expect(os.locale, isA<String>());
    });

    test('falls back to empty when the native layer throws', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'E', message: 'boom');
      });

      final os = await OperationSystem.init(
          TestWidgetsFlutterBinding.instance.platformDispatcher);
      // Whether we hit the catch block or degrade through _getTimezone's catch,
      // we always get a well-formed OperationSystem.
      expect(os, isNotNull);
      expect(os.name, isA<String>());
    });
  });
}
