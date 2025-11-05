import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kontext_flutter_sdk/src/widgets/utils/use_last_messages.dart';

void main() {
  testWidgets('useLastMessages handles empty messages correctly', (tester) async {
    bool? ready;
    String? lastAssistantId;
    String? lastUserId;
    String? relevantAssistantId;

    await tester.pumpWidget(
      HookBuilder(
        builder: (context) {
          useLastMessages(
            const [],
            lastUserMessageId: null,
            setReadyForStreamingAssistant: (v) => ready = v,
            setLastAssistantMessageId: (v) => lastAssistantId = v,
            setLastUserMessageId: (v) => lastUserId = v,
            setRelevantAssistantMessageId: (v) => relevantAssistantId = v,
          );
          return const SizedBox.shrink();
        },
      ),
    );

    expect(ready, isFalse);
    expect(lastAssistantId, isNull);
    expect(lastUserId, isNull);
    expect(relevantAssistantId, isNull);
  });
}
