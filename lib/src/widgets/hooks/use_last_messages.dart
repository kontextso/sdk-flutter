import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

void useLastMessages(
  List<Message> messages, {
  required ValueChanged<bool> setReadyForStreamingAssistant,
  required ValueChanged<String?> setLastAssistantMessageId,
  required ValueChanged<String?> setLastUserMessageId,
}) {
  if (messages.isEmpty) {
    setReadyForStreamingAssistant(false);
    setLastAssistantMessageId(null);
    setLastUserMessageId(null);
    return;
  }

  final messageHash = messages.deepHash;

  useEffect(
    () {
      final lastUserMessage = messages.lastWhereOrElse((message) => message.isUser);
      setLastUserMessageId(lastUserMessage?.id);

      // Set the lastAssistantMessageId based on the last assistant message in the sequence
      final latestAssistantMessagesInSequence = messages.reversed.takeWhile((message) => message.isAssistant);
      final lastAssistantMessage = latestAssistantMessagesInSequence.lastOrNull;
      setLastAssistantMessageId(lastAssistantMessage?.id);

      // Ready for streaming if the last message is from the assistant
      setReadyForStreamingAssistant(messages.last.isAssistant);

      return null;
    },
    [messageHash],
  );
}
