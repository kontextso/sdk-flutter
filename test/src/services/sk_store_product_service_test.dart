import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart' show Skan;
import 'package:kontext_flutter_sdk/src/services/sk_store_product_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('kontext_flutter_sdk/sk_store_product');

  Skan skan() => Skan(
        version: '4.0',
        network: 'example.com',
        itunesItem: '123',
        sourceApp: '0',
      );

  setUp(() {
    SKStoreProductService.isIOS = () => true;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    SKStoreProductService.isIOS = () => true;
  });

  group('present', () {
    test('returns false on non-iOS without touching the channel', () async {
      SKStoreProductService.isIOS = () => false;
      var called = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        called = true;
        return true;
      });
      expect(await SKStoreProductService.present(skan()), isFalse);
      expect(called, isFalse);
    });

    test('forwards skan JSON and returns true when native returns true', () async {
      MethodCall? captured;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        captured = call;
        return true;
      });

      expect(await SKStoreProductService.present(skan()), isTrue);
      expect(captured?.method, 'present');
      expect(captured?.arguments, isA<Map>());
    });

    test('returns false when native throws', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'E', message: 'boom');
      });
      expect(await SKStoreProductService.present(skan()), isFalse);
    });

    test('returns false when native result is not true', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);
      expect(await SKStoreProductService.present(skan()), isFalse);
    });
  });

  group('dismiss', () {
    test('returns false on non-iOS without touching the channel', () async {
      SKStoreProductService.isIOS = () => false;
      var called = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        called = true;
        return true;
      });
      expect(await SKStoreProductService.dismiss(), isFalse);
      expect(called, isFalse);
    });

    test('invokes dismiss and returns true on success', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'dismiss');
        return true;
      });
      expect(await SKStoreProductService.dismiss(), isTrue);
    });

    test('returns false on platform exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'E');
      });
      expect(await SKStoreProductService.dismiss(), isFalse);
    });
  });
}
