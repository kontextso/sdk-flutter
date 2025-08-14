import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' show HookWidget, useState, useEffect;
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart';
import 'package:kontext_flutter_sdk/src/widgets/ads_provider_data.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/models/character.dart';
import 'package:kontext_flutter_sdk/src/utils/constants.dart';
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
    this.enabledPlacementCodes = const [],
    this.character,
    this.vendorId,
    this.variantId,
    this.advertisingId,
    this.logLevel,
    this.iosAppStoreId,
    this.onAdView,
    this.onAdClick,
    this.onAdDone,
    required this.child,
  });

  /// The URL of the ad server.
  ///
  /// Defaults to [kDefaultAdServerUrl] if not provided.
  final String adServerUrl;

  /// Your unique publisher token.
  final String publisherToken;

  /// A unique string that should remain the same during the user’s
  /// lifetime (used for retargeting and rewarded ads).
  final String userId;

  /// Unique identifier of the conversation.
  final String conversationId;

  /// A list of messages between the assistant and the user.
  final List<Message> messages;

  /// Whether the ads are disabled.
  final bool isDisabled;

  /// A list of enabled placement codes for the ads.
  final List<String> enabledPlacementCodes;

  /// The character object used in this conversation.
  final Character? character;

  /// Vendor-specific ID.
  final String? vendorId;

  /// A variant ID that helps determine which type of ad to render.
  ///
  /// This ID is typically unique for each publisher and is defined
  /// based on an agreement between the publisher and Kontext.so.
  final String? variantId;

  /// Device-specific identifier provided by the operating systems (IDFA/GAID)
  final String? advertisingId;

  /// The log level for the SDK:
  /// [LogLevel.debug], [LogLevel.info],
  /// [LogLevel.log], [LogLevel.warn],
  /// [LogLevel.error], or [LogLevel.silent].
  final LogLevel? logLevel;

  /// iOS App Store ID for the app, used for better ad matching and reporting.
  ///
  /// Ignored on Android.
  final String? iosAppStoreId;

  /// Callback when an ad is viewed.
  final AdCallback? onAdView;

  /// Callback when an ad is clicked.
  final AdCallback? onAdClick;

  /// Callback when an ad is fully processed.
  final AdCallback? onAdDone;

  /// The child widget to be wrapped by the AdsProvider.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bids = useState<List<Bid>>([]);
    final readyForStreamingAssistant = useState<bool>(false);
    final readyForStreamingUser = useState<bool>(false);
    final lastAssistantMessageId = useState<String?>(null);
    final lastUserMessageId = useState<String?>(null);
    final relevantAssistantMessageId = useState<String?>(null);

    void setBids(List<Bid> newBids) => bids.value = newBids;
    void setReadyForStreamingAssistant(bool ready) => readyForStreamingAssistant.value = ready;
    void setReadyForStreamingUser(bool ready) => readyForStreamingUser.value = ready;
    void setLastAssistantMessageId(String? id) => lastAssistantMessageId.value = id;
    void setLastUserMessageId(String? id) => lastUserMessageId.value = id;
    void setRelevantAssistantMessageId(String? id) => relevantAssistantMessageId.value = id;

    void resetAll() {
      setBids([]);
      setReadyForStreamingAssistant(false);
      setReadyForStreamingUser(false);
      setLastAssistantMessageId(null);
      setLastUserMessageId(null);
      setRelevantAssistantMessageId(null);
    }

    useEffect(() {
      HttpClient.resetInstance();
      HttpClient(baseUrl: adServerUrl);
      resetAll();
      return null;
    }, [adServerUrl]);

    useEffect(() {
      resetAll();
      return null;
    }, [conversationId]);

    useEffect(() {
      final logLevel = this.logLevel;
      if (logLevel != null) {
        Logger.setLocalLogLevel(logLevel);
      }
      return null;
    }, [logLevel]);

    usePreloadAds(
      context,
      adServerUrl: adServerUrl,
      publisherToken: publisherToken,
      userId: userId,
      conversationId: conversationId,
      messages: messages,
      enabledPlacementCodes: enabledPlacementCodes,
      isDisabled: isDisabled,
      character: character,
      vendorId: vendorId,
      variantId: variantId,
      advertisingId: advertisingId,
      iosAppStoreId: iosAppStoreId,
      setBids: setBids,
      setReadyForStreamingAssistant: setReadyForStreamingAssistant,
      setReadyForStreamingUser: setReadyForStreamingUser,
    );

    useLastMessages(
      messages,
      lastUserMessageId: lastUserMessageId.value,
      setReadyForStreamingAssistant: setReadyForStreamingAssistant,
      setLastAssistantMessageId: setLastAssistantMessageId,
      setLastUserMessageId: setLastUserMessageId,
      setRelevantAssistantMessageId: setRelevantAssistantMessageId,
    );

    return AdsProviderData(
      adServerUrl: adServerUrl,
      messages: messages,
      bids: bids.value,
      isDisabled: isDisabled,
      enabledPlacementCodes: enabledPlacementCodes,
      readyForStreamingAssistant: readyForStreamingAssistant.value,
      readyForStreamingUser: readyForStreamingUser.value,
      lastAssistantMessageId: lastAssistantMessageId.value,
      lastUserMessageId: lastUserMessageId.value,
      relevantAssistantMessageId: relevantAssistantMessageId.value,
      setRelevantAssistantMessageId: setRelevantAssistantMessageId,
      resetAll: resetAll,
      onAdView: onAdView,
      onAdClick: onAdClick,
      onAdDone: onAdDone,
      child: child,
    );
  }
}
