import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/services/api.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
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
        '{"sessionId": "123", "bids": []}',
        200,
      );
    });

    final response = await api.preload(
      publisherToken: 'test-token',
      userId: 'user-123',
      conversationId: 'conv-456',
      messages: [],
      enabledPlacementCodes: [],
    );

    expect(response.sessionId, '123');
    expect(response.bids, isEmpty);
    expect(response.statusCode, 200);
  });
}
