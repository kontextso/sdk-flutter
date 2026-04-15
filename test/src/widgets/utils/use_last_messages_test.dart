import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/widgets/utils/use_last_messages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Message user(String id) => Message(id: id, role: MessageRole.user, content: 'u', createdAt: DateTime.utc(2025));
  Message assistant(String id) =>
      Message(id: id, role: MessageRole.assistant, content: 'a', createdAt: DateTime.utc(2025));

  testWidgets('empty messages list resets every setter to null/false', (tester) async {
    final readyCalls = <bool>[];
    final assistantCalls = <String?>[];
    final userCalls = <String?>[];
    final relevantCalls = <String?>[];

    await tester.pumpWidget(HookBuilder(builder: (context) {
      useLastMessages(
        const [],
        lastUserMessageId: null,
        setReadyForStreamingAssistant: readyCalls.add,
        setLastAssistantMessageId: assistantCalls.add,
        setLastUserMessageId: userCalls.add,
        setRelevantAssistantMessageId: relevantCalls.add,
      );
      return const SizedBox.shrink();
    }));

    expect(readyCalls, [false]);
    expect(assistantCalls, [null]);
    expect(userCalls, [null]);
    expect(relevantCalls, [null]);
  });

  testWidgets('emits last user and last assistant ids, readyForStreaming=true for assistant-last', (tester) async {
    var ready = false;
    String? lastA, lastU, relevant;

    await tester.pumpWidget(HookBuilder(builder: (context) {
      useLastMessages(
        [user('u-1'), assistant('a-1')],
        lastUserMessageId: null,
        setReadyForStreamingAssistant: (v) => ready = v,
        setLastAssistantMessageId: (v) => lastA = v,
        setLastUserMessageId: (v) => lastU = v,
        setRelevantAssistantMessageId: (v) => relevant = v,
      );
      return const SizedBox.shrink();
    }));

    expect(ready, isTrue); // last message is assistant
    expect(lastA, 'a-1');
    expect(lastU, 'u-1');
    // last message is assistant → relevant unaffected (not reset).
    expect(relevant, isNull);
  });

  testWidgets('readyForStreaming=false when last message is user', (tester) async {
    var ready = true; // start true to observe it flipping to false

    await tester.pumpWidget(HookBuilder(builder: (context) {
      useLastMessages(
        [assistant('a-1'), user('u-1')],
        lastUserMessageId: null,
        setReadyForStreamingAssistant: (v) => ready = v,
        setLastAssistantMessageId: (_) {},
        setLastUserMessageId: (_) {},
        setRelevantAssistantMessageId: (_) {},
      );
      return const SizedBox.shrink();
    }));

    expect(ready, isFalse);
  });

  testWidgets('resets relevantAssistantMessageId when a new user message appears', (tester) async {
    final relevantCalls = <String?>[];

    await tester.pumpWidget(HookBuilder(builder: (context) {
      useLastMessages(
        [user('u-1')],
        // Simulate the previous-iteration id being different from the new one.
        lastUserMessageId: 'u-0',
        setReadyForStreamingAssistant: (_) {},
        setLastAssistantMessageId: (_) {},
        setLastUserMessageId: (_) {},
        setRelevantAssistantMessageId: relevantCalls.add,
      );
      return const SizedBox.shrink();
    }));

    // The reset only fires when last is a user AND the id changed.
    expect(relevantCalls, contains(null));
  });

  testWidgets('does NOT reset relevantAssistantMessageId when the last user id is the same', (tester) async {
    final relevantCalls = <String?>[];

    await tester.pumpWidget(HookBuilder(builder: (context) {
      useLastMessages(
        [user('u-1')],
        lastUserMessageId: 'u-1', // same as current last user
        setReadyForStreamingAssistant: (_) {},
        setLastAssistantMessageId: (_) {},
        setLastUserMessageId: (_) {},
        setRelevantAssistantMessageId: relevantCalls.add,
      );
      return const SizedBox.shrink();
    }));

    // Called 0 times — reset gate is gated on id change.
    expect(relevantCalls, isEmpty);
  });
}
