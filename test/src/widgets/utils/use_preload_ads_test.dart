import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kontext_flutter_sdk/src/widgets/utils/use_preload_ads.dart';

void main() {
  testWidgets('usePreloadAds runs without crashing', (tester) async {

    await tester.pumpWidget(
      HookBuilder(
        builder: (context) {
          usePreloadAds(
            context,
            publisherToken: 'test-token',
            conversationId: 'conv1',
            userId: 'user1',
            userEmail: null,
            enabledPlacementCodes: ['inlineAd'],
            messages: [],
            isDisabled: false,
            vendorId: null,
            advertisingId: null,
            regulatory: null,
            character: null,
            variantId: null,
            iosAppStoreId: null,
            setBids: (bids) => bids,
            setReadyForStreamingAssistant: (ready) => ready,
            setReadyForStreamingUser: (ready) => ready,
            onEvent: null,
          );
          return const SizedBox.shrink();
        },
      ),
    );

    expect(1, 1);
  });
}
