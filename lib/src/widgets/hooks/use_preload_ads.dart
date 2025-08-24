import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/character.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/services/api.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart';
import 'package:kontext_flutter_sdk/src/utils/constants.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

void usePreloadAds(
  BuildContext context, {
  required String publisherToken,
  required String userId,
  required String conversationId,
  required List<Message> messages,
  required bool isDisabled,
  required List<String> enabledPlacementCodes,
  required Character? character,
  required String? vendorId,
  required String? variantId,
  required String? advertisingId,
  required String? iosAppStoreId,
  required int? gdpr,
  required String? gdprConsent,
  required int? coppa,
  required String? gpp,
  required List<int>? gppSid,
  required String? usPrivacy,
  required ValueChanged<List<Bid>> setBids,
  required ValueChanged<bool> setReadyForStreamingAssistant,
  required ValueChanged<bool> setReadyForStreamingUser,
}) {
  final sessionId = useRef<String?>(null);
  final sessionDisabled = useRef<bool>(false);

  final prevUserMessageCount = useRef<int>(0);
  final userMessageCount = messages.where((message) => message.isUser).length;

  final hasMessages = messages.isNotEmpty;

  useEffect(() {
    if (!hasMessages) {
      setBids([]);
      setReadyForStreamingAssistant(false);
      setReadyForStreamingUser(false);
      prevUserMessageCount.value = 0;
    }
    return null;
  }, [hasMessages]);

  useEffect(() {
    if (sessionId.value != null) {
      Logger.setRemoteConfig({
        'sdk': kSdkLabel,
        'sdkVersion': kSdkVersion,
        'sessionId': sessionId.value,
        'publisherToken': publisherToken,
        'userId': userId,
        'conversationId': conversationId,
        'character': character?.toJson(),
        'vendorId': vendorId,
        'variantId': variantId,
        'advertisingId': advertisingId,
      });
    }

    return null;
  }, [sessionId.value, publisherToken, userId, conversationId, character, vendorId, variantId, advertisingId]);

  useEffect(() {
    if (!hasMessages) return null;

    final isNewUserMessage = userMessageCount > prevUserMessageCount.value;
    prevUserMessageCount.value = userMessageCount;

    if (!isNewUserMessage) {
      return null;
    }

    setBids([]);
    setReadyForStreamingAssistant(false);
    setReadyForStreamingUser(false);

    bool cancelled = false;

    Future<void> preload() async {
      if (isDisabled || cancelled || sessionDisabled.value) return;

      Logger.log('Preload ads started');
      final api = Api();
      final response = await api.preload(
        publisherToken: publisherToken,
        userId: userId,
        conversationId: conversationId,
        sessionId: sessionId.value,
        messages: messages.getLastMessages(),
        enabledPlacementCodes: enabledPlacementCodes,
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
      );

      if (cancelled || !context.mounted) return;

      if (response.statusCode == 204) {
        Logger.log('Preload ads finished (204)');
        return;
      }

      if (response.error != null || response.errorCode != null || response.sessionId == null) {
        if (response.permanentError == true) {
          // Geo disabled or other reason, ads are permanently disabled
          sessionDisabled.value = true;
          Logger.info('Session is disabled. Reason: Error=${response.error}, ErrorCode=${response.errorCode}');
          return;
        }
        Logger.info('Ad generation skipped. Reason: Error=${response.error}, ErrorCode=${response.errorCode}');
        return;
      }

      if (response.remoteLogLevel != null) {
        Logger.setRemoteLogLevel(response.remoteLogLevel!);
      }

      sessionId.value = response.sessionId;

      setBids([...response.bids]);
      setReadyForStreamingUser(true);

      Logger.log('Preload Ads finished');
    }

    preload();

    return () {
      cancelled = true;
    };
  }, [userMessageCount, hasMessages]);
}
