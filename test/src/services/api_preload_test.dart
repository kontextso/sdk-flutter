import 'dart:convert' show jsonDecode;

import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart' show AdDisplayPosition;
import 'package:kontext_flutter_sdk/src/models/regulatory.dart';
import 'package:kontext_flutter_sdk/src/services/api.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/utils/types.dart' show Json;
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

class MockHttp extends Mock implements http.Client {}

void main() {
  late MockHttp mock;
  late Api api;

  setUp(() {
    registerFallbackValue(Uri.parse('https://dummy.local'));
    mock = MockHttp();

    HttpClient.resetInstance();
    Api.resetInstance();

    HttpClient(baseUrl: 'https://api.test', client: mock);
    api = Api();
  });

  test('correct request and response structure', () async {
    when(() => mock.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async {
      return http.Response(
        '{"sessionId": "123", "remoteLogLevel": "unknown", "bids": [{"bidId": "id1", "code": "code1", "adDisplayPosition": "afterAssistantMessage"}]}',
        200,
      );
    });

    final response = await api.preload(
      publisherToken: 'test-token',
      userId: 'user-123',
      conversationId: 'conv-456',
      messages: [],
      enabledPlacementCodes: [],
      isDisabled: false,
    );

    expect(response, isA<PreloadResponse>());
    expect(response.sessionId, '123');
    expect(response.remoteLogLevel, isNull);
    expect(response.bids.first.id, 'id1');
    expect(response.bids.first.code, 'code1');
    expect(response.bids.first.position, AdDisplayPosition.afterAssistantMessage);
    expect(response.statusCode, 200);

    verify(() => mock.post(
          Uri.parse('https://api.test/preload'),
          headers: {
            'Content-Type': 'application/json',
            'Kontextso-Publisher-Token': 'test-token',
            'Kontextso-Is-Disabled': '0',
          },
          body: any(
            named: 'body',
            that: predicate<String>((b) {
              final body = jsonDecode(b) as Json;
              return body['publisherToken'] == 'test-token' &&
                  body['userId'] == 'user-123' &&
                  body['conversationId'] == 'conv-456' &&
                  body['messages'] is List &&
                  body['enabledPlacementCodes'] is List;
            }),
          ),
        )).called(1);
  });

  test('invalid response structure', () async {
    when(() => mock.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async {
      return http.Response('{"invalid": "data"}', 200);
    });

    final response = await api.preload(
      publisherToken: 'test-token',
      userId: 'user-123',
      conversationId: 'conv-456',
      messages: [],
      enabledPlacementCodes: [],
      isDisabled: false,
    );

    expect(response, isA<PreloadResponse>());
    expect(response.sessionId, isNull);
    expect(response.bids, isEmpty);
  });

  test('http error in payload', () async {
    when(() => mock.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async {
      return http.Response('{"error":"Bad","errCode":"X1","permanent":true}', 400);
    });

    final response = await api.preload(
      publisherToken: 'test-token',
      userId: 'user-123',
      conversationId: 'conv-456',
      messages: [],
      enabledPlacementCodes: [],
      isDisabled: false,
    );

    expect(response, isA<PreloadResponse>());
    expect(response.sessionId, isNull);
    expect(response.bids, isEmpty);
    expect(response.statusCode, 400);
    expect(response.error, 'Bad');
    expect(response.errorCode, 'X1');
    expect(response.permanentError, true);
  });

  test('skip info in payload', () async {
    when(() => mock.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async {
      return http.Response('{"skip":true,"skipCode":"S123"}', 200);
    });

    final response = await api.preload(
      publisherToken: 'test-token',
      userId: 'user-123',
      conversationId: 'conv-456',
      messages: [],
      enabledPlacementCodes: [],
      isDisabled: false,
    );

    expect(response, isA<PreloadResponse>());
    expect(response.sessionId, isNull);
    expect(response.bids, isEmpty);
    expect(response.skip, true);
    expect(response.skipCode, 'S123');
  });

  test('exception -> safe fallback', () async {
    when(() => mock.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenThrow(Exception('Network error'));

    final response = await api.preload(
      publisherToken: 'test-token',
      userId: 'user-123',
      conversationId: 'conv-456',
      messages: [],
      enabledPlacementCodes: [],
      isDisabled: false,
    );

    expect(response, isA<PreloadResponse>());
    expect(response.sessionId, isNull);
    expect(response.bids, isEmpty);
  });

  test('optional ids are null-stripped', () async {
    when(() => mock.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async {
      return http.Response(
        '{"sessionId": "123", "bids": []}',
        200,
      );
    });

    await api.preload(
      publisherToken: 'test-token',
      userId: 'user-123',
      conversationId: 'conv-456',
      messages: [],
      enabledPlacementCodes: [],
      vendorId: '',
      variantId: '',
      advertisingId: '',
      regulatory: Regulatory(
        gdpr: 1,
        gdprConsent: '',
        usPrivacy: '',
        gpp: '',
        gppSid: [],
      ),
      isDisabled: false,
    );

    verify(() => mock.post(
          Uri.parse('https://api.test/preload'),
          headers: {
            'Content-Type': 'application/json',
            'Kontextso-Publisher-Token': 'test-token',
            'Kontextso-Is-Disabled': '0',
          },
          body: any(
            named: 'body',
            that: predicate<String>((b) {
              final body = jsonDecode(b) as Json;
              final regulatory = body['regulatory'] as Json;
              return !body.containsKey('vendorId') &&
                  !body.containsKey('variantId') &&
                  !body.containsKey('advertisingId') &&
                  regulatory['gdpr'] == 1 &&
                  !regulatory.containsKey('gdprConsent') &&
                  !regulatory.containsKey('usPrivacy') &&
                  !regulatory.containsKey('gpp') &&
                  regulatory['gppSid'] is List;
            }),
          ),
        )).called(1);
  });

  test('device provider throws -> falls back to empty device payload', () async {
    when(() => mock.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async {
      return http.Response('{"sessionId": "123", "bids": []}', 200);
    });

    api.deviceInfoProvider = ({String? iosAppStoreId}) async {
      throw Exception('Device info error');
    };

    await api.preload(
      publisherToken: 'test-token',
      userId: 'user-123',
      conversationId: 'conv-456',
      messages: [],
      enabledPlacementCodes: [],
      isDisabled: false,
    );

    verify(() => mock.post(
          Uri.parse('https://api.test/preload'),
          headers: {
            'Content-Type': 'application/json',
            'Kontextso-Publisher-Token': 'test-token',
            'Kontextso-Is-Disabled': '0',
          },
          body: any(
            named: 'body',
            that: predicate<String>((raw) {
              final body = jsonDecode(raw) as Map<String, dynamic>;
              final device = body['device'];
              if (device is! Map<String, dynamic>) return false;

              const requiredKeys = {
                'os',
                'hardware',
                'screen',
                'power',
                'audio',
                'network',
              };
              return requiredKeys.every(device.containsKey);
            }),
          ),
        )).called(1);
  });
}
