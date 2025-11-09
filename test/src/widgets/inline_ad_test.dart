import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/utils/types.dart' show Json;
import 'package:kontext_flutter_sdk/src/widgets/ad_format.dart';
import 'package:kontext_flutter_sdk/src/widgets/inline_ad.dart';
import 'package:kontext_flutter_sdk/src/widgets/interstitial_modal.dart' show InterstitialModal;
import 'package:kontext_flutter_sdk/src/widgets/kontext_webview.dart' show OnMessageReceived;
import 'package:mocktail/mocktail.dart';

import 'test_helpers.dart';

void main() {
  final fakeController = MockInAppWebViewController();

  tearDown(() => InterstitialModal.close());

  when(() => fakeController.evaluateJavascript(source: any(named: 'source'))).thenAnswer((_) async => null);

  testWidgets(
    'InlineAd becomes keepAlive when ad is active and stops when inactive',
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

      final scrollController = ScrollController();

      final key = GlobalKey<InlineAdState>();

      final isDisabledAndBidsNotifier = ValueNotifier<IsDisabledAndBids>((
        isDisabled: false,
        bids: [],
      ));
      final adsProvider = ValueListenableBuilder<IsDisabledAndBids>(
          valueListenable: isDisabledAndBidsNotifier,
          builder: (_, isDisabledAndBids, __) {
            return createDefaultProvider(
              isDisabled: isDisabledAndBids.isDisabled,
              bids: isDisabledAndBids.bids,
              resetAll: () => isDisabledAndBidsNotifier.value = (
                isDisabled: false,
                bids: [],
              ),
              child: MaterialApp(
                home: Scaffold(
                  body: ListView(
                    controller: scrollController,
                    children: [
                      InlineAd(
                        key: key,
                        code: 'test_code',
                        messageId: 'msg_1',
                        adFormatBuilder: (setKeepAlive) {
                          return AdFormat(
                            code: 'test_code',
                            messageId: 'msg_1',
                            onActiveChanged: setKeepAlive,
                            webviewBuilder: webviewBuilder,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          });

      await tester.pumpWidget(adsProvider);

      expect(key.currentState, isNotNull);
      final inlineAdState = key.currentState!;
      expect(inlineAdState.wantKeepAlive, isFalse);

      isDisabledAndBidsNotifier.value = (
        isDisabled: false,
        bids: [Bid(id: '1', code: 'test_code', position: AdDisplayPosition.afterAssistantMessage)],
      );
      await tester.pump();
      expect(inlineAdState.wantKeepAlive, isTrue);

      // Scroll the ad out of view - it should still be kept alive
      scrollController.jumpTo(1000);
      await tester.pump();
      expect(inlineAdState.wantKeepAlive, isTrue);

      isDisabledAndBidsNotifier.value = (
        isDisabled: true,
        bids: isDisabledAndBidsNotifier.value.bids,
      );
      await tester.pump();
      expect(inlineAdState.wantKeepAlive, isFalse);

      isDisabledAndBidsNotifier.value = (
        isDisabled: false,
        bids: isDisabledAndBidsNotifier.value.bids,
      );
      await tester.pump();
      expect(inlineAdState.wantKeepAlive, isTrue);

      onMessage(fakeController, 'init-iframe', null);
      await tester.pump();

      onMessage(fakeController, 'show-iframe', null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      onMessage(fakeController, 'error-iframe', null);
      await tester.pump();

      expect(inlineAdState.wantKeepAlive, isFalse);

      scrollController.dispose();
    },
  );
}
