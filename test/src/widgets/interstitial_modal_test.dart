import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  tearDown(() => InterstitialModal.closeModal());

  testWidgets(
    'Opens interstitial modal with correct URI and timeout',
    (tester) async {
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

      int openCount = 0;
      late String seenAdServerUrl;
      late Duration seenTimeout;

      void showInterstitial(
        BuildContext context, {
        required String adServerUrl,
        required Uri uri,
        required Duration initTimeout,
        required void Function(Json? data) onClickIframe,
        required void Function(Json? data) onEventIframe,
      }) {
        openCount++;
        seenAdServerUrl = adServerUrl;
        seenTimeout = initTimeout;
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

      final offstageFinder = find.descendant(of: find.byType(AdFormat), matching: find.byType(Offstage));

      onMessage(fakeController, 'init-iframe', null);
      await tester.pump();

      onMessage(fakeController, 'show-iframe', null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final offstage = tester.widget<Offstage>(offstageFinder);
      expect(offstage.offstage, isFalse);

      onMessage(fakeController, 'open-component-iframe', {
        'component': 'modal',
        'timeout': 2500,
      });
      await tester.pump();

      expect(openCount, 1);
      expect(seenAdServerUrl, 'https://example.com/ad');
      expect(seenTimeout, const Duration(milliseconds: 2500));
    },
  );

  testWidgets(
    'Interstitial modal closes if init-component-iframe not received before timeout',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox.shrink())));

      InterstitialModal.show(
        tester.element(find.byType(SizedBox).first),
        adServerUrl: 'https://example.com/ad',
        uri: Uri.parse('https://example.com/ad?code=test_code'),
        initTimeout: const Duration(milliseconds: 500),
        onClickIframe: (_) {},
        onEventIframe: (_) {},
        onOpenComponentIframe: (_, __) {},
        closeSKOverlay: () {},
        webviewBuilder: ({
          Key? key,
          required Uri uri,
          required List<String> allowedOrigins,
          required void Function(Json? data) onEventIframe,
          required OnMessageReceived onMessageReceived,
        }) {
          return FakeWebview(
            key: key,
            onEventIframe: onEventIframe,
            onMessageReceived: onMessageReceived,
          );
        },
      );

      await tester.pump();

      final opacityFinder = find.byType(AnimatedOpacity);
      expect(opacityFinder, findsOneWidget);
      final opacity = tester.widget<AnimatedOpacity>(opacityFinder);
      expect(opacity.opacity, equals(0.0));

      await tester.pump(const Duration(milliseconds: 400));
      expect(opacityFinder, findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(opacityFinder, findsNothing);
    },
  );

  testWidgets(
    'Interstitial modal visible on init-component-iframe and close on close-component-iframe',
    (tester) async {
      late OnMessageReceived onMsgModal;

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox.shrink())));

      InterstitialModal.show(
        tester.element(find.byType(SizedBox).first),
        adServerUrl: 'https://example.com/ad',
        uri: Uri.parse('https://example.com/ad?code=test_code'),
        initTimeout: const Duration(milliseconds: 500),
        onClickIframe: (_) {},
        onEventIframe: (_) {},
        onOpenComponentIframe: (_, __) {},
        closeSKOverlay: () {},
        webviewBuilder: ({
          Key? key,
          required Uri uri,
          required List<String> allowedOrigins,
          required void Function(Json? data) onEventIframe,
          required OnMessageReceived onMessageReceived,
        }) {
          onMsgModal = onMessageReceived;
          return FakeWebview(
            key: key,
            onEventIframe: onEventIframe,
            onMessageReceived: onMessageReceived,
          );
        },
      );

      await tester.pump();

      final opacityFinder = find.byType(AnimatedOpacity);
      expect(opacityFinder, findsOneWidget);
      AnimatedOpacity opacity = tester.widget<AnimatedOpacity>(opacityFinder);
      expect(opacity.opacity, equals(0.0));

      onMsgModal(fakeController, 'init-component-iframe', {'component': 'modal'});
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      opacity = tester.widget<AnimatedOpacity>(opacityFinder);
      expect(opacity.opacity, equals(1.0), reason: 'Visible after init-component-iframe');

      onMsgModal(fakeController, 'close-component-iframe', {'component': 'modal'});
      await tester.pumpAndSettle();
      expect(opacityFinder, findsNothing, reason: 'Disposed after close-component-iframe');
    },
  );

  testWidgets(
    'Interstitial modal visible on init-component-iframe and close on error-component-iframe',
    (tester) async {
      late OnMessageReceived onMsgModal;

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox.shrink())));

      InterstitialModal.show(
        tester.element(find.byType(SizedBox).first),
        adServerUrl: 'https://example.com/ad',
        uri: Uri.parse('https://example.com/ad?code=test_code'),
        initTimeout: const Duration(milliseconds: 500),
        onClickIframe: (_) {},
        onEventIframe: (_) {},
        onOpenComponentIframe: (_, __) {},
        closeSKOverlay: () {},
        webviewBuilder: ({
          Key? key,
          required Uri uri,
          required List<String> allowedOrigins,
          required void Function(Json? data) onEventIframe,
          required OnMessageReceived onMessageReceived,
        }) {
          onMsgModal = onMessageReceived;
          return FakeWebview(
            key: key,
            onEventIframe: onEventIframe,
            onMessageReceived: onMessageReceived,
          );
        },
      );

      await tester.pump();

      final opacityFinder = find.byType(AnimatedOpacity);
      expect(opacityFinder, findsOneWidget);
      AnimatedOpacity opacity = tester.widget<AnimatedOpacity>(opacityFinder);
      expect(opacity.opacity, equals(0.0));

      onMsgModal(fakeController, 'init-component-iframe', {'component': 'modal'});
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      opacity = tester.widget<AnimatedOpacity>(opacityFinder);
      expect(opacity.opacity, equals(1.0), reason: 'Visible after init-component-iframe');

      onMsgModal(fakeController, 'error-component-iframe', {'component': 'modal'});
      await tester.pumpAndSettle();
      expect(opacityFinder, findsNothing, reason: 'Disposed after error-component-iframe');
    },
  );

  testWidgets(
    'Forwards onEventIframe calls from interstitial modal',
    (tester) async {
      late void Function(Json? data) onEventIframeModal;
      Json? receivedData;

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox.shrink())));

      InterstitialModal.show(
        tester.element(find.byType(SizedBox).first),
        adServerUrl: 'https://example.com/ad',
        uri: Uri.parse('https://example.com/ad?code=test_code'),
        initTimeout: const Duration(milliseconds: 500),
        onClickIframe: (_) {},
        onEventIframe: (data) => receivedData = data,
        onOpenComponentIframe: (_, __) {},
        closeSKOverlay: () {},
        webviewBuilder: ({
          Key? key,
          required Uri uri,
          required List<String> allowedOrigins,
          required void Function(Json? data) onEventIframe,
          required OnMessageReceived onMessageReceived,
        }) {
          onEventIframeModal = onEventIframe;
          return FakeWebview(
            key: key,
            onEventIframe: onEventIframe,
            onMessageReceived: onMessageReceived,
          );
        },
      );

      await tester.pump();

      onEventIframeModal({'test_key': 'test_value'});
      await tester.pump();
      expect(receivedData!['test_key'], equals('test_value'));

      await tester.pump(const Duration(milliseconds: 500));
    },
  );

  testWidgets(
    'Calling show() while modal is already open closes previous modal',
    (tester) async {
      late OnMessageReceived firstModalOnMessage;
      late OnMessageReceived secondModalOnMessage;

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox.shrink())));

      InterstitialModal.show(
        tester.element(find.byType(SizedBox).first),
        adServerUrl: 'https://example.com/ad',
        uri: Uri.parse('https://example.com/ad?first=true'),
        initTimeout: const Duration(milliseconds: 1000),
        onClickIframe: (_) {},
        onEventIframe: (_) {},
        onOpenComponentIframe: (_, __) {},
        closeSKOverlay: () {},
        animatedOpacityKey: const Key('first_modal_opacity'),
        webviewBuilder: ({
          Key? key,
          required Uri uri,
          required List<String> allowedOrigins,
          required void Function(Json? data) onEventIframe,
          required OnMessageReceived onMessageReceived,
        }) {
          firstModalOnMessage = onMessageReceived;
          return FakeWebview(
            key: const Key('first_modal'),
            onEventIframe: onEventIframe,
            onMessageReceived: onMessageReceived,
          );
        },
      );

      await tester.pump();
      expect(find.byKey(const Key('first_modal')), findsOneWidget);

      firstModalOnMessage(fakeController, 'init-component-iframe', {'component': 'modal'});
      await tester.pump();

      final opacity1 = tester.widget<AnimatedOpacity>(find.byKey(const Key('first_modal_opacity')));
      expect(opacity1.opacity, equals(1.0));

      InterstitialModal.show(
        tester.element(find.byType(SizedBox).first),
        adServerUrl: 'https://example.com/ad',
        uri: Uri.parse('https://example.com/ad?second=true'),
        initTimeout: const Duration(milliseconds: 1000),
        onClickIframe: (_) {},
        onEventIframe: (_) {},
        onOpenComponentIframe: (_, __) {},
        closeSKOverlay: () {},
        animatedOpacityKey: const Key('second_modal_opacity'),
        webviewBuilder: ({
          Key? key,
          required Uri uri,
          required List<String> allowedOrigins,
          required void Function(Json? data) onEventIframe,
          required OnMessageReceived onMessageReceived,
        }) {
          secondModalOnMessage = onMessageReceived;
          return FakeWebview(
            key: const Key('second_modal'),
            onEventIframe: onEventIframe,
            onMessageReceived: onMessageReceived,
          );
        },
      );

      await tester.pump();
      expect(find.byKey(const Key('second_modal')), findsOneWidget);

      secondModalOnMessage(fakeController, 'init-component-iframe', {'component': 'modal'});
      await tester.pump();

      final opacity2 = tester.widget<AnimatedOpacity>(find.byKey(const Key('second_modal_opacity')));
      expect(opacity2.opacity, equals(1.0));

      expect(find.byKey(const Key('first_modal')), findsNothing);
      expect(find.byKey(const Key('second_modal')), findsOneWidget);

      tester.pump(const Duration(milliseconds: 1000));
    },
  );

  testWidgets(
    'init-component-iframe received just before timeout cancels timer',
    (tester) async {
      late OnMessageReceived onMsgModal;

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox.shrink())));

      InterstitialModal.show(
        tester.element(find.byType(SizedBox).first),
        adServerUrl: 'https://example.com/ad',
        uri: Uri.parse('https://example.com/ad?code=test_code'),
        initTimeout: const Duration(milliseconds: 500),
        onClickIframe: (_) {},
        onEventIframe: (_) {},
        onOpenComponentIframe: (_, __) {},
        closeSKOverlay: () {},
        webviewBuilder: ({
          Key? key,
          required Uri uri,
          required List<String> allowedOrigins,
          required void Function(Json? data) onEventIframe,
          required OnMessageReceived onMessageReceived,
        }) {
          onMsgModal = onMessageReceived;
          return FakeWebview(
            key: key,
            onEventIframe: onEventIframe,
            onMessageReceived: onMessageReceived,
          );
        },
      );

      await tester.pump(const Duration(milliseconds: 490));

      final opacityFinder = find.byType(AnimatedOpacity);
      expect(opacityFinder, findsOneWidget);

      onMsgModal(fakeController, 'init-component-iframe', {'component': 'modal'});
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 20));

      expect(opacityFinder, findsOneWidget);
      final opacity = tester.widget<AnimatedOpacity>(opacityFinder);
      expect(opacity.opacity, equals(1.0));
    },
  );

  testWidgets(
    'click-iframe forwards valid url payload via onClickIframe',
    (tester) async {
      late OnMessageReceived onMsgModal;

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox.shrink())));

      InterstitialModal.show(
        tester.element(find.byType(SizedBox).first),
        adServerUrl: 'https://example.com/ad',
        uri: Uri.parse('https://example.com/ad?code=test_code'),
        initTimeout: const Duration(milliseconds: 500),
        onClickIframe: (data) {
          final url = data?['url'];
          if (url is String) {
            opener.open(Uri.parse('https://example.com$url'));
          }
        },
        onEventIframe: (_) {},
        onOpenComponentIframe: (_, __) {},
        closeSKOverlay: () {},
        webviewBuilder: ({
          Key? key,
          required Uri uri,
          required List<String> allowedOrigins,
          required void Function(Json? data) onEventIframe,
          required OnMessageReceived onMessageReceived,
        }) {
          onMsgModal = onMessageReceived;
          return FakeWebview(
            key: key,
            onEventIframe: onEventIframe,
            onMessageReceived: onMessageReceived,
          );
        },
      );

      await tester.pump();

      onMsgModal(fakeController, 'click-iframe', {'url': '/test-path'});
      await tester.pump();

      final captured = verify(() => opener.open(captureAny(that: isA<Uri>()))).captured.single as Uri;
      expect(captured.toString(), equals('https://example.com/test-path'));
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(milliseconds: 1000));
    },
  );

  testWidgets(
    'click-iframe ignores non-string url payload via onClickIframe',
    (tester) async {
      late OnMessageReceived onMsgModal;

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox.shrink())));

      InterstitialModal.show(
        tester.element(find.byType(SizedBox).first),
        adServerUrl: 'https://example.com/ad',
        uri: Uri.parse('https://example.com/ad?code=test_code'),
        initTimeout: const Duration(milliseconds: 500),
        onClickIframe: (data) {
          final url = data?['url'];
          if (url is String) {
            opener.open(Uri.parse('https://example.com$url'));
          }
        },
        onEventIframe: (_) {},
        onOpenComponentIframe: (_, __) {},
        closeSKOverlay: () {},
        webviewBuilder: ({
          Key? key,
          required Uri uri,
          required List<String> allowedOrigins,
          required void Function(Json? data) onEventIframe,
          required OnMessageReceived onMessageReceived,
        }) {
          onMsgModal = onMessageReceived;
          return FakeWebview(
            key: key,
            onEventIframe: onEventIframe,
            onMessageReceived: onMessageReceived,
          );
        },
      );

      await tester.pump();

      onMsgModal(fakeController, 'click-iframe', {'url': 12345});
      await tester.pump();

      verifyNever(() => opener.open(any()));
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(milliseconds: 1000));
    },
  );

  testWidgets(
    'click-iframe ignores null data payload via onClickIframe',
    (tester) async {
      late OnMessageReceived onMsgModal;

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox.shrink())));

      InterstitialModal.show(
        tester.element(find.byType(SizedBox).first),
        adServerUrl: 'https://example.com/ad',
        uri: Uri.parse('https://example.com/ad?code=test_code'),
        initTimeout: const Duration(milliseconds: 500),
        onClickIframe: (data) {
          final url = data?['url'];
          if (url is String) {
            opener.open(Uri.parse('https://example.com$url'));
          }
        },
        onEventIframe: (_) {},
        onOpenComponentIframe: (_, __) {},
        closeSKOverlay: () {},
        webviewBuilder: ({
          Key? key,
          required Uri uri,
          required List<String> allowedOrigins,
          required void Function(Json? data) onEventIframe,
          required OnMessageReceived onMessageReceived,
        }) {
          onMsgModal = onMessageReceived;
          return FakeWebview(
            key: key,
            onEventIframe: onEventIframe,
            onMessageReceived: onMessageReceived,
          );
        },
      );

      await tester.pump();

      onMsgModal(fakeController, 'click-iframe', null);
      await tester.pump();

      verifyNever(() => opener.open(any()));
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(milliseconds: 1000));
    },
  );
}
