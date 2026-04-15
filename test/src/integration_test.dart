import 'dart:convert' show jsonDecode;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/character.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/models/regulatory.dart';
import 'package:kontext_flutter_sdk/src/services/advertising_id_service.dart';
import 'package:kontext_flutter_sdk/src/services/api.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/utils/types.dart' show Json;
import 'package:mocktail/mocktail.dart';

/// Integration tests that drive the real Api → HttpClient → http.Client
/// pipeline end-to-end, with only the outermost http.Client mocked. This
/// covers the full pre-load flow that publishers depend on:
///   - TCF consent lookup,
///   - IFA resolution,
///   - body assembly and header wiring,
///   - response decoding,
///   - error-path fallback.
class MockHttp extends Mock implements http.Client {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHttp httpMock;

  const tcfChannel = MethodChannel('kontext_flutter_sdk/transparency_consent_framework');

  setUp(() {
    registerFallbackValue(Uri.parse('https://dummy.local'));
    httpMock = MockHttp();

    HttpClient.resetInstance();
    Api.resetInstance();

    AdvertisingIdService.resetForTesting();
    AdvertisingIdService.isIOSProvider = () => false;
    AdvertisingIdService.idfvProvider = () async => null;
    AdvertisingIdService.advertisingIdProvider = () async => null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(tcfChannel, (_) async => null);

    HttpClient(baseUrl: 'https://api.integration.test', client: httpMock);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(tcfChannel, null);
    AdvertisingIdService.resetForTesting();
    HttpClient.resetInstance();
    Api.resetInstance();
  });

  Api buildApi() {
    final api = Api();
    // Avoid platform-channel lookups for device info during tests.
    api.deviceInfoProvider = ({String? iosAppStoreId}) async {
      throw Exception('skip device info in tests');
    };
    return api;
  }

  group('integration: full preload pipeline', () {
    test('happy path POSTs to /preload with correct token + body and decodes bids', () async {
      when(() => httpMock.post(any(), headers: any(named: 'headers'), body: any(named: 'body'))).thenAnswer(
        (_) async => http.Response(
          '{"sessionId": "s-int-1", "bids": [{"bidId": "b-1", "code": "inlineAd", "adDisplayPosition": "afterAssistantMessage"}]}',
          200,
        ),
      );

      final api = buildApi();
      final response = await api.preload(
        publisherToken: 'pub-tok-int',
        userId: 'u-int',
        conversationId: 'c-int',
        messages: [Message(id: 'u-1', role: MessageRole.user, content: 'Hi', createdAt: DateTime.utc(2025))],
        enabledPlacementCodes: const ['inlineAd'],
        isDisabled: false,
      );

      expect(response.sessionId, 's-int-1');
      expect(response.bids, isNotEmpty);
      expect(response.bids.first.code, 'inlineAd');

      // Verify wire contract.
      final captured = verify(() => httpMock.post(
            captureAny(),
            headers: captureAny(named: 'headers'),
            body: captureAny(named: 'body'),
          )).captured;
      expect(captured, isNotEmpty);
      final url = captured[captured.length - 3] as Uri;
      final headers = captured[captured.length - 2] as Map<String, String>;
      final body = jsonDecode(captured.last as String) as Json;

      expect(url.toString(), 'https://api.integration.test/preload');
      expect(headers['Kontextso-Publisher-Token'], 'pub-tok-int');
      expect(headers['Kontextso-Is-Disabled'], '0');
      expect(body['publisherToken'], 'pub-tok-int');
      expect(body['conversationId'], 'c-int');
      expect(body['userId'], 'u-int');
      expect(body['enabledPlacementCodes'], ['inlineAd']);
      expect(body['messages'], isA<List>());
    });

    test('isDisabled=true is forwarded as Kontextso-Is-Disabled: 1', () async {
      when(() => httpMock.post(any(), headers: any(named: 'headers'), body: any(named: 'body'))).thenAnswer(
        (_) async => http.Response('{"sessionId": "s", "bids": []}', 200),
      );

      await buildApi().preload(
        publisherToken: 'tok',
        userId: 'u',
        conversationId: 'c',
        messages: const [],
        enabledPlacementCodes: const [],
        isDisabled: true,
      );

      final headers = verify(() => httpMock.post(any(),
              headers: captureAny(named: 'headers'), body: any(named: 'body')))
          .captured
          .last as Map<String, String>;
      expect(headers['Kontextso-Is-Disabled'], '1');
    });

    test('skip response is propagated through to PreloadResponse', () async {
      when(() => httpMock.post(any(), headers: any(named: 'headers'), body: any(named: 'body'))).thenAnswer(
        (_) async => http.Response('{"sessionId": "s", "skip": true, "skipCode": "rate_limit"}', 200),
      );

      final response = await buildApi().preload(
        publisherToken: 'tok',
        userId: 'u',
        conversationId: 'c',
        messages: const [],
        enabledPlacementCodes: const [],
        isDisabled: false,
      );
      expect(response.skip, isTrue);
      expect(response.skipCode, 'rate_limit');
      expect(response.bids, isEmpty);
    });

    test('network throw is swallowed into an empty PreloadResponse', () async {
      when(() => httpMock.post(any(), headers: any(named: 'headers'), body: any(named: 'body'))).thenThrow(
        Exception('network error'),
      );

      final response = await buildApi().preload(
        publisherToken: 'tok',
        userId: 'u',
        conversationId: 'c',
        messages: const [],
        enabledPlacementCodes: const [],
        isDisabled: false,
      );
      expect(response.sessionId, isNull);
      expect(response.bids, isEmpty);
    });

    test('5xx response surfaces statusCode', () async {
      when(() => httpMock.post(any(), headers: any(named: 'headers'), body: any(named: 'body'))).thenAnswer(
        (_) async => http.Response('{}', 503),
      );

      final response = await buildApi().preload(
        publisherToken: 'tok',
        userId: 'u',
        conversationId: 'c',
        messages: const [],
        enabledPlacementCodes: const [],
        isDisabled: false,
      );
      expect(response.statusCode, 503);
    });

    test('TCF data from the platform channel is merged into regulatory', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(tcfChannel, (call) async {
        return <String, Object?>{'gdprApplies': 1, 'tcString': 'CONSENT'};
      });

      when(() => httpMock.post(any(), headers: any(named: 'headers'), body: any(named: 'body'))).thenAnswer(
        (_) async => http.Response('{"sessionId": "s", "bids": []}', 200),
      );

      await buildApi().preload(
        publisherToken: 'tok',
        userId: 'u',
        conversationId: 'c',
        messages: const [],
        enabledPlacementCodes: const [],
        regulatory: const Regulatory(coppa: 1),
        isDisabled: false,
      );

      final body = jsonDecode(
        verify(() => httpMock.post(any(), headers: any(named: 'headers'), body: captureAny(named: 'body'))).captured.last
            as String,
      ) as Json;
      final regulatory = body['regulatory'] as Json;
      expect(regulatory['gdpr'], 1);
      expect(regulatory['gdprConsent'], 'CONSENT');
      expect(regulatory['coppa'], 1); // publisher-provided
    });

    test('character, variantId and userEmail are forwarded when provided', () async {
      when(() => httpMock.post(any(), headers: any(named: 'headers'), body: any(named: 'body'))).thenAnswer(
        (_) async => http.Response('{"sessionId": "s", "bids": []}', 200),
      );

      await buildApi().preload(
        publisherToken: 'tok',
        userId: 'u',
        conversationId: 'c',
        messages: const [],
        enabledPlacementCodes: const [],
        character: Character(id: 'c-1', name: 'Max'),
        variantId: 'v-1',
        userEmail: 'x@y.z',
        isDisabled: false,
      );

      final body = jsonDecode(
        verify(() => httpMock.post(any(), headers: any(named: 'headers'), body: captureAny(named: 'body'))).captured.last
            as String,
      ) as Json;
      expect(body['character'], isA<Map>());
      expect((body['character'] as Json)['id'], 'c-1');
      expect(body['variantId'], 'v-1');
      expect(body['userEmail'], 'x@y.z');
    });

    test('bids survive a second preload with previously returned sessionId', () async {
      // 1st response — gives us a sessionId.
      when(() => httpMock.post(any(), headers: any(named: 'headers'), body: any(named: 'body'))).thenAnswer(
        (_) async => http.Response('{"sessionId": "sess-A", "bids": []}', 200),
      );

      final api = buildApi();
      final r1 = await api.preload(
        publisherToken: 'tok',
        userId: 'u',
        conversationId: 'c',
        messages: const [],
        enabledPlacementCodes: const [],
        isDisabled: false,
      );
      expect(r1.sessionId, 'sess-A');

      // 2nd preload with sessionId passed in.
      when(() => httpMock.post(any(), headers: any(named: 'headers'), body: any(named: 'body'))).thenAnswer(
        (_) async => http.Response(
          '{"sessionId": "sess-A", "bids": [{"bidId": "b-1", "code": "inlineAd", "adDisplayPosition": "afterAssistantMessage"}]}',
          200,
        ),
      );

      final r2 = await api.preload(
        publisherToken: 'tok',
        userId: 'u',
        conversationId: 'c',
        messages: const [],
        enabledPlacementCodes: const ['inlineAd'],
        sessionId: 'sess-A',
        isDisabled: false,
      );
      expect(r2.bids.first.code, 'inlineAd');

      // Last body should carry the sessionId back up.
      final body = jsonDecode(
        verify(() => httpMock.post(any(), headers: any(named: 'headers'), body: captureAny(named: 'body'))).captured.last
            as String,
      ) as Json;
      expect(body['sessionId'], 'sess-A');
    });
  });
}
