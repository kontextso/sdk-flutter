import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart' show Skan;
import 'package:kontext_flutter_sdk/src/services/sk_overlay_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('kontext_flutter_sdk/sk_overlay');

  Skan skan({String itunesItem = '123456'}) => Skan(
        version: '4.0',
        network: 'example.com',
        itunesItem: itunesItem,
        sourceApp: '0',
      );

  setUp(() {
    SKOverlayService.isIOS = () => true;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    SKOverlayService.isIOS = () => true;
  });

  group('present', () {
    test('returns false on non-iOS without touching the channel', () async {
      SKOverlayService.isIOS = () => false;
      var channelCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        channelCalls++;
        return true;
      });

      final ok = await SKOverlayService.present(
        skan: skan(),
        position: SKOverlayPosition.bottom,
      );
      expect(ok, isFalse);
      expect(channelCalls, 0);
    });

    test('returns false when itunesItem is empty', () async {
      var called = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        called = true;
        return true;
      });
      final ok = await SKOverlayService.present(
        skan: skan(itunesItem: ''),
        position: SKOverlayPosition.bottom,
      );
      expect(ok, isFalse);
      expect(called, isFalse);
    });

    test('forwards skan, position and dismissible to native', () async {
      MethodCall? capturedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        capturedCall = call;
        return true;
      });

      final ok = await SKOverlayService.present(
        skan: skan(),
        position: SKOverlayPosition.bottomRaised,
        dismissible: false,
      );

      expect(ok, isTrue);
      expect(capturedCall?.method, 'present');
      final args = capturedCall!.arguments as Map;
      expect(args['position'], 'bottomRaised');
      expect(args['dismissible'], false);
      expect(args['skan'], isA<Map>());
    });

    test('returns false when native result is not true', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => false);
      expect(
        await SKOverlayService.present(skan: skan(), position: SKOverlayPosition.bottom),
        isFalse,
      );
    });

    test('swallows UNSUPPORTED_IOS platform error and returns false', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'UNSUPPORTED_IOS', message: 'iOS < 16');
      });
      expect(
        await SKOverlayService.present(skan: skan(), position: SKOverlayPosition.bottom),
        isFalse,
      );
    });

    test('swallows any platform exception and returns false', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'OTHER', message: 'boom');
      });
      expect(
        await SKOverlayService.present(skan: skan(), position: SKOverlayPosition.bottom),
        isFalse,
      );
    });
  });

  group('dismiss', () {
    test('returns false on non-iOS without touching the channel', () async {
      SKOverlayService.isIOS = () => false;
      var called = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        called = true;
        return true;
      });
      expect(await SKOverlayService.dismiss(), isFalse);
      expect(called, isFalse);
    });

    test('calls native dismiss and returns true when native returns true', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'dismiss');
        return true;
      });
      expect(await SKOverlayService.dismiss(), isTrue);
    });

    test('returns false on platform exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'E');
      });
      expect(await SKOverlayService.dismiss(), isFalse);
    });
  });
}
