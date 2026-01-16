import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/utils/types.dart' show OnEventCallback;

class AdsProviderData extends InheritedWidget {
  const AdsProviderData({
    super.key,
    required this.adServerUrl,
    required this.messages,
    required this.bids,
    required this.isDisabled,
    this.enabledPlacementCodes = const [],
    this.otherParams,
    required this.readyForStreamingAssistant,
    required this.lastAssistantMessageId,
    required this.lastUserMessageId,
    required this.relevantAssistantMessageId,
    required this.setRelevantAssistantMessageId,
    required this.resetAll,
    required this.onEvent,
    required super.child,
  });

  final String adServerUrl;
  final List<Message> messages;
  final List<Bid> bids;
  final bool isDisabled;
  final List<String> enabledPlacementCodes;
  final Map<String, dynamic>? otherParams;
  final bool readyForStreamingAssistant;
  final String? lastAssistantMessageId;
  final String? lastUserMessageId;
  final String? relevantAssistantMessageId;
  final void Function(String?) setRelevantAssistantMessageId;
  final VoidCallback resetAll;
  final OnEventCallback? onEvent;

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
        !mapEquals(otherParams, oldWidget.otherParams) ||
        readyForStreamingAssistant != oldWidget.readyForStreamingAssistant ||
        lastAssistantMessageId != oldWidget.lastAssistantMessageId ||
        relevantAssistantMessageId != oldWidget.relevantAssistantMessageId ||
        lastUserMessageId != oldWidget.lastUserMessageId ||
        onEvent != oldWidget.onEvent;
  }
}
