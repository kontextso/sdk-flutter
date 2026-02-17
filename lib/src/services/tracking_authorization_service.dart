import 'dart:io' show Platform;

import 'package:flutter/services.dart' show MethodChannel;
import 'package:kontext_flutter_sdk/src/services/logger.dart';

enum TrackingStatus {
  /// The user has not yet received an authorization request dialog.
  notDetermined,

  /// The device is restricted and the system cannot show a request dialog.
  restricted,

  /// The user denied authorization for tracking.
  denied,

  /// The user authorized tracking.
  authorized,

  /// The platform does not support ATT.
  notSupported,
}

class TrackingAuthorizationService {
  static const _ch = MethodChannel('kontext_flutter_sdk/tracking_authorization');

  static Future<TrackingStatus> get trackingAuthorizationStatus async {
    if (!Platform.isIOS) {
      return TrackingStatus.notSupported;
    }
    return _invokeStatusMethod('getTrackingAuthorizationStatus');
  }

  static Future<TrackingStatus> requestTrackingAuthorization() async {
    if (!Platform.isIOS) {
      return TrackingStatus.notSupported;
    }
    return _invokeStatusMethod('requestTrackingAuthorization');
  }

  static Future<TrackingStatus> _invokeStatusMethod(String method) async {
    try {
      final rawStatus = await _ch.invokeMethod<int>(method);
      return _mapRawStatus(rawStatus);
    } catch (e, stack) {
      Logger.error('Failed to invoke $method: $e', stack);
      return TrackingStatus.notSupported;
    }
  }

  static TrackingStatus _mapRawStatus(int? rawStatus) {
    if (rawStatus == null || rawStatus < 0 || rawStatus >= TrackingStatus.values.length) {
      return TrackingStatus.notSupported;
    }
    return TrackingStatus.values[rawStatus];
  }
}
