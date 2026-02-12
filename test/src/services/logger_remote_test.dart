import 'dart:convert' show jsonDecode;

import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart';
import 'package:kontext_flutter_sdk/src/utils/types.dart' show Json;
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

class MockHttp extends Mock implements http.Client {}

void main() {
  late MockHttp mock;

  setUp(() {
    registerFallbackValue(Uri.parse('https://dummy.local'));
    mock = MockHttp();

    HttpClient.resetInstance();
    Logger.resetInstance();

    HttpClient(baseUrl: 'https://api.test', client: mock);
  });

  test('posts to /log when level passes gate and remoteConfig set', () async {
    when(() => mock.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('{"ok": true}', 200));

    Logger.setRemoteConfig({'sdk': 'sdk-flutter', 'sdkVersion': '1.2.3'});
    Logger.setRemoteLogLevel(LogLevel.debug);
    Logger.info('Hello');

    await untilCalled(() => mock.post(
          Uri.parse('https://api.test/log'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ));

    verify(() => mock.post(
          any(that: predicate<Uri>((u) => u.path == '/log')),
          headers: any(named: 'headers'),
          body: any(
              named: 'body',
              that: predicate<String>((b) {
                final body = jsonDecode(b) as Json;
                return body['level'] == 'info' &&
                    body['message'] == 'Hello' &&
                    body['sdk'] == 'sdk-flutter' &&
                    body['sdkVersion'] == '1.2.3';
              })),
        )).called(1);
  });

  test('does not post when below remoteLevel', () async {
    when(() => mock.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('{"ok": true}', 200));

    Logger.setRemoteConfig({'sdk': 'sdk-flutter', 'sdkVersion': '1.2.3'});
    Logger.setRemoteLogLevel(LogLevel.warn);
    Logger.info('This should not be logged');

    verifyNever(() => mock.post(any(), headers: any(named: 'headers'), body: any(named: 'body')));
  });

  test('errorLocalOnly does not post to /log', () async {
    when(() => mock.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('{"ok": true}', 200));

    Logger.setRemoteConfig({'sdk': 'sdk-flutter', 'sdkVersion': '1.2.3'});
    Logger.setRemoteLogLevel(LogLevel.debug);
    Logger.errorLocalOnly('Local only error');

    await Future<void>.delayed(const Duration(milliseconds: 20));

    verifyNever(() => mock.post(any(), headers: any(named: 'headers'), body: any(named: 'body')));
  });

  test('errorRemoteOnly posts when remote gate allows', () async {
    when(() => mock.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('{"ok": true}', 200));

    Logger.setRemoteConfig({'sdk': 'sdk-flutter', 'sdkVersion': '1.2.3'});
    Logger.setRemoteLogLevel(LogLevel.error);
    Logger.errorRemoteOnly('Remote only error');

    await untilCalled(() => mock.post(
          Uri.parse('https://api.test/log'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ));

    verify(() => mock.post(
          any(that: predicate<Uri>((u) => u.path == '/log')),
          headers: any(named: 'headers'),
          body: any(
              named: 'body',
              that: predicate<String>((b) {
                final body = jsonDecode(b) as Json;
                return body['level'] == 'error' && body['message'] == 'Remote only error';
              })),
        )).called(1);
  });

  test('errorRemoteOnly respects remoteLevel gate', () async {
    when(() => mock.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('{"ok": true}', 200));

    Logger.setRemoteConfig({'sdk': 'sdk-flutter', 'sdkVersion': '1.2.3'});
    Logger.setRemoteLogLevel(LogLevel.silent);
    Logger.errorRemoteOnly('Should be gated');

    await Future<void>.delayed(const Duration(milliseconds: 20));

    verifyNever(() => mock.post(any(), headers: any(named: 'headers'), body: any(named: 'body')));
  });
}
