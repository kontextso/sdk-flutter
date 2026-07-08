import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/services/sk_overlay_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = binding.defaultBinaryMessenger;
  const channel = MethodChannel('kontext_flutter_sdk/sk_overlay');

  final calls = <MethodCall>[];
  Object? mockReturn;
  Object? mockThrow;

  Skan skanWith([Map<String, dynamic> overrides = const {}]) => Skan.fromJson({
        'version': '4.0',
        'network': 'net.skadnetwork',
        'itunesItem': '123456789',
        'sourceApp': '987',
        'fidelities': [
          {'fidelity': 1, 'nonce': 'n1', 'signature': 's1', 'timestamp': '100'},
        ],
        ...overrides,
      })!;

  setUp(() {
    calls.clear();
    mockReturn = true;
    mockThrow = null;
    SKOverlayService.isIOS = () => true;
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
      SKOverlayService.isIOS = () => false;
      final result = await SKOverlayService.present(
        skan: skanWith(),
        position: SKOverlayPosition.bottom,
      );
      expect(result, isFalse);
      expect(calls, isEmpty);
    });

    test('returns false without a channel call when itunesItem is empty', () async {
      final result = await SKOverlayService.present(
        skan: skanWith({'itunesItem': ''}),
        position: SKOverlayPosition.bottom,
      );
      expect(result, isFalse);
      expect(calls, isEmpty);
    });

    test('invokes present with skan/position/dismissible and returns true', () async {
      final result = await SKOverlayService.present(
        skan: skanWith(),
        position: SKOverlayPosition.bottomRaised,
        dismissible: false,
      );
      expect(result, isTrue);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'present');
      final args = calls.single.arguments as Map;
      expect(args['position'], 'bottomRaised');
      expect(args['dismissible'], false);
      final skan = args['skan'] as Map;
      expect(skan['itunesItem'], '123456789');
      expect(skan['network'], 'net.skadnetwork');
    });

    test('defaults dismissible to true', () async {
      await SKOverlayService.present(skan: skanWith(), position: SKOverlayPosition.bottom);
      expect((calls.single.arguments as Map)['dismissible'], true);
    });

    test('returns false when the native side returns null', () async {
      mockReturn = null;
      final result = await SKOverlayService.present(skan: skanWith(), position: SKOverlayPosition.bottom);
      expect(result, isFalse);
    });

    test('returns false on an UNSUPPORTED_IOS PlatformException', () async {
      mockThrow = PlatformException(code: 'UNSUPPORTED_IOS');
      final result = await SKOverlayService.present(skan: skanWith(), position: SKOverlayPosition.bottom);
      expect(result, isFalse);
    });

    test('returns false on any other error', () async {
      mockThrow = PlatformException(code: 'BOOM');
      final result = await SKOverlayService.present(skan: skanWith(), position: SKOverlayPosition.bottom);
      expect(result, isFalse);
    });
  });

  group('dismiss', () {
    test('returns false and makes no channel call when not iOS', () async {
      SKOverlayService.isIOS = () => false;
      expect(await SKOverlayService.dismiss(), isFalse);
      expect(calls, isEmpty);
    });

    test('invokes dismiss and returns true', () async {
      final result = await SKOverlayService.dismiss();
      expect(result, isTrue);
      expect(calls.single.method, 'dismiss');
    });

    test('returns false when the native side returns non-true', () async {
      mockReturn = false;
      expect(await SKOverlayService.dismiss(), isFalse);
    });
  });
}
