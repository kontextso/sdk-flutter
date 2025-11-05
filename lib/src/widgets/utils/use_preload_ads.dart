import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kontext_flutter_sdk/src/models/ad_event.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/character.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/models/regulatory.dart';
import 'package:kontext_flutter_sdk/src/services/api.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart';
import 'package:kontext_flutter_sdk/src/utils/constants.dart';
import 'package:kontext_flutter_sdk/src/utils/types.dart' show OnEventCallback;

void usePreloadAds(
  BuildContext context, {
  required String publisherToken,
  required String conversationId,
  required String userId,
  required String? userEmail,
  required List<String> enabledPlacementCodes,
  required List<Message> messages,
  required bool isDisabled,
  required String? vendorId,
  required String? advertisingId,
  required Regulatory? regulatory,
  required Character? character,
  required String? variantId,
  required String? iosAppStoreId,
  required ValueChanged<List<Bid>> setBids,
  required ValueChanged<bool> setReadyForStreamingAssistant,
  required ValueChanged<bool> setReadyForStreamingUser,
  required OnEventCallback? onEvent,
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

  final loading = useRef<bool>(false);

  useEffect(() {
    if (!hasMessages) return null;

    final isNewUserMessage = userMessageCount > prevUserMessageCount.value;

    if (loading.value) {
      if (isNewUserMessage) {
        // Acknowledge the arrival but do not schedule another preload
        prevUserMessageCount.value = userMessageCount;
      }
      // Drop if a preload is already running
      return null;
    }

    if (!isNewUserMessage) return null;

    prevUserMessageCount.value = userMessageCount;

    setBids([]);
    setReadyForStreamingAssistant(false);
    setReadyForStreamingUser(false);

    notifyAdFilled() => onEvent?.call(AdEvent(type: AdEventType.adFilled));
    notifyAdNoFill(String skipCode) => onEvent?.call(AdEvent(type: AdEventType.adNoFill, skipCode: skipCode));

    Future<void> preload() async {
      if (isDisabled || sessionDisabled.value) {
        Logger.log('Preload ads dropped (disabled mid-flight)');
        return;
      }

      Logger.log('Preload ads started');
      loading.value = true;

      try {
        final api = Api();
        final response = await api.preload(
          publisherToken: publisherToken,
          conversationId: conversationId,
          userId: userId,
          userEmail: userEmail,
          enabledPlacementCodes: enabledPlacementCodes,
          messages: messages,
          sessionId: sessionId.value,
          vendorId: vendorId,
          advertisingId: advertisingId,
          regulatory: regulatory,
          character: character,
          variantId: variantId,
          iosAppStoreId: iosAppStoreId,
        );

        if (!context.mounted) {
          return;
        }

        if (response.statusCode == 204) {
          Logger.log('Preload ads finished (204)');
          notifyAdNoFill(AdEvent.skipCodeUnFilledBid);
          return;
        }

        if (response.skip == true) {
          notifyAdNoFill(response.skipCode ?? AdEvent.skipCodeUnknown);
          Logger.info('Ad generation skipped. Reason: ${response.skipCode}');
          return;
        }

        if (response.error != null || response.errorCode != null || response.sessionId == null) {
          if (response.permanentError == true) {
            // Geo disabled or other reason, ads are permanently disabled
            sessionDisabled.value = true;
            notifyAdNoFill(AdEvent.skipCodeSessionDisabled);
            Logger.info('Session is disabled. Reason: Error=${response.error}, ErrorCode=${response.errorCode}');
          } else {
            notifyAdNoFill(response.errorCode ?? AdEvent.skipCodeUnknown);
            Logger.info('Ad generation skipped. Reason: Error=${response.error}, ErrorCode=${response.errorCode}');
          }
          return;
        }

        if (response.remoteLogLevel != null) {
          Logger.setRemoteLogLevel(response.remoteLogLevel!);
        }

        sessionId.value = response.sessionId;

        final bids = response.bids;
        setBids([...bids]);
        setReadyForStreamingUser(true);
        Logger.log('Preload Ads finished');

        if (bids.isNotEmpty) {
          notifyAdFilled();
        } else {
          notifyAdNoFill(AdEvent.skipCodeUnFilledBid);
        }
      } catch (e) {
        Logger.error('Preload ads error: $e');
        notifyAdNoFill(AdEvent.skipCodeError);
      } finally {
        loading.value = false;
      }
    }

    preload();
    return null;
  }, [userMessageCount, hasMessages, isDisabled]);
}
