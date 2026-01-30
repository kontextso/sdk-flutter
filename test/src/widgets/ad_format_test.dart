import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/ad_event.dart';
import 'package:kontext_flutter_sdk/src/utils/types.dart' show Json;
import 'package:kontext_flutter_sdk/src/widgets/ad_format.dart';
import 'package:kontext_flutter_sdk/src/widgets/interstitial_modal.dart' show InterstitialModal;
import 'package:kontext_flutter_sdk/src/widgets/kontext_webview.dart' show OnMessageReceived;
import 'package:mocktail/mocktail.dart';

import 'test_helpers.dart';

void main() {
  late MockInAppWebViewController fakeController;
  late MockBrowserOpener opener;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://dummy.local'));
  });
  setUp(() {
    fakeController = MockInAppWebViewController();
    opener = MockBrowserOpener();

    when(() => fakeController.evaluateJavascript(source: any(named: 'source'))).thenAnswer((_) async => null);
    when(() => opener.open(any())).thenAnswer((_) async => true);
  });

  tearDown(() => InterstitialModal.close());

  group('AdFormat disabled', () {
    testWidgets(
      'AdFormat is disabled when AdsProviderData.isDisabled is true',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createDefaultProvider(
            isDisabled: true,
            child: const AdFormat(
              code: 'test_code',
              messageId: 'msg_1',
              onActiveChanged: onActiveChanged,
            ),
          ),
        );

        final offstageFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(Offstage));
        expect(offstageFinder, findsNothing);
        final sizedBoxFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(SizedBox));
        expect(sizedBoxFinder, findsOneWidget);
      },
    );

    testWidgets(
      'AdFormat disabled when AdsProviderData is not available in context',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: AdFormat(
              code: 'test_code',
              messageId: 'msg_1',
              onActiveChanged: onActiveChanged,
            ),
          ),
        );

        final offstageFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(Offstage));
        expect(offstageFinder, findsNothing);
        final sizedBoxFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(SizedBox));
        expect(sizedBoxFinder, findsOneWidget);
      },
    );

    testWidgets(
      'AdFormat disabled when placement code is not in enabledPlacementCodes',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createDefaultProvider(
            child: const AdFormat(
              code: 'invalid_code',
              messageId: 'msg_1',
              onActiveChanged: onActiveChanged,
            ),
          ),
        );

        final offstageFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(Offstage));
        expect(offstageFinder, findsNothing);
        final sizedBoxFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(SizedBox));
        expect(sizedBoxFinder, findsOneWidget);
      },
    );

    testWidgets(
      'AdFormat disabled when no bid exists for the given code',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createDefaultProvider(
            child: const AdFormat(
              code: 'no_bid_code',
              messageId: 'msg_1',
              onActiveChanged: onActiveChanged,
            ),
          ),
        );

        final offstageFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(Offstage));
        expect(offstageFinder, findsNothing);
        final sizedBoxFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(SizedBox));
        expect(sizedBoxFinder, findsOneWidget);
      },
    );

    testWidgets(
      'AdFormat disabled when bid is after assistant message but relevantAssistantMessageId and lastAssistantMessageId do not match messageId',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createDefaultProvider(
            relevantAssistantMessageId: 'msg_3',
            lastAssistantMessageId: 'msg_4',
            child: const AdFormat(
              code: 'test_code',
              messageId: 'msg_2',
              onActiveChanged: onActiveChanged,
            ),
          ),
        );

        final offstageFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(Offstage));
        expect(offstageFinder, findsNothing);
        final sizedBoxFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(SizedBox));
        expect(sizedBoxFinder, findsOneWidget);
      },
    );

    testWidgets(
      'AdFormat disabled when bid is after assistant message but readyForStreamingAssistant is false',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createDefaultProvider(
            readyForStreamingAssistant: false,
            child: const AdFormat(
              code: 'test_code',
              messageId: 'msg_1',
              onActiveChanged: onActiveChanged,
            ),
          ),
        );

        final offstageFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(Offstage));
        expect(offstageFinder, findsNothing);
        final sizedBoxFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(SizedBox));
        expect(sizedBoxFinder, findsOneWidget);
      },
    );

    testWidgets(
      'AdFormat disabled when bid is after user message but lastUserMessageId does not match messageId',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createDefaultProvider(
            lastUserMessageId: 'msg_3',
            child: const AdFormat(
              code: 'test_code',
              messageId: 'msg_2',
              onActiveChanged: onActiveChanged,
            ),
          ),
        );

        final offstageFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(Offstage));
        expect(offstageFinder, findsNothing);
        final sizedBoxFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(SizedBox));
        expect(sizedBoxFinder, findsOneWidget);
      },
    );

    testWidgets(
      'AdFormat disabled when bid is after user message but readyForStreamingUser is false',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createDefaultProvider(
            bids: [Bid(id: '1', code: 'test_code', position: AdDisplayPosition.afterUserMessage)],
            lastUserMessageId: 'msg_1',
            readyForStreamingUser: false,
            child: const AdFormat(
              code: 'test_code',
              messageId: 'msg_1',
              onActiveChanged: onActiveChanged,
            ),
          ),
        );

        final offstageFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(Offstage));
        expect(offstageFinder, findsNothing);
        final sizedBoxFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(SizedBox));
        expect(sizedBoxFinder, findsOneWidget);
      },
    );

    testWidgets(
      'AdFormat disabled when inline URI cannot be built',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createDefaultProvider(
            adServerUrl: ':::invalid-url:::',
            child: const AdFormat(
              code: 'test_code',
              messageId: 'msg_1',
              onActiveChanged: onActiveChanged,
            ),
          ),
        );

        final offstageFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(Offstage));
        expect(offstageFinder, findsNothing);
        final sizedBoxFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(SizedBox));
        expect(sizedBoxFinder, findsOneWidget);
      },
    );
  });

  testWidgets(
    'AdFormat toggles visibility and resizes on iframe events',
    (WidgetTester tester) async {
      late OnMessageReceived onMessage;
      FakeWebview webviewBuilder({
        Key? key,
        required Uri uri,
        required List<String> allowedOrigins,
        required void Function(Json? data) onEventIframe,
        required OnMessageReceived onMessageReceived,
      }) {
        onMessage = onMessageReceived;
        return FakeWebview(
          key: key,
          onEventIframe: onEventIframe,
          onMessageReceived: onMessageReceived,
        );
      }

      await tester.pumpWidget(
        createDefaultProvider(
          child: AdFormat(
            code: 'test_code',
            messageId: 'msg_1',
            onActiveChanged: onActiveChanged,
            webviewBuilder: webviewBuilder,
          ),
        ),
      );

      final offstageFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(Offstage));
      expect(offstageFinder, findsOneWidget);
      Offstage offstage = tester.widget<Offstage>(offstageFinder);
      expect(offstage.offstage, isTrue);

      onMessage(fakeController, 'init-iframe', null);
      await tester.pump();

      offstage = tester.widget<Offstage>(offstageFinder);
      expect(offstage.offstage, isTrue);

      onMessage(fakeController, 'show-iframe', null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      offstage = tester.widget<Offstage>(offstageFinder);
      expect(offstage.offstage, isFalse);

      final containerFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(Container));
      final container = tester.widget<Container>(containerFinder.first);
      expect(container.constraints?.maxHeight, equals(0.0));

      onMessage(fakeController, 'resize-iframe', {'height': 250});
      await tester.pump();
      final resizedContainer = tester.widget<Container>(containerFinder.first);
      expect(resizedContainer.constraints?.maxHeight, equals(250.0));
    },
  );

  testWidgets(
    'AdFormat hides again when hide-iframe message is received',
    (WidgetTester tester) async {
      late OnMessageReceived onMessage;
      FakeWebview webviewBuilder({
        Key? key,
        required Uri uri,
        required List<String> allowedOrigins,
        required void Function(Json? data) onEventIframe,
        required OnMessageReceived onMessageReceived,
      }) {
        onMessage = onMessageReceived;
        return FakeWebview(
          key: key,
          onEventIframe: onEventIframe,
          onMessageReceived: onMessageReceived,
        );
      }

      await tester.pumpWidget(
        createDefaultProvider(
          child: AdFormat(
            code: 'test_code',
            messageId: 'msg_1',
            onActiveChanged: onActiveChanged,
            webviewBuilder: webviewBuilder,
          ),
        ),
      );

      final offstageFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(Offstage));

      onMessage(fakeController, 'init-iframe', null);
      await tester.pump();

      onMessage(fakeController, 'show-iframe', null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      Offstage offstage = tester.widget<Offstage>(offstageFinder);
      expect(offstage.offstage, isFalse);

      onMessage(fakeController, 'hide-iframe', null);
      await tester.pump();

      offstage = tester.widget<Offstage>(offstageFinder);
      expect(offstage.offstage, isTrue);
    },
  );

  testWidgets(
    'error-iframe message resets iframe state',
    (WidgetTester tester) async {
      late OnMessageReceived onMessage;
      FakeWebview webviewBuilder({
        Key? key,
        required Uri uri,
        required List<String> allowedOrigins,
        required void Function(Json? data) onEventIframe,
        required OnMessageReceived onMessageReceived,
      }) {
        onMessage = onMessageReceived;
        return FakeWebview(
          key: key,
          onEventIframe: onEventIframe,
          onMessageReceived: onMessageReceived,
        );
      }

      final bids = ValueNotifier<List<Bid>>([
        Bid(id: '1', code: 'test_code', position: AdDisplayPosition.afterAssistantMessage),
      ]);

      final adsProvider = ValueListenableBuilder<List<Bid>>(
          valueListenable: bids,
          builder: (_, bidList, __) {
            return createDefaultProvider(
              bids: bidList,
              resetAll: () => bids.value = [],
              child: AdFormat(
                code: 'test_code',
                messageId: 'msg_1',
                onActiveChanged: onActiveChanged,
                webviewBuilder: webviewBuilder,
              ),
            );
          });

      await tester.pumpWidget(adsProvider);

      final offstageFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(Offstage));

      onMessage(fakeController, 'init-iframe', null);
      await tester.pump();

      onMessage(fakeController, 'show-iframe', null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final offstage = tester.widget<Offstage>(offstageFinder);
      expect(offstage.offstage, isFalse);

      onMessage(fakeController, 'error-iframe', null);
      await tester.pump();

      expect(offstageFinder, findsNothing);
      final sizedBoxFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(SizedBox));
      expect(sizedBoxFinder, findsOneWidget);
    },
  );

  testWidgets(
    'update-dimensions-iframe posts periodically when iframe is visible',
    (WidgetTester tester) async {
      late OnMessageReceived onMessage;
      final dimensionCalls = <String>[];

      when(() => fakeController.evaluateJavascript(source: any(named: 'source'))).thenAnswer((invocation) async {
        final source = invocation.namedArguments[const Symbol('source')] as String;
        if (source.contains('update-dimensions-iframe')) {
          dimensionCalls.add(source);
        }
        return null;
      });

      FakeWebview webviewBuilder({
        Key? key,
        required Uri uri,
        required List<String> allowedOrigins,
        required void Function(Json? data) onEventIframe,
        required OnMessageReceived onMessageReceived,
      }) {
        onMessage = onMessageReceived;
        return FakeWebview(
          key: key,
          onEventIframe: onEventIframe,
          onMessageReceived: onMessageReceived,
        );
      }

      await tester.pumpWidget(
        createDefaultProvider(
          child: AdFormat(
            code: 'test_code',
            messageId: 'msg_1',
            onActiveChanged: onActiveChanged,
            webviewBuilder: webviewBuilder,
          ),
        ),
      );

      onMessage(fakeController, 'init-iframe', null);
      await tester.pump();

      onMessage(fakeController, 'show-iframe', null);
      await tester.pump();

      // Wait for initial delay + first tick
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 50));

      expect(dimensionCalls.length, greaterThan(0));

      final initialCount = dimensionCalls.length;

      // Wait for another tick
      await tester.pump(const Duration(milliseconds: 300));

      expect(dimensionCalls.length, greaterThan(initialCount));
    },
  );

  testWidgets(
    'Timer is cancelled when widget is disposed mid-update',
    (WidgetTester tester) async {
      late OnMessageReceived onMessage;
      final dimensionCalls = <String>[];

      when(() => fakeController.evaluateJavascript(source: any(named: 'source'))).thenAnswer((invocation) async {
        final source = invocation.namedArguments[const Symbol('source')] as String;
        if (source.contains('update-dimensions-iframe')) {
          dimensionCalls.add(source);
        }
        return null;
      });

      FakeWebview webviewBuilder({
        Key? key,
        required Uri uri,
        required List<String> allowedOrigins,
        required void Function(Json? data) onEventIframe,
        required OnMessageReceived onMessageReceived,
      }) {
        onMessage = onMessageReceived;
        return FakeWebview(
          key: key,
          onEventIframe: onEventIframe,
          onMessageReceived: onMessageReceived,
        );
      }

      final showWidget = ValueNotifier<bool>(true);

      await tester.pumpWidget(
        ValueListenableBuilder<bool>(
          valueListenable: showWidget,
          builder: (context, show, _) {
            if (!show) return const SizedBox.shrink();
            return createDefaultProvider(
              child: AdFormat(
                code: 'test_code',
                messageId: 'msg_1',
                onActiveChanged: onActiveChanged,
                webviewBuilder: webviewBuilder,
              ),
            );
          },
        ),
      );

      onMessage(fakeController, 'init-iframe', null);
      await tester.pump();

      onMessage(fakeController, 'show-iframe', null);
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 50));

      expect(dimensionCalls.length, greaterThan(0));
      final callsBeforeDispose = dimensionCalls.length;

      // Dispose the widget
      showWidget.value = false;
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Still the same number of calls
      expect(dimensionCalls.length, equals(callsBeforeDispose));
    },
  );

  testWidgets(
    'update-iframe sent when iframeLoaded.value is set to true',
    (WidgetTester tester) async {
      late OnMessageReceived onMessage;
      final updateIframeCalls = <String>[];

      when(() => fakeController.evaluateJavascript(source: any(named: 'source'))).thenAnswer((invocation) async {
        final source = invocation.namedArguments[const Symbol('source')] as String;
        if (source.contains('update-iframe')) {
          updateIframeCalls.add(source);
        }
        return null;
      });

      FakeWebview webviewBuilder({
        Key? key,
        required Uri uri,
        required List<String> allowedOrigins,
        required void Function(Json? data) onEventIframe,
        required OnMessageReceived onMessageReceived,
      }) {
        onMessage = onMessageReceived;
        return FakeWebview(
          key: key,
          onEventIframe: onEventIframe,
          onMessageReceived: onMessageReceived,
        );
      }

      await tester.pumpWidget(
        createDefaultProvider(
          child: AdFormat(
            code: 'test_code',
            messageId: 'msg_1',
            onActiveChanged: onActiveChanged,
            webviewBuilder: webviewBuilder,
          ),
        ),
      );

      onMessage(fakeController, 'init-iframe', null);
      await tester.pump();

      expect(updateIframeCalls.length, greaterThan(0));
    },
  );

  testWidgets(
    'AdEvent.adClicked is emitted with correct data',
    (WidgetTester tester) async {
      late OnMessageReceived onMessage;
      late void Function(Json? data) onEvent;
      final capturedEvents = <AdEvent>[];

      FakeWebview webviewBuilder({
        Key? key,
        required Uri uri,
        required List<String> allowedOrigins,
        required void Function(Json? data) onEventIframe,
        required OnMessageReceived onMessageReceived,
      }) {
        onMessage = onMessageReceived;
        onEvent = onEventIframe;
        return FakeWebview(
          key: key,
          onEventIframe: onEventIframe,
          onMessageReceived: onMessageReceived,
        );
      }

      await tester.pumpWidget(
        createDefaultProvider(
          onEvent: (event) => capturedEvents.add(event),
          child: AdFormat(
            code: 'test_code',
            messageId: 'msg_1',
            onActiveChanged: onActiveChanged,
            webviewBuilder: webviewBuilder,
          ),
        ),
      );

      onMessage(fakeController, 'init-iframe', null);
      await tester.pump();

      final eventData = {
        'name': 'ad.clicked',
        'code': 'test_code',
        'payload': {
          'url': '/test-path',
          'id': 'bid_123',
          'content': 'test_content',
          'messageId': 'msg_1',
        },
      };

      onEvent(eventData);
      await tester.pump();

      expect(capturedEvents.length, equals(1));
      final first = capturedEvents.first;
      expect(first.type, equals(AdEventType.adClicked));
      expect(first.code, equals('test_code'));
      expect(first.id, equals('bid_123'));
      expect(first.content, equals('test_content'));
      expect(first.messageId, equals('msg_1'));
      expect(first.url, contains('https://example.com/test-path'));
    },
  );

  testWidgets(
    'OnEventIframe with invalid payload is ignored',
    (WidgetTester tester) async {
      late OnMessageReceived onMessage;
      late void Function(Json? data) onEvent;
      final capturedEvents = <AdEvent>[];

      FakeWebview webviewBuilder({
        Key? key,
        required Uri uri,
        required List<String> allowedOrigins,
        required void Function(Json? data) onEventIframe,
        required OnMessageReceived onMessageReceived,
      }) {
        onMessage = onMessageReceived;
        onEvent = onEventIframe;
        return FakeWebview(
          key: key,
          onEventIframe: onEventIframe,
          onMessageReceived: onMessageReceived,
        );
      }

      await tester.pumpWidget(
        createDefaultProvider(
          onEvent: (event) => capturedEvents.add(event),
          child: AdFormat(
            code: 'test_code',
            messageId: 'msg_1',
            onActiveChanged: onActiveChanged,
            webviewBuilder: webviewBuilder,
          ),
        ),
      );

      onMessage(fakeController, 'init-iframe', null);
      await tester.pump();

      final eventData = {
        'name': 'ad.viewed',
        'code': 'test_code',
        'payload': {
          'id': false,
          'url': ['invalid'],
          'content': {'nested': 'object'},
        },
      };

      onEvent(eventData);
      await tester.pump();

      expect(capturedEvents.length, equals(0));
    },
  );

  testWidgets(
    'open-component-iframe with modal component opens InterstitialModal',
    (WidgetTester tester) async {
      late OnMessageReceived onMessage;
      Uri? capturedModalUri;
      String? capturedAdServerUrl;
      Duration? capturedTimeout;

      FakeWebview webviewBuilder({
        Key? key,
        required Uri uri,
        required List<String> allowedOrigins,
        required void Function(Json? data) onEventIframe,
        required OnMessageReceived onMessageReceived,
      }) {
        onMessage = onMessageReceived;
        return FakeWebview(
          key: key,
          onEventIframe: onEventIframe,
          onMessageReceived: onMessageReceived,
        );
      }

      void showInterstitial(
        BuildContext context, {
        required String adServerUrl,
        required Uri uri,
        required Duration initTimeout,
        required void Function(Json? data) onClickIframe,
        required void Function(Json? data) onEventIframe,
      }) {
        capturedModalUri = uri;
        capturedAdServerUrl = adServerUrl;
        capturedTimeout = initTimeout;
      }

      await tester.pumpWidget(
        createDefaultProvider(
          child: AdFormat(
            code: 'test_code',
            messageId: 'msg_1',
            onActiveChanged: onActiveChanged,
            webviewBuilder: webviewBuilder,
            showInterstitial: showInterstitial,
          ),
        ),
      );

      onMessage(fakeController, 'init-iframe', null);
      await tester.pump();

      onMessage(fakeController, 'open-component-iframe', {
        'component': 'modal',
        'timeout': 3000,
      });
      await tester.pump();

      expect(capturedModalUri, isNotNull);
      expect(capturedModalUri.toString(), contains('/api/modal/1'));
      expect(capturedAdServerUrl, equals('https://example.com/ad'));
      expect(capturedTimeout, equals(const Duration(milliseconds: 3000)));
    },
  );

  testWidgets(
    'open-component-iframe with modal uses default timeout when timeout is not provided',
    (WidgetTester tester) async {
      late OnMessageReceived onMessage;
      Duration? capturedTimeout;

      FakeWebview webviewBuilder({
        Key? key,
        required Uri uri,
        required List<String> allowedOrigins,
        required void Function(Json? data) onEventIframe,
        required OnMessageReceived onMessageReceived,
      }) {
        onMessage = onMessageReceived;
        return FakeWebview(
          key: key,
          onEventIframe: onEventIframe,
          onMessageReceived: onMessageReceived,
        );
      }

      void showInterstitial(
        BuildContext context, {
        required String adServerUrl,
        required Uri uri,
        required Duration initTimeout,
        required void Function(Json? data) onClickIframe,
        required void Function(Json? data) onEventIframe,
      }) {
        capturedTimeout = initTimeout;
      }

      await tester.pumpWidget(
        createDefaultProvider(
          child: AdFormat(
            code: 'test_code',
            messageId: 'msg_1',
            onActiveChanged: onActiveChanged,
            webviewBuilder: webviewBuilder,
            showInterstitial: showInterstitial,
          ),
        ),
      );

      onMessage(fakeController, 'init-iframe', null);
      await tester.pump();

      onMessage(fakeController, 'open-component-iframe', {
        'component': 'modal',
      });
      await tester.pump();

      expect(capturedTimeout, equals(AdFormat.defaultTimeout));
    },
  );

  testWidgets(
    'tap opens bid url',
    (WidgetTester tester) async {
      late OnMessageReceived onMessage;

      FakeWebview webviewBuilder({
        Key? key,
        required Uri uri,
        required List<String> allowedOrigins,
        required void Function(Json? data) onEventIframe,
        required OnMessageReceived onMessageReceived,
      }) {
        onMessage = onMessageReceived;
        return FakeWebview(
          key: key,
          onEventIframe: onEventIframe,
          onMessageReceived: onMessageReceived,
        );
      }

      await tester.pumpWidget(
        createDefaultProvider(
          bids: [
            Bid(
              id: '1',
              code: 'test_code',
              url: 'https://example.com/landing',
              position: AdDisplayPosition.afterAssistantMessage,
            ),
          ],
          child: AdFormat(
            code: 'test_code',
            messageId: 'msg_1',
            onActiveChanged: onActiveChanged,
            browserOpener: opener,
            webviewBuilder: webviewBuilder,
          ),
        ),
      );

      onMessage(fakeController, 'init-iframe', null);
      onMessage(fakeController, 'show-iframe', null);
      await tester.pump();

      await tester.tap(
        find.descendant(
          of: find.byType(AdFormat),
          matching: find.byType(GestureDetector),
        ),
      );
      await tester.pump();

      verify(() => opener.open(Uri.parse('https://example.com/landing'))).called(1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tap opens fallback redirect when bid url is missing',
    (WidgetTester tester) async {
      late OnMessageReceived onMessage;

      FakeWebview webviewBuilder({
        Key? key,
        required Uri uri,
        required List<String> allowedOrigins,
        required void Function(Json? data) onEventIframe,
        required OnMessageReceived onMessageReceived,
      }) {
        onMessage = onMessageReceived;
        return FakeWebview(
          key: key,
          onEventIframe: onEventIframe,
          onMessageReceived: onMessageReceived,
        );
      }

      await tester.pumpWidget(
        createDefaultProvider(
          child: AdFormat(
            code: 'test_code',
            messageId: 'msg_1',
            onActiveChanged: onActiveChanged,
            browserOpener: opener,
            webviewBuilder: webviewBuilder,
          ),
        ),
      );

      onMessage(fakeController, 'init-iframe', null);
      onMessage(fakeController, 'show-iframe', null);
      await tester.pump();

      await tester.tap(
        find.descendant(
          of: find.byType(AdFormat),
          matching: find.byType(GestureDetector),
        ),
      );
      await tester.pump();

      verify(
        () => opener.open(
          any(
            that: predicate<Uri>((uri) => uri.toString().contains('/ad/1/redirect')),
          ),
        ),
      ).called(1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'click-iframe does not open browser',
    (WidgetTester tester) async {
      late OnMessageReceived onMessage;

      FakeWebview webviewBuilder({
        Key? key,
        required Uri uri,
        required List<String> allowedOrigins,
        required void Function(Json? data) onEventIframe,
        required OnMessageReceived onMessageReceived,
      }) {
        onMessage = onMessageReceived;
        return FakeWebview(
          key: key,
          onEventIframe: onEventIframe,
          onMessageReceived: onMessageReceived,
        );
      }

      await tester.pumpWidget(
        createDefaultProvider(
          child: AdFormat(
            code: 'test_code',
            messageId: 'msg_1',
            onActiveChanged: onActiveChanged,
            browserOpener: opener,
            webviewBuilder: webviewBuilder,
          ),
        ),
      );

      onMessage(fakeController, 'init-iframe', null);
      await tester.pump();

      onMessage(fakeController, 'click-iframe', null);
      await tester.pump();

      verifyNever(() => opener.open(any()));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'open-component-iframe with invalid component is ignored',
    (WidgetTester tester) async {
      late OnMessageReceived onMessage;
      bool showInterstitialCalled = false;

      FakeWebview webviewBuilder({
        Key? key,
        required Uri uri,
        required List<String> allowedOrigins,
        required void Function(Json? data) onEventIframe,
        required OnMessageReceived onMessageReceived,
      }) {
        onMessage = onMessageReceived;
        return FakeWebview(
          key: key,
          onEventIframe: onEventIframe,
          onMessageReceived: onMessageReceived,
        );
      }

      void showInterstitial(
        BuildContext context, {
        required String adServerUrl,
        required Uri uri,
        required Duration initTimeout,
        required void Function(Json? data) onClickIframe,
        required void Function(Json? data) onEventIframe,
      }) {
        showInterstitialCalled = true;
      }

      await tester.pumpWidget(
        createDefaultProvider(
          child: AdFormat(
            code: 'test_code',
            messageId: 'msg_1',
            onActiveChanged: onActiveChanged,
            webviewBuilder: webviewBuilder,
            showInterstitial: showInterstitial,
          ),
        ),
      );

      onMessage(fakeController, 'init-iframe', null);
      await tester.pump();

      onMessage(fakeController, 'open-component-iframe', {
        'component': 'invalid_component',
        'timeout': 3000,
      });
      await tester.pump();

      expect(showInterstitialCalled, equals(false));
    },
  );

  testWidgets(
    'open-component-iframe with null data is ignored',
    (WidgetTester tester) async {
      late OnMessageReceived onMessage;
      bool showInterstitialCalled = false;

      FakeWebview webviewBuilder({
        Key? key,
        required Uri uri,
        required List<String> allowedOrigins,
        required void Function(Json? data) onEventIframe,
        required OnMessageReceived onMessageReceived,
      }) {
        onMessage = onMessageReceived;
        return FakeWebview(
          key: key,
          onEventIframe: onEventIframe,
          onMessageReceived: onMessageReceived,
        );
      }

      void showInterstitial(
        BuildContext context, {
        required String adServerUrl,
        required Uri uri,
        required Duration initTimeout,
        required void Function(Json? data) onClickIframe,
        required void Function(Json? data) onEventIframe,
      }) {
        showInterstitialCalled = true;
      }

      await tester.pumpWidget(
        createDefaultProvider(
          child: AdFormat(
            code: 'test_code',
            messageId: 'msg_1',
            onActiveChanged: onActiveChanged,
            webviewBuilder: webviewBuilder,
            showInterstitial: showInterstitial,
          ),
        ),
      );

      onMessage(fakeController, 'init-iframe', null);
      await tester.pump();

      onMessage(fakeController, 'open-component-iframe', null);
      await tester.pump();

      expect(showInterstitialCalled, equals(false));
    },
  );
}
