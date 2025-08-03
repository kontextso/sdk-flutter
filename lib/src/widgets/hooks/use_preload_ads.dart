import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/character.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/services/api.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

void usePreloadAds(
  BuildContext context, {
  required String adServerUrl,
  required String publisherToken,
  required String userId,
  required String conversationId,
  required List<Message> messages,
  required bool isDisabled,
  required Character? character,
  required String? vendorId,
  required String? variantId,
  required String? advertisingId,
  required ValueChanged<List<Bid>> setBids,
  required ValueChanged<bool> setReadyForStreamingAssistant,
  required ValueChanged<bool> setReadyForStreamingUser,
}) {
  final sessionId = useRef<String?>(null);

  if (messages.isEmpty) {
    setBids([]);
    setReadyForStreamingAssistant(false);
    setReadyForStreamingUser(false);
    return;
  }

  final lastUserMessagesContent =
      messages.reversed.where((message) => message.isUser).take(6).map((message) => message.content).join('\n');

  useEffect(() {
    print('usePreloadAds useEffect triggered - lastUserMessagesContent length: ${lastUserMessagesContent.length}');
    setBids([]);
    setReadyForStreamingAssistant(false);
    setReadyForStreamingUser(false);

    bool cancelled = false;
    preload() async {
      if (isDisabled || cancelled) return;

      final api = Api();
      final result = await api.preload(
        publisherToken: publisherToken,
        userId: userId,
        conversationId: conversationId,
        sessionId: sessionId.value,
        messages: messages.getLastMessages(),
        character: character,
        vendorId: vendorId,
        variantId: variantId,
        advertisingId: advertisingId,
      );

      if (cancelled || !context.mounted) {
        return;
      }

      sessionId.value = result.sessionId;

      print('Fetched bids: lastUserMessagesContent length: ${lastUserMessagesContent.length}, ${result.bids}');
      setBids([...result.bids]);
      setReadyForStreamingUser(true);
    }

    preload();

    return () {
      cancelled = true;
    };
  }, [lastUserMessagesContent]);
}
