import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

void useLastMessages(
  List<Message> messages, {
  required String? lastUserMessageId,
  required ValueChanged<bool> setReadyForStreamingAssistant,
  required ValueChanged<String?> setLastAssistantMessageId,
  required ValueChanged<String?> setLastUserMessageId,
  required ValueChanged<String?> setRelevantAssistantMessageId,
}) {
  if (messages.isEmpty) {
    setReadyForStreamingAssistant(false);
    setLastAssistantMessageId(null);
    setLastUserMessageId(null);
    setRelevantAssistantMessageId(null);
    return;
  }

  final messageHash = messages.deepHash;

  useEffect(
    () {
      final lastUserMessage = messages.lastWhereOrElse((message) => message.isUser);
      setLastUserMessageId(lastUserMessage?.id);

      // If the last message is from the user, reset the relevant assistant message ID
      if (messages.last.isUser && lastUserMessage?.id != lastUserMessageId) {
        setRelevantAssistantMessageId(null);
      }

      final lastAssistantMessage = messages.lastWhereOrElse((message) => message.isAssistant);
      setLastAssistantMessageId(lastAssistantMessage?.id);

      // Ready for streaming if the last message is from the assistant
      setReadyForStreamingAssistant(messages.last.isAssistant);

      return null;
    },
    [messageHash],
  );
}
