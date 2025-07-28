import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/character.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';

class PreloadResult {
  const PreloadResult({
    required this.sessionId,
    required this.bids,
  });

  final String? sessionId;
  final List<Bid> bids;
}

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

  Future<PreloadResult> preload({
    required String publisherToken,
    required String userId,
    required String conversationId,
    String? sessionId,
    required List<Message> messages,
    Character? character,
    String? vendorId,
    String? variantId,
    String? advertisingId,
  }) async {
    try {
      final response = await _client.post(
        '/preload',
        body: {
          'publisherToken': publisherToken,
          'userId': userId,
          'conversationId': conversationId,
          if (sessionId != null) 'sessionId': sessionId,
          'messages': messages.map((message) => message.toJson()).toList(),
          if (character != null) 'character': character.toJson(),
          if (vendorId != null) 'vendorId': vendorId,
          if (variantId != null) 'variantId': variantId,
          if (advertisingId != null) 'advertisingId': advertisingId,
        },
      );

      print("[Kontext] Preload response: $response");
      final sessionIdJson = response['sessionId'] as String?;
      final bidJson = response['bids'] as List<dynamic>?;

      return PreloadResult(
        sessionId: sessionIdJson,
        bids: bidJson?.map((json) => Bid.fromJson(json)).toList() ?? [],
      );
    } catch (e) {
      print("[Kontext] Error fetching data: $e");
      return const PreloadResult(
        sessionId: null,
        bids: [],
      );
    }
  }
}
