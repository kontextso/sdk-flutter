import 'dart:convert' show jsonEncode;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kontext_flutter_sdk/src/models/character.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/widgets/utils/use_preload_ads.dart';
import 'package:kontext_flutter_sdk/src/services/api.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/models/ad_event.dart';

class MockHttp extends Mock implements http.Client {}

void mockPostResponse(MockHttp mock, dynamic response, [int statusCode = 200]) {
  when(() => mock.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).thenAnswer((_) async {
    final body = response is String ? response : jsonEncode(response);
    return http.Response(body, statusCode);
  });
}

void mockSuccessfulPreload(MockHttp mock) {
  mockPostResponse(
    mock,
    {
      'sessionId': 'sess-1',
      'remoteLogLevel': 'unknown',
      'bids': [
        {
          'bidId': 'id1',
          'code': 'code1'
        },
      ],
    },
  );
}

void mockNoFillPreload(MockHttp mock) {
  mockPostResponse(
    mock,
    {
      'sessionId': 'sess-1',
      'skip': true,
      'skipCode': 'unfilled_bid',
      'bids': [],
    },
  );
}

void mock500Error(MockHttp mock) {
  mockPostResponse(mock, 'Server error', 500);
}

void mockPermanentError(MockHttp mock) {
  mockPostResponse(
    mock,
    {
      'error': 'Request from this country is not allowed.',
      'errCode': 'geo-disabled',
      'status': 'geo-disabled',
      'permanent': true,
    },
  );
}


void main() {

  late MockHttp mock;

  setUp(() {
    registerFallbackValue(Uri.parse('https://dummy.local')); // keep here or in setUpAll
    mock = MockHttp();

    HttpClient.resetInstance();
    Api.resetInstance();
    HttpClient(baseUrl: 'https://api.test', client: mock);
  });

  testWidgets('run a successful preload flow with 1 user message', (tester) async {
    mockSuccessfulPreload(mock);

    List? lastBids;
    bool? readyAssistant;
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
              character: Character(
                id: 'char1',
                name: 'John Doe',
                avatarUrl: 'https://example.com/image.png',
              ),
              variantId: null,
              iosAppStoreId: null,
              setBids: (bids) => lastBids = bids,
              setReadyForStreamingAssistant: (ready) => readyAssistant = ready,
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
    expect(readyAssistant, isFalse);
    expect(events.length, 1);
    expect(events.first.type, AdEventType.adFilled);
  });

  testWidgets('skip preload if user message count is 0', (tester) async {
    mockSuccessfulPreload(mock);

    List? lastBids = [];
    bool? readyAssistant = false;
    final bool readyUser = false;
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
              character: Character(
                id: 'char1',
                name: 'John Doe',
                avatarUrl: 'https://example.com/image.png',
              ),
              variantId: null,
              iosAppStoreId: null,
              setBids: (bids) => lastBids = bids,
              setReadyForStreamingAssistant: (ready) => readyAssistant = ready,
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

  testWidgets('call preload even if disabled flag is set true, ignore the output', (tester) async {
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
              character: Character(
                id: 'char1',
                name: 'John Doe',
                avatarUrl: 'https://example.com/image.png',
              ),
              variantId: null,
              iosAppStoreId: null,
              setBids: (bids) => lastBids = bids,
              setReadyForStreamingAssistant: (ready) => {},
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

  testWidgets('handle unfilled bid (no fill) + skip code', (tester) async {
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
              isDisabled: false,
              vendorId: null,
              advertisingId: null,
              regulatory: null,
              character: Character(
                id: 'char1',
                name: 'John Doe',
                avatarUrl: 'https://example.com/image.png',
              ),
              variantId: null,
              iosAppStoreId: null,
              setBids: (bids) => lastBids = bids,
              setReadyForStreamingAssistant: (ready) => {},
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
    expect(events.length, 1);
    expect(events.first.type, AdEventType.adNoFill);
    expect(events.first.skipCode, AdEvent.skipCodeUnFilledBid);
  });

  testWidgets('handle 500 error (without errCode)', (tester) async {
    mock500Error(mock);

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
              isDisabled: false,
              vendorId: null,
              advertisingId: null,
              regulatory: null,
              character: Character(
                id: 'char1',
                name: 'John Doe',
                avatarUrl: 'https://example.com/image.png',
              ),
              variantId: null,
              iosAppStoreId: null,
              setBids: (bids) => lastBids = bids,
              setReadyForStreamingAssistant: (ready) => {},
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
    expect(events.length, 1);
    expect(events.first.type, AdEventType.adError);
  });
  
  testWidgets('dedupes: same user message triggers preload only once', (tester) async {
    // arrange
    mockSuccessfulPreload(mock);

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

    Future<void> pumpWithSameMessages() async {
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
              messages: messages, // same array, same last user message id
              isDisabled: false,
              vendorId: null,
              advertisingId: null,
              regulatory: null,
              character: Character(
                id: 'char1',
                name: 'John Doe',
                avatarUrl: 'https://example.com/image.png',
              ),
              variantId: null,
              iosAppStoreId: null,
              setBids: (_) {},
              setReadyForStreamingAssistant: (_) {},
              onEvent: (_) {},
            );
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pump(); // let effects run
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    await tester.runAsync(() async {
      await pumpWithSameMessages();
      await pumpWithSameMessages(); // re-render with the same last user message
    });

    // assert: HTTP POST called exactly once
    verify(() => mock.post(
      any(),
      headers: any(named: 'headers'),
      body: any(named: 'body'),
    )).called(1);
    verifyNoMoreInteractions(mock);
  });

  testWidgets('handle permament error (session disabled)', (tester) async {
    // arrange
    mockPermanentError(mock);

    final messages1 = <Message>[
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

    final messages2 = <Message>[
      ...messages1,
      Message(
        id: 'a2',
        role: MessageRole.assistant,
        content: 'Hello!',
        createdAt: DateTime.parse('2025-08-31T10:00:00Z'),
      ),
      Message(
        id: 'u2',
        role: MessageRole.user,
        content: 'Please preload again.',
        createdAt: DateTime.parse('2025-08-31T10:00:05Z'),
      ),
    ];

    Future<void> pumpWithMessages(List<Message> messages) async {
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
              isDisabled: false,
              vendorId: null,
              advertisingId: null,
              regulatory: null,
              character: Character(
                id: 'char1',
                name: 'John Doe',
                avatarUrl: 'https://example.com/image.png',
              ),
              variantId: null,
              iosAppStoreId: null,
              setBids: (_) {},
              setReadyForStreamingAssistant: (_) {},
              onEvent: (_) {},
            );
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pump(); // let effects run
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    await tester.runAsync(() async {
      await pumpWithMessages(messages1);
      await pumpWithMessages(messages2);
    });

    // assert: HTTP POST called exactly once
    verify(() => mock.post(
      any(),
      headers: any(named: 'headers'),
      body: any(named: 'body'),
    )).called(1);
    verifyNoMoreInteractions(mock);
  });

  testWidgets('handle unexpected error in usePreloadAds', (tester) async {
    mockSuccessfulPreload(mock);

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

    bool firstThrow = true;

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
              isDisabled: false,
              vendorId: null,
              advertisingId: null,
              regulatory: null,
              character: Character(
                id: 'char1',
                name: 'John Doe',
                avatarUrl: 'https://example.com/image.png',
              ),
              variantId: null,
              iosAppStoreId: null,
              setBids: (_) => {},
              setReadyForStreamingAssistant: (ready) => {},
              onEvent: (e) {
                if (firstThrow) {
                  firstThrow = false;
                  throw Exception('boom in onEvent');
                }
                events.add(e);
              },
            );
            return const SizedBox.shrink();
          },
        ),
      );

      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    expect(events.length, 1);
    expect(events.first.type, AdEventType.adError);
    expect(events.first.errCode, AdEvent.skipCodeRequestFailed);
  });

}

// TODO: parallel preloads