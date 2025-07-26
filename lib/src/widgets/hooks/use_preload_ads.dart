import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/services/api.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

void usePreloadAds(
  BuildContext context, {
  required String publisherToken,
  required List<Message> messages,
  required String userId,
  required String conversationId,
  required ValueChanged<List<Bid>> setBids,
  required ValueChanged<bool> setReadyForStreamingAssistant,
  required ValueChanged<bool> setReadyForStreamingUser,
}) {
  if (messages.isEmpty) {
    setBids([]);
    setReadyForStreamingAssistant(false);
    setReadyForStreamingUser(false);
    return;
  }

  final lastUserMessagesContent =
      messages.reversed.where((message) => message.isUser).take(6).map((message) => message.content).join('\n');

  final assistantMessageCount = messages.where((message) => message.isAssistant).length;

  useEffect(() {
    // Skip preload if this is the first assistant message
    if (assistantMessageCount <= 1) {
      return null;
    }

    final timer = Timer(const Duration(milliseconds: 300), () async {
      final api = Api();
      final bids = await api.preload(
        publisherToken: publisherToken,
        userId: userId,
        conversationId: conversationId,
        messages: messages.getLastMessages(),
      );
      print('Fetched bids: $bids');
      if (!context.mounted) {
        return;
      }

      setBids([...bids]);
    });

    return () => timer.cancel();
  }, [lastUserMessagesContent, assistantMessageCount]);
}
