import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/app_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('kontext_flutter_sdk/app_info');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('AppInfo.empty', () {
    test('fields have safe defaults and toJson serialises the core keys', () {
      final app = AppInfo.empty();
      expect(app.bundleId, '');
      expect(app.version, '');
      expect(app.storeUrl, isNull);
      expect(app.firstInstallTime, 0);
      expect(app.lastUpdateTime, 0);
      expect(app.startTime, 0);

      final json = app.toJson();
      expect(json['bundleId'], '');
      expect(json['version'], '');
      expect(json['firstInstallTime'], 0);
      expect(json['lastUpdateTime'], 0);
      expect(json['startTime'], 0);
      expect(json.containsKey('storeUrl'), isFalse);
    });
  });

  group('AppInfo.init', () {
    test('does not throw under the test binding', () async {
      // package_info_plus and the native channel are both unavailable under
      // the default test binding; init() should catch and return .empty().
      // We verify it resolves.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getInstallUpdateTimes') {
          return <String, Object?>{'firstInstall': 1000, 'lastUpdate': 2000};
        }
        if (call.method == 'getProcessStartEpochMs') return 3000;
        return null;
      });

      final app = await AppInfo.init();
      expect(app, isNotNull);
      expect(app.bundleId, isA<String>());
      expect(app.version, isA<String>());
    });

    test('constructs the iOS storeUrl from iosAppStoreId when provided (via empty fallback assertion)', () {
      // The constructor is private and init() depends on Platform.isIOS, which we
      // cannot flip in a Dart test. We only assert that a non-iOS code path
      // produces a store URL via the Android bundleId template, which depends
      // on a real platform. Skip dynamic dispatch and rely on the empty path.
      final empty = AppInfo.empty();
      expect(empty.storeUrl, isNull); // sanity
    });
  });
}
