import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/app_info.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/device_app_info.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/device_audio.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/device_hardware.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/device_network.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/device_power.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/device_screen.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/operation_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceAppInfo.empty', () {
    test('aggregates empty instances of every sub-info', () {
      final d = DeviceAppInfo.empty();
      expect(d.appInfo, isA<AppInfo>());
      expect(d.os, isA<OperationSystem>());
      expect(d.hardware, isA<DeviceHardware>());
      expect(d.power, isA<DevicePower>());
      expect(d.network, isA<DeviceNetwork>());
      expect(d.appInfo.bundleId, '');
      expect(d.os.name, '');
    });
  });

  group('DeviceAppInfo.toJson', () {
    test('assembles the full JSON shape from all sub-infos', () {
      final d = DeviceAppInfo.empty();
      final json = d.toJson(
        screen: DeviceScreen.empty(),
        audio: DeviceAudio.empty(),
      );
      expect(json.keys, containsAll(['os', 'hardware', 'screen', 'power', 'audio', 'network']));
      expect(json['os'], isA<Map<String, dynamic>>());
      expect(json['hardware'], isA<Map<String, dynamic>>());
      expect(json['screen'], isA<Map<String, dynamic>>());
      expect(json['audio'], isA<Map<String, dynamic>>());
      expect(json['network'], isA<Map<String, dynamic>>());
    });
  });

  group('DeviceAppInfo.toJsonFresh', () {
    test('returns a Map with all expected top-level keys', () async {
      final d = DeviceAppInfo.empty();
      final json = await d.toJsonFresh();
      expect(json.keys, containsAll(['os', 'hardware', 'screen', 'power', 'audio', 'network']));
    });
  });

  group('DeviceAppInfo.init', () {
    test('returns a singleton-equivalent value on repeated calls', () async {
      final first = await DeviceAppInfo.init();
      final second = await DeviceAppInfo.init();
      // The same instance is returned on subsequent calls — a memoisation test.
      expect(identical(first, second), isTrue);
    });
  });
}
