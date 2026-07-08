import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/services/sk_store_product_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = binding.defaultBinaryMessenger;
  const channel = MethodChannel('kontext_flutter_sdk/sk_store_product');

  final calls = <MethodCall>[];
  Object? mockReturn;
  Object? mockThrow;

  Skan validSkan() => Skan.fromJson({
        'version': '4.0',
        'network': 'net.skadnetwork',
        'itunesItem': '123456789',
        'sourceApp': '987',
        'fidelities': [
          {'fidelity': 1, 'nonce': 'n1', 'signature': 's1', 'timestamp': '100'},
        ],
      })!;

  setUp(() {
    calls.clear();
    mockReturn = true;
    mockThrow = null;
    SKStoreProductService.isIOS = () => true;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (mockThrow != null) throw mockThrow!;
      return mockReturn;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('present', () {
    test('returns false and makes no channel call when not iOS', () async {
      SKStoreProductService.isIOS = () => false;
      expect(await SKStoreProductService.present(validSkan()), isFalse);
      expect(calls, isEmpty);
    });

    test('invokes present with skan.toJson() as the arguments and returns true', () async {
      final result = await SKStoreProductService.present(validSkan());
      expect(result, isTrue);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'present');
      // The arguments ARE the skan map directly (not nested under a "skan" key).
      final args = calls.single.arguments as Map;
      expect(args.containsKey('skan'), isFalse);
      expect(args['itunesItem'], '123456789');
      expect(args['version'], '4.0');
      expect(args['network'], 'net.skadnetwork');
      expect((args['fidelities'] as List).single, isA<Map>());
    });

    test('returns false when the native side returns null', () async {
      mockReturn = null;
      expect(await SKStoreProductService.present(validSkan()), isFalse);
    });

    test('returns false on error', () async {
      mockThrow = PlatformException(code: 'BOOM');
      expect(await SKStoreProductService.present(validSkan()), isFalse);
    });
  });

  group('dismiss', () {
    test('returns false and makes no channel call when not iOS', () async {
      SKStoreProductService.isIOS = () => false;
      expect(await SKStoreProductService.dismiss(), isFalse);
      expect(calls, isEmpty);
    });

    test('invokes dismiss and returns true', () async {
      expect(await SKStoreProductService.dismiss(), isTrue);
      expect(calls.single.method, 'dismiss');
    });

    test('returns false when the native side returns non-true', () async {
      mockReturn = 'nope';
      expect(await SKStoreProductService.dismiss(), isFalse);
    });
  });
}
