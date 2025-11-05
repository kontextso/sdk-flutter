import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/widgets/utils/use_last_messages.dart';
import 'package:flutter_hooks/flutter_hooks.dart';


void main() {
  testWidgets('runs useLastMessages without crashing', (tester) async {
    await tester.pumpWidget(
      HookBuilder(
        builder: (context) {
          useLastMessages(
            const [], // empty list of messages
            lastUserMessageId: null,
            setReadyForStreamingAssistant: (_) {},
            setLastAssistantMessageId: (_) {},
            setLastUserMessageId: (_) {},
            setRelevantAssistantMessageId: (_) {},
          );
          return const SizedBox.shrink();
        },
      ),
    );

    expect(true, isTrue);
  });
}