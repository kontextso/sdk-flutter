import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/models/public_ad.dart';

typedef AdCallback = void Function(PublicAd ad);

class AdsProviderData extends InheritedWidget {
  const AdsProviderData({
    super.key,
    required this.adServerUrl,
    required this.messages,
    required this.bids,
    required this.isDisabled,
    this.enabledPlacementCodes = const [],
    required this.readyForStreamingAssistant,
    required this.readyForStreamingUser,
    required this.lastAssistantMessageId,
    required this.lastUserMessageId,
    required this.relevantAssistantMessageId,
    required this.setRelevantAssistantMessageId,
    required this.resetAll,
    required this.onAdView,
    required this.onAdClick,
    required this.onAdDone,
    required super.child,
  });

  final String adServerUrl;
  final List<Message> messages;
  final List<Bid> bids;
  final bool isDisabled;
  final List<String> enabledPlacementCodes;
  final bool readyForStreamingAssistant;
  final bool readyForStreamingUser;
  final String? lastAssistantMessageId;
  final String? lastUserMessageId;
  final String? relevantAssistantMessageId;
  final void Function(String?) setRelevantAssistantMessageId;
  final VoidCallback resetAll;
  final AdCallback? onAdView;
  final AdCallback? onAdClick;
  final AdCallback? onAdDone;

  static AdsProviderData? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdsProviderData>();
  }

  @override
  bool updateShouldNotify(AdsProviderData oldWidget) {
    return adServerUrl != oldWidget.adServerUrl ||
        !listEquals<Message>(messages, oldWidget.messages) ||
        !listEquals<Bid>(bids, oldWidget.bids) ||
        isDisabled != oldWidget.isDisabled ||
        !listEquals(enabledPlacementCodes, oldWidget.enabledPlacementCodes) ||
        readyForStreamingUser != oldWidget.readyForStreamingUser ||
        readyForStreamingAssistant != oldWidget.readyForStreamingAssistant ||
        lastAssistantMessageId != oldWidget.lastAssistantMessageId ||
        relevantAssistantMessageId != oldWidget.relevantAssistantMessageId ||
        lastUserMessageId != oldWidget.lastUserMessageId ||
        onAdView != oldWidget.onAdView ||
        onAdClick != oldWidget.onAdClick ||
        onAdDone != oldWidget.onAdDone;
  }
}
