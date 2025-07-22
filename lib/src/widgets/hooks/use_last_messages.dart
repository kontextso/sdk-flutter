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
      final lastAssistantMessage = messages.lastWhereOrElse((message) => message.isAssistant);
      final lastUserMessage = messages.lastWhereOrElse((message) => message.isUser);

      setLastAssistantMessageId(lastAssistantMessage?.id);
      setLastUserMessageId(lastUserMessage?.id);

      // Ready for streaming if the last message is from the assistant
      setReadyForStreamingAssistant(messages.lastOrNull?.isAssistant == true);

      return null;
    },
    [messageHash],
  );
}
