import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/character.dart';
import 'package:kontext_flutter_sdk/src/services/device_app_info.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

class PreloadResponse {
  const PreloadResponse({
    required this.sessionId,
    required this.bids,
    this.statusCode,
    this.remoteLogLevel,
    this.error,
    this.errorCode,
    this.permanentError,
  });

  final String? sessionId;
  final List<Bid> bids;
  final int? statusCode;
  final LogLevel? remoteLogLevel;
  final String? error;
  final String? errorCode;
  final bool? permanentError;
}

class Api {
  Api._internal() : _client = HttpClient();

  final HttpClient _client;

  static Api? _instance;

  factory Api() {
    return _instance ??= Api._internal();
  }

  Future<PreloadResponse> preload({
    required String publisherToken,
    required String userId,
    required String conversationId,
    String? sessionId,
    required List<Message> messages,
    Character? character,
    String? vendorId,
    String? variantId,
    String? advertisingId,
    String? iosAppStoreId,
  }) async {
    try {
      final device = DeviceAppInfo.instance?.toJson();
      final result = await _client.post(
        '/preload',
        body: {
          'publisherToken': publisherToken,
          'userId': userId,
          'conversationId': conversationId,
          if (sessionId != null) 'sessionId': sessionId,
          if (device != null) 'device': device,
          'messages': messages.map((message) => message.toJson()).toList(),
          if (character != null) 'character': character.toJson(),
          if (vendorId != null) 'vendorId': vendorId,
          if (variantId != null) 'variantId': variantId,
          if (advertisingId != null) 'advertisingId': advertisingId,
        },
      );

      final statusCode = result.response.statusCode;
      final data = result.data;

      final sessionIdJson = data['sessionId'] as String?;
      final bidJson = data['bids'] as List<dynamic>?;
      final remoteLogLevel = data['remoteLogLevel'] as String?;
      final error = data['error'] as String?;
      final errorCode = data['errCode'] as String?;
      final permanentError = data['permanent'] as bool?;

      return PreloadResponse(
        sessionId: sessionIdJson,
        bids: bidJson?.map((json) => Bid.fromJson(json)).toList() ?? [],
        statusCode: statusCode,
        remoteLogLevel: remoteLogLevel != null
            ? LogLevel.values.firstWhereOrElse(
                (level) => level.name == remoteLogLevel,
              )
            : null,
        error: error,
        errorCode: errorCode,
        permanentError: permanentError,
      );
    } catch (e, stack) {
      Logger.exception(e, stack);
      return const PreloadResponse(
        sessionId: null,
        bids: [],
      );
    }
  }
}
