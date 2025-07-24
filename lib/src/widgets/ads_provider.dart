import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/widgets/ads_provider_data.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/widgets/hooks/use_last_messages.dart';
import 'package:kontext_flutter_sdk/src/widgets/hooks/use_preload_ads.dart';

class AdsProvider extends HookWidget {
  const AdsProvider({
    super.key,
    required this.publisherToken,
    required this.userId,
    required this.conversationId,
    required this.messages,
    this.onAdView,
    this.onAdClick,
    this.onAdDone,
    required this.child,
  });

  final String publisherToken;
  final String userId;
  final String conversationId;
  final List<Message> messages;
  final AdCallback? onAdView;
  final AdCallback? onAdClick;
  final AdCallback? onAdDone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    print('Building AdsProvider');

    final bids = useState<List<Bid>>([]);
    final readyForStreamingAssistant = useState<bool>(false);
    final readyForStreamingUser = useState<bool>(false);
    final lastAssistantMessageId = useState<String?>(null);
    final lastUserMessageId = useState<String?>(null);

    void setBids(List<Bid> newBids) => bids.value = newBids;
    void setReadyForStreamingAssistant(bool ready) => readyForStreamingAssistant.value = ready;
    void setReadyForStreamingUser(bool ready) => readyForStreamingUser.value = ready;
    void setLastAssistantMessageId(String? id) => lastAssistantMessageId.value = id;
    void setLastUserMessageId(String? id) => lastUserMessageId.value = id;

    final lastMessages = messages.length > 10
        ? messages.sublist(messages.length - 10)
        : messages;

    usePreloadAds(
      context,
      publisherToken: publisherToken,
      messages: messages,
      lastMessages: lastMessages,
      userId: userId,
      conversationId: conversationId,
      setBids: setBids,
      setReadyForStreamingAssistant: setReadyForStreamingAssistant,
      setReadyForStreamingUser: setReadyForStreamingUser,
    );

    useLastMessages(
      messages,
      setReadyForStreamingAssistant: setReadyForStreamingAssistant,
      setLastAssistantMessageId: setLastAssistantMessageId,
      setLastUserMessageId: setLastUserMessageId,
    );

    return AdsProviderData(
      messages: lastMessages,
      bids: bids.value,
      readyForStreamingAssistant: readyForStreamingAssistant.value,
      readyForStreamingUser: readyForStreamingUser.value,
      lastAssistantMessageId: lastAssistantMessageId.value,
      lastUserMessageId: lastUserMessageId.value,
      onAdView: onAdView,
      onAdClick: onAdClick,
      onAdDone: onAdDone,
      child: child,
    );
  }
}
