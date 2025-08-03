import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/services/api.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/widgets/ads_provider_data.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/models/character.dart';
import 'package:kontext_flutter_sdk/src/widgets/constants.dart';
import 'package:kontext_flutter_sdk/src/widgets/hooks/use_last_messages.dart';
import 'package:kontext_flutter_sdk/src/widgets/hooks/use_preload_ads.dart';

class AdsProvider extends HookWidget {
  const AdsProvider({
    super.key,
    this.adServerUrl = kDefaultAdServerUrl,
    required this.publisherToken,
    required this.userId,
    required this.conversationId,
    required this.messages,
    this.isDisabled = false,
    this.character,
    this.vendorId,
    this.variantId,
    this.advertisingId,
    this.onAdView,
    this.onAdClick,
    this.onAdDone,
    required this.child,
  });


  final String adServerUrl;
  final String publisherToken;
  final String userId;
  final String conversationId;
  final List<Message> messages;
  final bool isDisabled;
  final Character? character;
  final String? vendorId;
  final String? variantId;
  final String? advertisingId;
  final AdCallback? onAdView;
  final AdCallback? onAdClick;
  final AdCallback? onAdDone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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

    void resetAll() {
      setBids([]);
      setReadyForStreamingAssistant(false);
      setReadyForStreamingUser(false);
      setLastAssistantMessageId(null);
      setLastUserMessageId(null);
    }

    useEffect(() {
      HttpClient.resetInstance();
      HttpClient(baseUrl: adServerUrl);
      resetAll();
      return null;
    }, [adServerUrl]);

    usePreloadAds(
      context,
      adServerUrl: adServerUrl,
      publisherToken: publisherToken,
      userId: userId,
      conversationId: conversationId,
      messages: messages,
      isDisabled: isDisabled,
      character: character,
      vendorId: vendorId,
      variantId: variantId,
      advertisingId: advertisingId,
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
      adServerUrl: adServerUrl,
      messages: messages,
      bids: bids.value,
      isDisabled: isDisabled,
      readyForStreamingAssistant: readyForStreamingAssistant.value,
      readyForStreamingUser: readyForStreamingUser.value,
      lastAssistantMessageId: lastAssistantMessageId.value,
      lastUserMessageId: lastUserMessageId.value,
      resetAll: resetAll,
      onAdView: onAdView,
      onAdClick: onAdClick,
      onAdDone: onAdDone,
      child: child,
    );
  }
}
