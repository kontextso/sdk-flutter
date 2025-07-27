import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/character.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';

class Api {
  Api._internal({String? baseUrl}) : _client = HttpClient(baseUrl: baseUrl);

  final HttpClient _client;

  static Api? _instance;

  factory Api({String? baseUrl}) {
    return _instance ??= Api._internal(baseUrl: baseUrl);
  }

  static void resetInstance() {
    _instance = null;
  }

  Future<List<Bid>> preload({
    required String publisherToken,
    required String userId,
    required String conversationId,
    required List<Message> messages,
    Character? character,
  }) async {
    try {
      final response = await _client.post(
        '/preload',
        body: {
          'publisherToken': publisherToken,
          'userId': userId,
          'conversationId': conversationId,
          'messages': messages.map((message) => message.toJson()).toList(),
          if (character != null) 'character': character.toJson(),
        },
      );

      final bidJson = response['bids'] as List<dynamic>?;
      if (bidJson == null) {
        return [];
      }

      final bids = bidJson.map((json) => Bid.fromJson(json)).toList();

      return bids;
    } catch (e) {
      print("[Kontext] Error fetching data: $e");
      return [];
    }
  }
}
