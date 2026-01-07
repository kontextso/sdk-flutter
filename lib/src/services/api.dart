import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/character.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/device_app_info.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/models/regulatory.dart';
import 'package:kontext_flutter_sdk/src/services/transparency_consent_framework_service.dart';
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
    this.skip,
    this.skipCode,
  });

  final String? sessionId;
  final List<Bid> bids;
  final int? statusCode;
  final LogLevel? remoteLogLevel;
  final String? error;
  final String? errorCode;
  final bool? permanentError;
  final bool? skip;
  final String? skipCode;
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
    required String conversationId,
    required String userId,
    String? userEmail,
    required List<String> enabledPlacementCodes,
    required List<Message> messages,
    String? sessionId,
    String? vendorId,
    String? advertisingId,
    Regulatory? regulatory,
    Character? character,
    String? variantId,
    String? iosAppStoreId,
    required bool isDisabled,
  }) async {
    late final DeviceAppInfo device;
    try {
      device = await (deviceInfoProvider ?? DeviceAppInfo.init)(iosAppStoreId: iosAppStoreId);
    } catch (_) {
      device = DeviceAppInfo.empty();
    }

    final tcfData = await TransparencyConsentFrameworkService.getTCFData();

    try {
      final deviceJson = await device.toJsonFresh();

      final vendor = vendorId?.nullIfEmpty;
      final advertising = advertisingId?.nullIfEmpty;
      final variant = variantId?.nullIfEmpty;

      final regulatoryObj = (regulatory ?? const Regulatory()).copyWith(
        gdpr: tcfData.gdpr,
        gdprConsent: tcfData.gdprConsent,
      );

      final result = await _client.post(
        '/preload',
        body: {
          'publisherToken': publisherToken,
          'conversationId': conversationId,
          'userId': userId,
          if (userEmail != null) 'userEmail': userEmail,
          'enabledPlacementCodes': enabledPlacementCodes,
          'messages': messages.map((message) => message.toJson()).toList(),
          if (sessionId != null) 'sessionId': sessionId,
          if (vendor != null) 'vendorId': vendor,
          if (advertising != null) 'advertisingId': advertising,
          'sdk': {
            'name': kSdkLabel,
            'version': kSdkVersion,
            'platform': Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web'),
          },
          'app': device.appInfo.toJson(),
          'device': deviceJson,
          if (!regulatoryObj.isEmpty) 'regulatory': regulatoryObj.toJson(),
          if (character != null) 'character': character.toJson(),
          if (variant != null) 'variantId': variant,
        },
        headers: {
          'Kontextso-Publisher-Token': publisherToken,
          'Kontextso-Is-Disabled': isDisabled ? '1' : '0',
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
      final skip = data['skip'] as bool?;
      final skipCode = data['skipCode'] as String?;

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
        skip: skip,
        skipCode: skipCode,
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
