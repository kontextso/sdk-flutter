import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/services.dart' show MethodChannel;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;

class AdAttributionKit {
  AdAttributionKit._();

  static const MethodChannel _channel = MethodChannel('kontext_flutter_sdk/ad_attribution');

  static bool _initialized = false;
  static bool _attributionFrameSet = false;

  static Future<bool> initImpression(String jws) async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod('initImpression', {'jws': jws});
      final success = result == true;
      _initialized = success;
      Logger.debug('AdAttributionKit impression initialized: $success');
      return success;
    } catch (e, stack) {
      _initialized = false;
      Logger.exception('Error initializing AdAttributionKit impression: $e', stack);
      return false;
    }
  }

  static Future<bool> setAttributionFrame(Rect rect) async {
    if (!Platform.isIOS || !_initialized) return false;

    try {
      final result = await _channel.invokeMethod('setAttributionFrame', {
        'x': rect.left,
        'y': rect.top,
        'width': rect.width,
        'height': rect.height,
      });
      final success = result == true;
      _attributionFrameSet = success;
      Logger.debug('AdAttributionKit attribution frame set: $success');
      return success;
    } catch (e, stack) {
      _attributionFrameSet = false;
      Logger.exception('Error setting AdAttributionKit attribution frame: $e', stack);
      return false;
    }
  }

  static Future<void> handleTap(Uri? uri) async {
    if (!Platform.isIOS || !_initialized || !_attributionFrameSet) return;

    try {
      final result = await _channel.invokeMethod('handleTap', {'url': uri?.toString()});
      Logger.debug('AdAttributionKit handle tap: $result');
    } catch (e, stack) {
      Logger.exception('Error handling AdAttributionKit tap: $e', stack);
    }
  }

  static Future<void> beginView() async {
    if (!Platform.isIOS || !_initialized || !_attributionFrameSet) return;

    try {
      final result = await _channel.invokeMethod('beginView');
      Logger.debug('AdAttributionKit view began: $result');
    } catch (e, stack) {
      Logger.exception('Error beginning AdAttributionKit view: $e', stack);
    }
  }

  static Future<void> endView() async {
    if (!Platform.isIOS || !_initialized || !_attributionFrameSet) return;

    try {
      final result = await _channel.invokeMethod('endView');
      Logger.debug('AdAttributionKit view ended: $result');
    } catch (e, stack) {
      Logger.exception('Error ending AdAttributionKit view: $e', stack);
    }
  }

  static Future<void> dispose() async {
    if (!Platform.isIOS || !_initialized) {
      _initialized = false;
      _attributionFrameSet = false;
      return;
    }

    try {
      final result = await _channel.invokeMethod('dispose');
      Logger.debug('AdAttributionKit disposed: $result');
    } catch (e, stack) {
      Logger.exception('Error disposing AdAttributionKit: $e', stack);
    } finally {
      _initialized = false;
      _attributionFrameSet = false;
    }
  }
}
