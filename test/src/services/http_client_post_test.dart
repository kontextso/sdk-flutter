import 'dart:async' show TimeoutException;

import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

class MockHttp extends Mock implements http.Client {}

void main() {
  late MockHttp mock;
  late HttpClient client;

  setUp(() {
    registerFallbackValue(Uri.parse('https://dummy.local'));
    mock = MockHttp();
    HttpClient.resetInstance();
    client = HttpClient(baseUrl: 'https://api.test', client: mock);
  });

  group('post() timeout', () {
    test('throws TimeoutException on timeout', () async {
      when(() => mock.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return http.Response('{"ok": true}', 200);
      });

      expect(
        () => client.post(
          '/preload',
          timeout: const Duration(milliseconds: 10),
          body: {'key': 'value'},
        ),
        throwsA(isA<TimeoutException>()),
      );

      verify(() => mock.post(
            Uri.parse('https://api.test/preload'),
            headers: {'Content-Type': 'application/json'},
            body: '{"key":"value"}',
          )).called(1);
    });
  });

  group('post() JSON parsing', () {
    test('returns parsed Map for valid JSON object', () async {
      when(() => mock.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async {
        return http.Response('{"ok": true}', 200);
      });

      final result = await client.post('/preload', body: {'key': 'value'});

      expect(result.response.statusCode, 200);
      expect(result.data, {'ok': true});

      verify(() => mock.post(
            Uri.parse('https://api.test/preload'),
            headers: {'Content-Type': 'application/json'},
            body: '{"key":"value"}',
          )).called(1);
    });

    test('throw FormatException for invalid JSON', () async {
      when(() => mock.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async {
        return http.Response('Invalid JSON', 200);
      });

      expect(
        () => client.post('/preload', body: {'key': 'value'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('throw TypeError for non-Map JSON', () async {
      when(() => mock.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async {
        return http.Response('[]', 200);
      });

      expect(
        () => client.post('/preload', body: {'key': 'value'}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
