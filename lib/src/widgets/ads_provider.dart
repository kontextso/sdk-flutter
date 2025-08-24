import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' show HookWidget, useState, useEffect;
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/services/api.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart';
import 'package:kontext_flutter_sdk/src/widgets/ads_provider_data.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/models/character.dart';
import 'package:kontext_flutter_sdk/src/utils/constants.dart';
import 'package:kontext_flutter_sdk/src/widgets/hooks/use_last_messages.dart';
import 'package:kontext_flutter_sdk/src/widgets/hooks/use_preload_ads.dart';

/// [AdsProvider] handles data fetching and state management for ads.
class AdsProvider extends HookWidget {
  const AdsProvider({
    super.key,
    this.adServerUrl = kDefaultAdServerUrl,
    required this.publisherToken,
    required this.userId,
    required this.conversationId,
    required this.messages,
    this.isDisabled = false,
    required this.enabledPlacementCodes,
    this.character,
    this.vendorId,
    this.variantId,
    this.advertisingId,
    this.logLevel,
    this.iosAppStoreId,
    this.gdpr,
    this.gdprConsent,
    this.coppa,
    this.gpp,
    this.gppSid,
    this.usPrivacy,
    this.onAdView,
    this.onAdClick,
    this.onAdDone,
    required this.child,
  })  : assert(gdpr == null || gdpr == 0 || gdpr == 1, 'gdpr must be 0 or 1'),
        assert(coppa == null || coppa == 0 || coppa == 1, 'coppa must be 0 or 1');

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

  /// Flag that indicates whether or not the request is subject to GDPR regulations (0 = No, 1 = Yes, null = Unknown).
  final int? gdpr;

  /// When GDPR regulations are in effect this attribute contains the Transparency and Consent Framework's Consent String data structure
  ///
  /// https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework/blob/master/TCFv2/IAB%20Tech%20Lab%20-%20Consent%20string%20and%20vendor%20list%20formats%20v2.md#about-the-transparency--consent-string-tc-string
  final String? gdprConsent;

  /// Flag whether the request is subject to COPPA (0 = No, 1 = Yes, null = Unknown).
  ///
  /// https://www.ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule-coppa
  final int? coppa;

  /// Global Privacy Platform (GPP) consent string.
  ///
  /// https://github.com/InteractiveAdvertisingBureau/Global-Privacy-Platform
  final String? gpp;

  /// List of the section(s) of the GPP string which should be applied for this transaction.
  final List<int>? gppSid;

  /// Communicates signals regarding consumer privacy under US privacy regulation under CCPA and LSPA.
  ///
  /// https://github.com/InteractiveAdvertisingBureau/USPrivacy/blob/master/CCPA/US%20Privacy%20String.md
  final String? usPrivacy;

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
      resetAll();
      HttpClient.resetInstance();
      Api.resetInstance();
      Logger.resetInstance();

      HttpClient(baseUrl: adServerUrl);
      return null;
    }, [adServerUrl]);

    useEffect(() {
      resetAll();
      return null;
    }, [userId, conversationId]);

    useEffect(() {
      final logLevel = this.logLevel;
      if (logLevel != null) {
        Logger.setLocalLogLevel(logLevel);
      }
      return null;
    }, [logLevel]);

    usePreloadAds(
      context,
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
      gdpr: gdpr,
      gdprConsent: gdprConsent,
      coppa: coppa,
      gpp: gpp,
      gppSid: gppSid,
      usPrivacy: usPrivacy,
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
