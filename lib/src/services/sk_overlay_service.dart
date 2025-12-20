import 'dart:io';

import 'package:flutter/services.dart' show MethodChannel;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;

enum SKOverlayPosition { bottom, bottomRaised }

class SKOverlayService {
  SKOverlayService._();

  static SKOverlayService? _instance;

  factory SKOverlayService() {
    return _instance ??= SKOverlayService._();
  }

  static const MethodChannel _channel = MethodChannel('kontext_flutter_sdk/sk_overlay');

  static Future<bool> present({
    required String appStoreId,
    required SKOverlayPosition position,
    bool dismissible = true,
  }) async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod('present', {
        'appStoreId': appStoreId,
        'position': position.name,
        'dismissible': dismissible,
      });
      Logger.debug('SKOverlay presented: $result');
      return result == true;
    } catch (e, stack) {
      Logger.exception('Error presenting SKOverlay: $e', stack);
      return false;
    }
  }

  static Future<bool> dismiss() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod('dismiss');
      Logger.debug('SKOverlay dismissed: $result');
      return result == true;
    } catch (e, stack) {
      Logger.exception('Error dismissing SKOverlay: $e', stack);
      return false;
    }
  }
}
