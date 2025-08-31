import 'package:flutter/foundation.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/character.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/device_app_info.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/models/regulatory.dart';
import 'package:kontext_flutter_sdk/src/utils/constants.dart';
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

  @visibleForTesting
  Future<DeviceAppInfo> Function({String? iosAppStoreId})? deviceInfoProvider;

  factory Api() {
    return _instance ??= Api._internal();
  }

  static void resetInstance() {
    _instance = null;
  }

  Future<PreloadResponse> preload({
    required String publisherToken,
    required String userId,
    required String conversationId,
    String? sessionId,
    required List<Message> messages,
    required List<String> enabledPlacementCodes,
    Character? character,
    String? vendorId,
    String? variantId,
    String? advertisingId,
    String? iosAppStoreId,
    Regulatory? regulatory,
  }) async {
    final init = (deviceInfoProvider ?? DeviceAppInfo.init);
    final device = await init(iosAppStoreId: iosAppStoreId)
        .catchError((_) => DeviceAppInfo.empty());
    final deviceJson = await device.toJsonFresh();

    try {
      final result = await _client.post(
        '/preload',
        body: {
          'sdk': kSdkLabel,
          'sdkVersion': kSdkVersion,
          'publisherToken': publisherToken,
          'userId': userId,
          'conversationId': conversationId,
          'sessionId': sessionId,
          'messages': messages.map((message) => message.toJson()).toList(),
          'enabledPlacementCodes': enabledPlacementCodes,
          'character': character?.toJson(),
          'vendorId': vendorId?.nullIfEmpty,
          'variantId': variantId?.nullIfEmpty,
          'advertisingId': advertisingId?.nullIfEmpty,
          'app': device.appInfo.toJson(),
          'device': deviceJson,
          if (regulatory != null) 'regulatory': regulatory.toJson(),
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
