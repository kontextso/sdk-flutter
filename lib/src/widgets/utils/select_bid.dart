import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';
import 'package:kontext_flutter_sdk/src/widgets/ads_provider_data.dart';

Bid? selectBid(AdsProviderData data, {required String code, required String messageId}) {
  final placement = data.enabledPlacementCodes.firstWhereOrElse((c) => c == code);
  if (placement == null) {
    return null;
  }

  final bid = data.bids.firstWhereOrElse((bid) => bid.code == code);

  // print('----------');
  //print('----data.bid: ${bid}');
  //print('----data.relevantAssistantMessageId: ${data.relevantAssistantMessageId}');
  //print('----data.lastAssistantMessageId: ${data.lastAssistantMessageId}');
  //print('----data.lastUserMessageId: ${data.lastUserMessageId}');
  print('----data.readyForStreamingAssistant: ${data.readyForStreamingAssistant}');
  //print('----data.readyForStreamingUser: ${data.readyForStreamingUser}');
  //print('----messageId: $messageId');
  //print('----------');

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
