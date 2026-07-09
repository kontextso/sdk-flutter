import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/services/sk_ad_network_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = binding.defaultBinaryMessenger;
  const channel = MethodChannel('kontext_flutter_sdk/sk_ad_network');

  final calls = <MethodCall>[];
  Object? mockReturn;
  Object? mockThrow;
  Duration? mockDelay;

  Skan validSkan() => Skan.fromJson({
        'version': '4.0',
        'network': 'mp7rpxwdrx.skadnetwork',
        'itunesItem': '335187483',
        'sourceApp': '0',
        'sourceIdentifier': '39',
        'fidelities': [
          {'fidelity': 0, 'nonce': 'n0', 'signature': 's0', 'timestamp': '100'},
          {'fidelity': 1, 'nonce': 'n1', 'signature': 's1', 'timestamp': '101'},
        ],
      })!;

  setUp(() async {
    calls.clear();
    mockReturn = true;
    mockThrow = null;
    mockDelay = null;
    // Reset the static _impressionReady between tests without a channel call.
    SKAdNetwork.isIOS = () => false;
    await SKAdNetwork.dispose();
    SKAdNetwork.isIOS = () => true;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (mockDelay != null) await Future<void>.delayed(mockDelay!);
      if (mockThrow != null) throw mockThrow!;
      return mockReturn;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('initImpression', () {
    test('returns false and makes no channel call when not iOS', () async {
      SKAdNetwork.isIOS = () => false;
      expect(await SKAdNetwork.initImpression(validSkan()), isFalse);
      expect(calls, isEmpty);
    });

    test('passes the full skan payload with correct field names', () async {
      await SKAdNetwork.initImpression(validSkan());
      expect(calls.single.method, 'initImpression');
      final args = calls.single.arguments as Map;
      expect(args['version'], '4.0');
      expect(args['network'], 'mp7rpxwdrx.skadnetwork');
      expect(args['itunesItem'], '335187483');
      expect(args['sourceApp'], '0');
      expect(args['sourceIdentifier'], '39');
      final fidelities = (args['fidelities'] as List).cast<Map>();
      expect(fidelities, hasLength(2));
      expect(fidelities[0], {'fidelity': 0, 'signature': 's0', 'nonce': 'n0', 'timestamp': '100'});
      expect(fidelities[1], {'fidelity': 1, 'signature': 's1', 'nonce': 'n1', 'timestamp': '101'});
    });

    test('returns true on native success and arms the impression', () async {
      expect(await SKAdNetwork.initImpression(validSkan()), isTrue);
      await SKAdNetwork.startImpression();
      expect(calls.map((c) => c.method), ['initImpression', 'startImpression']);
    });

    test('returns false when native returns non-true and does not arm', () async {
      mockReturn = false;
      expect(await SKAdNetwork.initImpression(validSkan()), isFalse);
      await SKAdNetwork.startImpression();
      expect(calls.map((c) => c.method), ['initImpression']); // no startImpression
    });

    test('returns false on PlatformException without throwing', () async {
      mockThrow = PlatformException(code: 'MISSING_ARGUMENTS');
      expect(await SKAdNetwork.initImpression(validSkan()), isFalse);
      await SKAdNetwork.startImpression();
      expect(calls.map((c) => c.method), ['initImpression']); // not armed
    });

    test('resolves correctly even when the native side responds slowly', () async {
      // Guards the "Apple callback is slow" scenario: the await simply resolves late.
      mockDelay = const Duration(milliseconds: 50);
      expect(await SKAdNetwork.initImpression(validSkan()), isTrue);
    });
  });

  group('startImpression', () {
    test('is a no-op before a successful initImpression', () async {
      await SKAdNetwork.startImpression();
      expect(calls, isEmpty);
    });

    test('is a no-op when not iOS even if armed', () async {
      await SKAdNetwork.initImpression(validSkan());
      SKAdNetwork.isIOS = () => false;
      await SKAdNetwork.startImpression();
      expect(calls.map((c) => c.method), ['initImpression']);
    });

    test('swallows a native error without throwing', () async {
      await SKAdNetwork.initImpression(validSkan());
      mockThrow = PlatformException(code: 'SKAN_START_IMPRESSION_FAILED');
      await SKAdNetwork.startImpression(); // must not throw
      expect(calls.map((c) => c.method), ['initImpression', 'startImpression']);
    });

    test('completes even when the native side responds slowly', () async {
      await SKAdNetwork.initImpression(validSkan());
      mockDelay = const Duration(milliseconds: 50);
      await SKAdNetwork.startImpression().timeout(const Duration(seconds: 1));
      expect(calls.last.method, 'startImpression');
    });
  });

  group('endImpression', () {
    test('is a no-op before a successful initImpression', () async {
      await SKAdNetwork.endImpression();
      expect(calls, isEmpty);
    });

    test('invokes endImpression when armed', () async {
      await SKAdNetwork.initImpression(validSkan());
      await SKAdNetwork.endImpression();
      expect(calls.map((c) => c.method), ['initImpression', 'endImpression']);
    });

    test('swallows a native error without throwing', () async {
      await SKAdNetwork.initImpression(validSkan());
      mockThrow = PlatformException(code: 'SKAN_END_IMPRESSION_FAILED');
      await SKAdNetwork.endImpression(); // must not throw
    });
  });

  group('dispose', () {
    test('disarms the impression and calls native dispose', () async {
      await SKAdNetwork.initImpression(validSkan());
      await SKAdNetwork.dispose();
      await SKAdNetwork.startImpression(); // disarmed -> no call
      expect(calls.map((c) => c.method), ['initImpression', 'dispose']);
    });
  });

  test('full lifecycle calls native in order: init, start, end, dispose', () async {
    await SKAdNetwork.initImpression(validSkan());
    await SKAdNetwork.startImpression();
    await SKAdNetwork.endImpression();
    await SKAdNetwork.dispose();
    expect(calls.map((c) => c.method), ['initImpression', 'startImpression', 'endImpression', 'dispose']);
  });
}
