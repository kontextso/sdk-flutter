import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/device_power.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('kontext_flutter_sdk/device_power');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('DevicePower.empty', () {
    test('all fields are null and toJson is empty', () {
      final p = DevicePower.empty();
      expect(p.batteryLevel, isNull);
      expect(p.batteryState, isNull);
      expect(p.lowPowerMode, isNull);
      expect(p.toJson(), isEmpty);
    });
  });

  group('DevicePower.init', () {
    test('decodes a full native response', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return <String, Object?>{
          'level': 83.5,
          'state': 'charging',
          'lowPower': false,
        };
      });

      final p = await DevicePower.init(PlatformDispatcher.instance);
      expect(p.batteryLevel, 83.5);
      expect(p.batteryState, BatteryState.charging);
      expect(p.lowPowerMode, false);
    });

    test('maps all known battery states', () async {
      for (final (raw, expected) in [
        ('charging', BatteryState.charging),
        ('full', BatteryState.full),
        ('unplugged', BatteryState.unplugged),
      ]) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          return <String, Object?>{'state': raw};
        });
        final p = await DevicePower.init(PlatformDispatcher.instance);
        expect(p.batteryState, expected, reason: 'for state "$raw"');
      }
    });

    test('unknown state string maps to BatteryState.unknown', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return <String, Object?>{'state': 'something-weird'};
      });
      final p = await DevicePower.init(PlatformDispatcher.instance);
      expect(p.batteryState, BatteryState.unknown);
    });

    test('accepts integer battery level and widens to double', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return <String, Object?>{'level': 50};
      });
      final p = await DevicePower.init(PlatformDispatcher.instance);
      expect(p.batteryLevel, 50.0);
    });

    test('returns empty on PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'E', message: 'boom');
      });
      final p = await DevicePower.init(PlatformDispatcher.instance);
      expect(p.batteryLevel, isNull);
      expect(p.batteryState, isNull);
    });
  });

  group('DevicePower.toJson', () {
    test('omits null fields', () {
      final p = DevicePower.empty();
      expect(p.toJson(), isEmpty);
    });

    test('serialises battery state as the enum name', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return <String, Object?>{
          'level': 10,
          'state': 'full',
          'lowPower': true,
        };
      });
      final json = (await DevicePower.init(PlatformDispatcher.instance)).toJson();
      expect(json['batteryState'], 'full');
      expect(json['lowPowerMode'], true);
      expect(json['batteryLevel'], 10.0);
    });
  });
}

