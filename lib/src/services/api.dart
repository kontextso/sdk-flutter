import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/enums.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';

class Api {
  Api._internal() : _client = HttpClient();

  final HttpClient _client;

  static final Api _instance = Api._internal();

  factory Api() => _instance;

  Future<List<Bid>> fetchBids({
    required String publisherToken,
    required String userId,
    required String conversationId,
    required List<Message> messages,
  }) async {
    try {
      final response = await _client.post('/preload', body: {
        'publisherToken': publisherToken,
        'userId': userId,
        'conversationId': conversationId,
        'messages': messages.map((message) => message.toJson()).toList(),
      });

      final bidJson = response['bids'] as List<dynamic>?;
      if (bidJson == null) {
        return [];
      }

      final bids = bidJson.map((bid) {
        return Bid(
          id: bid['bidId'] as String,
          code: bid['code'] as String,
          position: AdDisplayPosition.values.firstWhere(
            (position) => position.name == '${bid['adDisplayPosition']}',
            orElse: () => AdDisplayPosition.afterAssistantMessage,
          ),
        );
      }).toList();

      return bids;
    } catch (e) {
      print("[Kontext] Error fetching data: $e");
      return [];
    }
  }
}
