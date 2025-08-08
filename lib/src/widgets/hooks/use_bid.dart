import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';
import 'package:kontext_flutter_sdk/src/widgets/ads_provider_data.dart';

Bid? useBid(AdsProviderData data, {required String code, required String messageId}) {
  final bid = data.bids.firstWhereOrElse((bid) => bid.code == code);
  if (bid == null) {
    return null;
  }

  final isValidMessage = bid.isAfterAssistantMessage
      ? (data.relevantAssistantMessageId ?? data.lastAssistantMessageId) == messageId && data.readyForStreamingAssistant
      : data.lastUserMessageId == messageId && data.readyForStreamingUser;
  if (!isValidMessage) {
    return null;
  }

  return bid;
}
