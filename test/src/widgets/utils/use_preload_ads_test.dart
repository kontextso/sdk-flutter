import 'dart:convert' show jsonDecode;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/widgets/utils/use_preload_ads.dart';
import 'package:kontext_flutter_sdk/src/services/api.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/utils/types.dart' show Json;
import 'package:kontext_flutter_sdk/src/models/ad_event.dart';

class MockHttp extends Mock implements http.Client {}

void mockSuccessfulPreload(MockHttp mock) {
  when(() => mock.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).thenAnswer((invocation) async {
    final body = jsonDecode(invocation.namedArguments[#body] as String) as Json;
    expect(body['publisherToken'], 'test-token');

    return http.Response(
      '''
      {
        "sessionId": "sess-1",
        "remoteLogLevel": "unknown",
        "bids": [
          {
            "bidId": "id1",
            "code": "code1",
            "adDisplayPosition": "afterAssistantMessage"
          }
        ]
      }
      ''',
      200,
    );
  });
}

void mockNoFillPreload(MockHttp mock) {
  when(() => mock.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).thenAnswer((invocation) async {
    return http.Response(
      '''
      {
        "sessionId": "sess-1",
        "skip": true,
        "skipCode": "unfilled_bid",
        "bids": []
      }
      ''',
      200,
    );  
  });
}

void main() {

  late MockHttp mock;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://dummy.local'));
    mock = MockHttp();
    HttpClient.resetInstance();
    Api.resetInstance();
    HttpClient(baseUrl: 'https://api.test', client: mock);
  });

  testWidgets('run a successful preload flow with 1 user message', (tester) async {
    mockSuccessfulPreload(mock);

    List? lastBids;
    bool? readyAssistant;
    bool? readyUser;
    final events = <AdEvent>[];

    final messages = <Message>[
      Message(
        id: 'a1',
        role: MessageRole.assistant,
        content: 'Hi!',
        createdAt: DateTime.parse('2025-08-31T10:00:00Z'),
      ),
      Message(
        id: 'u1',
        role: MessageRole.user, 
        content: 'Please preload.',
        createdAt: DateTime.parse('2025-08-31T10:00:05Z'),
      ),
    ];

    await tester.runAsync(() async {
      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            usePreloadAds(
              context,
              publisherToken: 'test-token',
              conversationId: 'conv1',
              userId: 'user1',
              userEmail: null,
              enabledPlacementCodes: const ['inlineAd'],
              messages: messages,
              isDisabled: false, // allow calling the API
              vendorId: null,
              advertisingId: null,
              regulatory: null,
              character: null,
              variantId: null,
              iosAppStoreId: null,
              setBids: (bids) => lastBids = bids,
              setReadyForStreamingAssistant: (ready) => readyAssistant = ready,
              setReadyForStreamingUser: (ready) => readyUser = ready,
              onEvent: (e) => events.add(e),
            );
            return const SizedBox.shrink();
          },
        ),
      );

      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    expect(lastBids, isNotNull);
    expect(lastBids, isNotEmpty);
    expect(readyUser, isTrue);
    expect(readyAssistant, isFalse);
    expect(events.length, 1);
    expect(events.first.type, AdEventType.adFilled);
  });

  testWidgets('ignore preload if user message count is 0', (tester) async {
    mockSuccessfulPreload(mock);

    List? lastBids = [];
    bool? readyAssistant = false;
    bool? readyUser = false;
    final events = <AdEvent>[];

    final messages = <Message>[
      Message(
        id: 'a1',
        role: MessageRole.assistant,
        content: 'Hi!',
        createdAt: DateTime.parse('2025-08-31T10:00:00Z'),
      ),
      Message(
        id: 'a2',
        role: MessageRole.assistant, 
        content: 'Hello!',
        createdAt: DateTime.parse('2025-08-31T10:00:05Z'),
      ),
    ];
  
    await tester.runAsync(() async {
      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            usePreloadAds(
              context,
              publisherToken: 'test-token',
              conversationId: 'conv1',
              userId: 'user1',
              userEmail: null,
              enabledPlacementCodes: const ['inlineAd'],
              messages: messages,
              isDisabled: false, // allow calling the API
              vendorId: null,
              advertisingId: null,
              regulatory: null,
              character: null,
              variantId: null,
              iosAppStoreId: null,
              setBids: (bids) => lastBids = bids,
              setReadyForStreamingAssistant: (ready) => readyAssistant = ready,
              setReadyForStreamingUser: (ready) => readyUser = ready,
              onEvent: (e) => events.add(e),
            );
            return const SizedBox.shrink();
          },
        ),
      );

      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    expect(lastBids, isEmpty);
    expect(readyUser, isFalse);
    expect(readyAssistant, isFalse);
    expect(events.length, 0);
  });

  testWidgets('call preload if disabled flag is set true, ignore the output', (tester) async {
      mockNoFillPreload(mock);

    List? lastBids = [];
    final events = <AdEvent>[];

    final messages = <Message>[
      Message(
        id: 'a1',
        role: MessageRole.assistant,
        content: 'Hi!',
        createdAt: DateTime.parse('2025-08-31T10:00:00Z'),
      ),
      Message(
        id: 'u1',
        role: MessageRole.user, 
        content: 'Please preload.',
        createdAt: DateTime.parse('2025-08-31T10:00:05Z'),
      ),
    ];

    await tester.runAsync(() async {
      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            usePreloadAds(
              context,
              publisherToken: 'test-token',
              conversationId: 'conv1',
              userId: 'user1',
              userEmail: null,
              enabledPlacementCodes: const ['inlineAd'],
              messages: messages,
              isDisabled: true,
              vendorId: null,
              advertisingId: null,
              regulatory: null,
              character: null,
              variantId: null,
              iosAppStoreId: null,
              setBids: (bids) => lastBids = bids,
              setReadyForStreamingAssistant: (ready) => {},
              setReadyForStreamingUser: (ready) => {},
              onEvent: (e) => events.add(e),
            );
            return const SizedBox.shrink();
          },
        ),
      );

      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    expect(lastBids, []);
    expect(events.length, 0);
  });
  
  
  // TODO: ignore if user messages count is not changed
  // TODO: session disabled
  // TODO: parallel preloads
  // TODO: error handling
  // TODO: skip
  // TODO: permanent error
  // TODO: unfilled bid

}
