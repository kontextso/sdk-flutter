import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/device_network.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('kontext_flutter_sdk/device_network');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('DeviceNetwork.empty', () {
    test('all fields are null and toJson is empty', () {
      final n = DeviceNetwork.empty();
      expect(n.userAgent, isNull);
      expect(n.type, isNull);
      expect(n.detail, isNull);
      expect(n.carrier, isNull);
      expect(n.toJson(), isEmpty);
    });
  });

  group('DeviceNetwork.init', () {
    test('decodes a full native response', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return <String, Object?>{
          'userAgent': 'Mozilla/5.0 test',
          'type': 'cellular',
          'detail': 'lte',
          'carrier': 'T-Mobile',
        };
      });

      final n = await DeviceNetwork.init();
      expect(n.userAgent, 'Mozilla/5.0 test');
      expect(n.type, NetworkType.cellular);
      expect(n.detail, NetworkDetail.lte);
      expect(n.carrier, 'T-Mobile');
    });

    test('maps every NetworkType', () async {
      for (final (raw, expected) in [
        ('wifi', NetworkType.wifi),
        ('cellular', NetworkType.cellular),
        ('ethernet', NetworkType.ethernet),
        ('other', NetworkType.other),
      ]) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          return <String, Object?>{'type': raw};
        });
        final n = await DeviceNetwork.init();
        expect(n.type, expected, reason: raw);
      }
    });

    test('unknown NetworkType string yields null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return <String, Object?>{'type': 'not-a-type'};
      });
      final n = await DeviceNetwork.init();
      expect(n.type, isNull);
    });

    test('returns empty when native call throws', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'E');
      });
      final n = await DeviceNetwork.init();
      expect(n.userAgent, isNull);
      expect(n.type, isNull);
    });
  });

  group('DeviceNetwork.toJson', () {
    test('serialises enum names and omits null fields', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return <String, Object?>{
          'type': 'wifi',
          'detail': 'lte',
          'carrier': 'Vodafone',
        };
      });
      final json = (await DeviceNetwork.init()).toJson();
      expect(json['type'], 'wifi');
      expect(json['detail'], 'lte');
      expect(json['carrier'], 'Vodafone');
      expect(json.containsKey('userAgent'), isFalse);
    });
  });
}
