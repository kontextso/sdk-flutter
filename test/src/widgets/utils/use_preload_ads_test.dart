import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/widgets/utils/use_preload_ads.dart';

void main() {
  testWidgets('usePreloadAds triggers preload and fails if no event arrives', (tester) async {
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
              setBids: (_) {},
              setReadyForStreamingAssistant: (_) {},
              setReadyForStreamingUser: (_) {},
              // Require at least one event; if the API never finishes, this never fires -> test FAILS.
              onEvent: expectAsync1((_) {}, count: 1, reason: 'Expected an ad event from preload'),
            );
            return const SizedBox.shrink();
          },
        ),
      );

      // Let the effects schedule the async work.
      await tester.pump();

      // Give some real time; the callback won’t fire -> test will fail due to unmet expectAsync1.
      await Future<void>.delayed(const Duration(seconds: 2));
    });
  });
}
