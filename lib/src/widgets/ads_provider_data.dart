import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/models/public_ad.dart';

typedef AdCallback = void Function(PublicAd ad);

class AdsProviderData extends InheritedWidget {
  const AdsProviderData({
    super.key,
    required this.messages,
    required this.bids,
    required this.readyForStreamingAssistant,
    required this.readyForStreamingUser,
    required this.lastAssistantMessageId,
    required this.lastUserMessageId,
    this.onAdView,
    this.onAdClick,
    this.onAdDone,
    required super.child,
  });

  final List<Message> messages;
  final List<Bid> bids;
  final bool readyForStreamingAssistant;
  final bool readyForStreamingUser;
  final String? lastAssistantMessageId;
  final String? lastUserMessageId;
  final AdCallback? onAdView;
  final AdCallback? onAdClick;
  final AdCallback? onAdDone;

  static AdsProviderData? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdsProviderData>();
  }

  @override
  bool updateShouldNotify(AdsProviderData oldWidget) {
    final foo = !listEquals<Message>(messages, oldWidget.messages) ||
        !listEquals<Bid>(bids, oldWidget.bids) ||
        readyForStreamingUser != oldWidget.readyForStreamingUser ||
        readyForStreamingAssistant != oldWidget.readyForStreamingAssistant ||
        lastAssistantMessageId != oldWidget.lastAssistantMessageId ||
        lastUserMessageId != oldWidget.lastUserMessageId;
    print('AdsProviderData updateShouldNotify: listEquals<Message>: ${!listEquals<Message>(messages, oldWidget.messages)}, '
          'listEquals<Bid>: ${!listEquals<Bid>(bids, oldWidget.bids)}, '
          'readyForStreamingUser: old: ${oldWidget.readyForStreamingUser}, new: $readyForStreamingUser, changed: ${readyForStreamingUser != oldWidget.readyForStreamingUser}, '
          'readyForStreamingAssistant: old: ${oldWidget.readyForStreamingAssistant}, new: $readyForStreamingAssistant, changed: ${readyForStreamingAssistant != oldWidget.readyForStreamingAssistant}, '
          'lastAssistantMessageId: old: ${oldWidget.lastAssistantMessageId}, new: $lastAssistantMessageId, changed: ${lastAssistantMessageId != oldWidget.lastAssistantMessageId}, '
          'lastUserMessageId: old: ${oldWidget.lastUserMessageId}, new: $lastUserMessageId, changed: ${lastUserMessageId != oldWidget.lastUserMessageId}, '
          'result: $foo');
    return foo;
  }
}
