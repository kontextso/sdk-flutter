import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/services.dart' show MethodChannel;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;

class AdAttributionKit {
  AdAttributionKit._();

  static AdAttributionKit? _instance;

  factory AdAttributionKit() {
    return _instance ??= AdAttributionKit._();
  }

  static const MethodChannel _channel = MethodChannel('kontext_flutter_sdk/ad_attribution');

  static Future<void> initImpression(String jws) async {
    if (!Platform.isIOS) return;

    try {
      final result = await _channel.invokeMethod('initImpression', {'jws': jws});
      Logger.debug('AdAttributionKit impression initialized: $result');
    } catch (e, stack) {
      Logger.exception('Error initializing AdAttributionKit impression: $e', stack);
    }
  }

  static Future<void> setAttributionFrame(Rect rect) async {
    if (!Platform.isIOS) return;

    try {
      final result = await _channel.invokeMethod('setAttributionFrame', {
        'x': rect.left,
        'y': rect.top,
        'width': rect.width,
        'height': rect.height,
      });
      Logger.debug('AdAttributionKit attribution frame set: $result');
    } catch (e, stack) {
      Logger.exception('Error setting AdAttributionKit attribution frame: $e', stack);
    }
  }

  static Future<void> handleTap(Uri? uri) async {
    if (!Platform.isIOS) return;

    try {
      final result = await _channel.invokeMethod('handleTap', {'url': uri?.toString()});
      Logger.debug('AdAttributionKit handle tap: $result');
    } catch (e, stack) {
      Logger.exception('Error handling AdAttributionKit tap: $e', stack);
    }
  }

  static Future<void> beginView() async {
    if (!Platform.isIOS) return;

    try {
      final result = await _channel.invokeMethod('beginView');
      Logger.debug('AdAttributionKit view began: $result');
    } catch (e, stack) {
      Logger.exception('Error beginning AdAttributionKit view: $e', stack);
    }
  }

  static Future<void> endView() async {
    if (!Platform.isIOS) return;

    try {
      final result = await _channel.invokeMethod('endView');
      Logger.debug('AdAttributionKit view ended: $result');
    } catch (e, stack) {
      Logger.exception('Error ending AdAttributionKit view: $e', stack);
    }
  }

  static Future<void> dispose() async {
    if (!Platform.isIOS) return;

    throw UnimplementedError('dispose is not implemented yet.');
  }
}
