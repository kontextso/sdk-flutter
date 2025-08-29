import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel, MissingPluginException;
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/character.dart';
import 'package:kontext_flutter_sdk/src/services/device_app_info.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/models/regulatory.dart';
import 'package:kontext_flutter_sdk/src/utils/constants.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

const MethodChannel _soundChannel = MethodChannel('kontext_flutter_sdk/device_sound');

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
  Future<Json?> Function({String? iosAppStoreId})? deviceInfoProvider;

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
    Json? device;
    try {
      device = await (deviceInfoProvider ?? _getDeviceAppInfo)(iosAppStoreId: iosAppStoreId);
    } catch (e, stack) {
      Logger.exception(e, stack);
      device = null;
    }

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
          'device': device,
          'messages': messages.map((message) => message.toJson()).toList(),
          'enabledPlacementCodes': enabledPlacementCodes,
          'character': character?.toJson(),
          'vendorId': vendorId?.nullIfEmpty,
          'variantId': variantId?.nullIfEmpty,
          'advertisingId': advertisingId?.nullIfEmpty,
          'regulatory': {
            'gdpr': regulatory?.gdpr,
            'gdprConsent': regulatory?.gdprConsent?.nullIfEmpty,
            'coppa': regulatory?.coppa,
            'gpp': regulatory?.gpp?.nullIfEmpty,
            'gppSid': regulatory?.gppSid?.nullIfEmpty,
            'usPrivacy': regulatory?.usPrivacy?.nullIfEmpty,
          },
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

  Future<Json?> _getDeviceAppInfo({String? iosAppStoreId}) async {
    try {
      await DeviceAppInfo.init(iosAppStoreId: iosAppStoreId);
      final device = DeviceAppInfo.instance?.toJson();

      if (device != null) {
        device['soundOn'] = await _isSoundOn();
      }

      return device;
    } catch (e, stack) {
      Logger.exception(e, stack);
      return null;
    }
  }

  Future<bool> _isSoundOn() async {
    try {
      final isSoundOn = await _soundChannel.invokeMethod<bool>('isSoundOn');
      return isSoundOn ?? true;
    } on MissingPluginException catch (e) {
      Logger.info(e.toString());
      return true;
    } catch (e, stack) {
      Logger.exception(e, stack);
      return true;
    }
  }
}
