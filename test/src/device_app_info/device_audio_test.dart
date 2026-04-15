import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/device_audio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('kontext_flutter_sdk/device_audio');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('DeviceAudio.empty', () {
    test('fields are null and toJson emits an empty map', () {
      final audio = DeviceAudio.empty();
      expect(audio.volume, isNull);
      expect(audio.muted, isNull);
      expect(audio.outputPluggedIn, isNull);
      expect(audio.outputType, isNull);
      expect(audio.toJson(), isEmpty);
    });
  });

  group('DeviceAudio.init', () {
    test('decodes a full native response', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getAudioInfo') {
          return <String, Object?>{
            'volume': 0.75 * 100,
            'muted': false,
            'outputPluggedIn': true,
            'outputType': ['wired', 'bluetooth'],
          };
        }
        return null;
      });

      final audio = await DeviceAudio.init();

      expect(audio.volume, 75); // rounded from 75.0
      expect(audio.muted, false);
      expect(audio.outputPluggedIn, true);
      expect(audio.outputType, [AudioOutputType.wired, AudioOutputType.bluetooth]);
    });

    test('maps every AudioOutputType string value', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return <String, Object?>{
          'outputType': ['wired', 'hdmi', 'bluetooth', 'usb', 'other'],
        };
      });

      final audio = await DeviceAudio.init();
      expect(audio.outputType, [
        AudioOutputType.wired,
        AudioOutputType.hdmi,
        AudioOutputType.bluetooth,
        AudioOutputType.usb,
        AudioOutputType.other,
      ]);
    });

    test('unknown output types fall back to AudioOutputType.other', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return <String, Object?>{'outputType': ['carplay', 'unknown']};
      });

      final audio = await DeviceAudio.init();
      expect(audio.outputType, [AudioOutputType.other, AudioOutputType.other]);
    });

    test('returns an empty instance when the native call throws', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'E', message: 'boom');
      });

      final audio = await DeviceAudio.init();
      expect(audio.volume, isNull);
      expect(audio.muted, isNull);
      expect(audio.outputType, isNull);
    });

    test('returns an empty instance when the native call returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);

      final audio = await DeviceAudio.init();
      expect(audio.volume, isNull);
      expect(audio.outputType, isNull);
    });
  });

  group('DeviceAudio.toJson', () {
    test('omits null fields and serialises every provided one', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return <String, Object?>{
          'volume': 60,
          'muted': true,
          'outputPluggedIn': false,
          'outputType': ['wired'],
        };
      });

      final json = (await DeviceAudio.init()).toJson();
      expect(json['volume'], 60);
      expect(json['muted'], true);
      expect(json['outputPluggedIn'], false);
      expect(json['outputType'], ['wired']);
    });
  });
}
