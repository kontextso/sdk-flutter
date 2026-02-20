import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:kontext_flutter_sdk/src/services/logger.dart';
import 'package:kontext_flutter_sdk/src/services/tracking_authorization_service.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

class AdvertisingIdService {
  static const _zeroUuid = '00000000-0000-0000-0000-000000000000';
  static const _ch = MethodChannel('kontext_flutter_sdk/advertising_id');

  static bool _didRunStartupFlow = false;
  static Future<void>? _startupFlowFuture;

  @visibleForTesting
  static bool Function() isIOSProvider = _isIOS;

  @visibleForTesting
  static Future<String> Function() iosVersionProvider = _iOSVersion;

  @visibleForTesting
  static Future<TrackingStatus> Function() trackingStatusProvider = _trackingStatus;

  @visibleForTesting
  static Future<TrackingStatus> Function() requestTrackingProvider = _requestTrackingAuthorization;

  @visibleForTesting
  static Future<String?> Function() idfvProvider = _vendorId;

  @visibleForTesting
  static Future<String?> Function() advertisingIdProvider = _advertisingId;

  static Future<void> requestTrackingAuthorization() {
    if (_didRunStartupFlow) {
      return _startupFlowFuture ?? Future.value();
    }

    _didRunStartupFlow = true;
    _startupFlowFuture = _requestTrackingAuthorizationInternal();
    return _startupFlowFuture!;
  }

  static Future<String?> getVendorId() async {
    if (!isIOSProvider()) {
      return null;
    }

    try {
      final vendorId = await idfvProvider();
      return _normalizeIdentifier(vendorId);
    } catch (e, stack) {
      Logger.error('Failed to resolve IDFV: $e', stack);
      return null;
    }
  }

  static Future<String?> getAdvertisingId() async {
    try {
      final advertisingId = await advertisingIdProvider();
      return _normalizeIdentifier(advertisingId);
    } catch (e, stack) {
      Logger.error('Failed to resolve advertising ID: $e', stack);
      return null;
    }
  }

  static Future<({String? vendorId, String? advertisingId})> resolveIds({
    String? vendorIdFallback,
    String? advertisingIdFallback,
  }) async {
    final results = await Future.wait<String?>([
      getVendorId(),
      getAdvertisingId(),
    ]);

    final vendorId = _normalizeIdentifier(results[0]) ?? _normalizeIdentifier(vendorIdFallback);
    final advertisingId = _normalizeIdentifier(results[1]) ?? _normalizeIdentifier(advertisingIdFallback);

    return (
      vendorId: vendorId,
      advertisingId: advertisingId,
    );
  }

  @visibleForTesting
  static void resetForTesting() {
    _didRunStartupFlow = false;
    _startupFlowFuture = null;

    isIOSProvider = _isIOS;
    iosVersionProvider = _iOSVersion;
    trackingStatusProvider = _trackingStatus;
    requestTrackingProvider = _requestTrackingAuthorization;
    idfvProvider = _vendorId;
    advertisingIdProvider = _advertisingId;
  }

  static Future<void> _requestTrackingAuthorizationInternal() async {
    if (!isIOSProvider()) {
      return;
    }

    try {
      final iosVersion = await iosVersionProvider();
      if (!_isVersionAtLeast145(iosVersion)) {
        return;
      }

      final status = await trackingStatusProvider();
      if (status != TrackingStatus.notDetermined) {
        return;
      }

      await requestTrackingProvider();
    } catch (e, stack) {
      Logger.error('Failed to request ATT on startup: $e', stack);
    }
  }

  static String? _normalizeIdentifier(String? rawValue) {
    final normalized = rawValue?.nullIfEmpty;
    if (normalized == null ) {
      return null;
    }
    if (normalized.toLowerCase() == _zeroUuid) {
      return null;
    }
    return normalized;
  }

  // On iOS >=14.0 <14.5, tracking authorization request dialog isn't required in order to get IDFA.
  // In those iOS versions, if we ask for it and the user rejects it we will lose access to IDFA.
  static bool _isVersionAtLeast145(String version) {
    final parts = version.split('.');
    final major = int.tryParse(parts[0]) ?? 0;
    final minor = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    if (major > 14) {
      return true;
    }
    if (major < 14) {
      return false;
    }

    return minor >= 5;
  }

  static bool _isIOS() => Platform.isIOS;

  static Future<String> _iOSVersion() async {
    final info = await DeviceInfoPlugin().iosInfo;
    return info.systemVersion;
  }

  static Future<TrackingStatus> _trackingStatus() {
    return TrackingAuthorizationService.trackingAuthorizationStatus;
  }

  static Future<TrackingStatus> _requestTrackingAuthorization() {
    return TrackingAuthorizationService.requestTrackingAuthorization();
  }

  static Future<String?> _vendorId() async {
    final info = await DeviceInfoPlugin().iosInfo;
    return info.identifierForVendor;
  }

  static Future<String?> _advertisingId() async {
    try {
      return _ch.invokeMethod<String>('getAdvertisingId');
    } catch (e, stack) {
      Logger.error('Failed to fetch advertising ID: $e', stack);
      return null;
    }
  }
}
