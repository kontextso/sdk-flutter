import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kontext_flutter_sdk/src/widgets/utils/use_preload_ads.dart';

void main() {
  testWidgets('usePreloadAds resets when messages are empty', (tester) async {
    List? lastBids;
    bool? readyAssistant;
    bool? readyUser;

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
            messages: const [], // triggers the reset early-path
            isDisabled: false,
            vendorId: null,
            advertisingId: null,
            regulatory: null,
            character: null,
            variantId: null,
            iosAppStoreId: null,
            setBids: (bids) => lastBids = bids,
            setReadyForStreamingAssistant: (ready) => readyAssistant = ready,
            setReadyForStreamingUser: (ready) => readyUser = ready,
            onEvent: null,
          );
          return const SizedBox.shrink();
        },
      ),
    );

    await tester.pump();

    expect(lastBids, isEmpty);
    expect(readyAssistant, isFalse);
    expect(readyUser, isFalse);
  });
}
