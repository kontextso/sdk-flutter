import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/services.dart' show MethodChannel, PlatformException;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;

class AdAttributionKit {
  AdAttributionKit._();

  static const MethodChannel _channel = MethodChannel('kontext_flutter_sdk/ad_attribution_kit');

  static bool _impressionReady = false;
  static bool _attributionFrameSet = false;

  static Future<bool> initImpression(String jws) async {
    if (!Platform.isIOS) return false;

    // Reset state for new impression
    _attributionFrameSet = false;

    try {
      final result = await _channel.invokeMethod('initImpression', {'jws': jws});
      final success = result == true;
      _impressionReady = success;
      Logger.debug('AdAttributionKit impression initialized: $success');
      return success;
    } on PlatformException catch (e) {
      _impressionReady = false;
      Logger.exception('Native error initializing AdAttributionKit impression: ${e.code} - ${e.message}', StackTrace.current);
      return false;
    } catch (e, stack) {
      _impressionReady = false;
      Logger.exception('Error initializing AdAttributionKit impression: $e', stack);
      return false;
    }
  }

  static Future<bool> setAttributionFrame(Rect rect) async {
    if (!Platform.isIOS || !_impressionReady) return false;

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
    } on PlatformException catch (e) {
      _attributionFrameSet = false;
      Logger.exception('Native error setting AdAttributionKit attribution frame: ${e.code} - ${e.message}', StackTrace.current);
      return false;
    } catch (e, stack) {
      _attributionFrameSet = false;
      Logger.exception('Error setting AdAttributionKit attribution frame: $e', stack);
      return false;
    }
  }

  static Future<bool> handleTap(Uri? uri) async {
    if (!Platform.isIOS || !_impressionReady) return false;

    // Only require attribution frame for regular tap (no URI)
    if (uri == null && !_attributionFrameSet) return false;

    try {
      final result = await _channel.invokeMethod('handleTap', {'url': uri?.toString()});
      final success = result == true;
      Logger.debug('AdAttributionKit handle tap: $result');
      return success && uri != null;
    } on PlatformException catch (e) {
      Logger.exception('Native error handling AdAttributionKit tap: ${e.code} - ${e.message}', StackTrace.current);
      return false;
    } catch (e, stack) {
      Logger.exception('Error handling AdAttributionKit tap: $e', stack);
      return false;
    }
  }

  static Future<void> beginView() async {
    if (!Platform.isIOS || !_impressionReady) return;

    try {
      final result = await _channel.invokeMethod('beginView');
      Logger.debug('AdAttributionKit view began: $result');
    } on PlatformException catch (e) {
      Logger.exception('Native error beginning AdAttributionKit view: ${e.code} - ${e.message}', StackTrace.current);
    } catch (e, stack) {
      Logger.exception('Error beginning AdAttributionKit view: $e', stack);
    }
  }

  static Future<void> endView() async {
    if (!Platform.isIOS || !_impressionReady) return;

    try {
      final result = await _channel.invokeMethod('endView');
      Logger.debug('AdAttributionKit view ended: $result');
    } on PlatformException catch (e) {
      Logger.exception('Native error ending AdAttributionKit view: ${e.code} - ${e.message}', StackTrace.current);
    } catch (e, stack) {
      Logger.exception('Error ending AdAttributionKit view: $e', stack);
    }
  }

  static Future<void> dispose() async {
    _impressionReady = false;
    _attributionFrameSet = false;

    if (!Platform.isIOS) return;

    try {
      final result = await _channel.invokeMethod('dispose');
      Logger.debug('AdAttributionKit disposed: $result');
    } on PlatformException catch (e) {
      Logger.exception('Native error disposing AdAttributionKit: ${e.code} - ${e.message}', StackTrace.current);
    } catch (e, stack) {
      Logger.exception('Error disposing AdAttributionKit: $e', stack);
    }
  }
}