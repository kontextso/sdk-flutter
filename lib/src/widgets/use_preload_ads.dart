import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/services/api.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

List<Bid> usePreloadAds(BuildContext context, {
  required String publisherToken,
  required List<Message> messages,
  required String userId,
  required String conversationId,
}) {
  final bidListState = useState<List<Bid>>([]);
  final messagesKey = messages.deepHash;
  useEffect(() {
    preloadAds() async {
      final api = Api();
      final bids = await api.preloadAds(
        publisherToken: publisherToken,
        userId: userId,
        conversationId: conversationId,
        messages: messages,
      );
      print('Fetched bids: $bids');
      if (!context.mounted) {
        return;
      }

      bidListState.value = [...bids];
    }

    preloadAds();

    return null;
  }, [publisherToken, userId, conversationId, messagesKey]);

  return bidListState.value;
}
