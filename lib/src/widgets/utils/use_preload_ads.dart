import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kontext_flutter_sdk/src/models/ad_event.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/character.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';
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
  final isDisabledRef = useRef<bool>(isDisabled);

  final prevUserMessageCount = useRef<int>(0);
  final userMessageCount = messages.where((message) => message.isUser).length;

  final hasMessages = messages.isNotEmpty;

  useEffect(() {
    isDisabledRef.value = isDisabled;
    return null;
  }, [isDisabled]);

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
      });
    }

    return null;
  }, [sessionId.value, publisherToken, userId, conversationId, character, vendorId, variantId]);

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

    notifyAdFilled(double? revenue) {
      if (isDisabledRef.value) return;
      onEvent?.call(AdEvent(type: AdEventType.adFilled, revenue: revenue));
    }

    notifyAdNoFill(String skipCode) {
      if (isDisabledRef.value) return;
      onEvent?.call(AdEvent(type: AdEventType.adNoFill, skipCode: skipCode));
    }

    notifyAdError(String error, String errorCode) {
      if (isDisabledRef.value) return;
      onEvent?.call(AdEvent(type: AdEventType.adError, message: error, errCode: errorCode));
    }

    Future<void> preload() async {
      if (sessionDisabled.value) {
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
          messages: messages.getLastMessages(),
          sessionId: sessionId.value,
          vendorId: vendorId,
          advertisingId: advertisingId,
          regulatory: regulatory,
          character: character,
          variantId: variantId,
          iosAppStoreId: iosAppStoreId,
          isDisabled: isDisabled,
        );

        if (!context.mounted) {
          return;
        }

        // 1) Skip everything if there was an error
        if (response.error != null || response.errorCode != null || response.sessionId == null) {
          if (response.permanentError == true) {
            // Geo disabled or other reason, ads are permanently disabled
            sessionDisabled.value = true;
            notifyAdError(
                response.error ?? 'Session is disabled', response.errorCode ?? AdEvent.skipCodeSessionDisabled);
            Logger.info('Session is disabled. Reason: Error=${response.error}, ErrorCode=${response.errorCode}');
          } else {
            notifyAdError(response.error ?? 'Ad generation skipped', response.errorCode ?? AdEvent.skipCodeUnknown);
            Logger.info('Ad generation skipped. Reason: Error=${response.error}, ErrorCode=${response.errorCode}');
          }
          return;
        }

        // 2) Save session ID
        sessionId.value = response.sessionId;

        if (isDisabledRef.value) {
          Logger.log('Preload ads finished (disabled mid-flight)');
          return;
        }

        // 3) Skip everything else if ads are disabled manually
        if (isDisabled) {
          Logger.log('Preload ads finished (disabled)');
          return;
        }

        final bids = response.bids;

        // 4) Handle unfilled response
        if (response.skip == true || bids.isEmpty) {
          notifyAdNoFill(response.skipCode ?? AdEvent.skipCodeUnknown);
          Logger.info('Ad generation skipped. Reason: ${response.skipCode}');
          return;
        }

        setBids([...bids]);
        setReadyForStreamingUser(true);
        Logger.log('Preload ads finished');
        notifyAdFilled(bids.firstOrNull?.revenue);
      } catch (e) {
        Logger.error('Preload ads error: $e');
        notifyAdError(e.toString(), AdEvent.skipCodeRequestFailed);
      } finally {
        loading.value = false;
      }
    }

    preload();
    return null;
  }, [userMessageCount, hasMessages, isDisabled]);
}
