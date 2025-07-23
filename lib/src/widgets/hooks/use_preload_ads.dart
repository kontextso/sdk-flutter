import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/services/api.dart';

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

  final userMessagesContent =
      messages.reversed.take(6).where((message) => message.isUser).map((message) => message.content).join('\n');

  final numberOfAssistantFollowups = messages.reversed.takeWhile((message) => !message.isUser).length;

  useEffect(() {
    final timer = Timer(const Duration(milliseconds: 300), () async {
      final api = Api();
      final bids = await api.fetchBids(
        publisherToken: publisherToken,
        userId: userId,
        conversationId: conversationId,
        messages: messages,
      );
      print('Fetched bids: $bids');
      if (!context.mounted) {
        return;
      }

      setBids([...bids]);
    });

    return () => timer.cancel();
  }, [userMessagesContent, numberOfAssistantFollowups]);
}
