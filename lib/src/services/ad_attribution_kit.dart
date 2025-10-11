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

    throw UnimplementedError('setAttributionFrame is not implemented yet.');
  }

  static Future<void> handleTap(String? url) async {
    if (!Platform.isIOS) return;

    throw UnimplementedError('handleTap is not implemented yet.');
  }

  static Future<void> beginView() async {
    if (!Platform.isIOS) return;

    throw UnimplementedError('beginView is not implemented yet.');
  }

  static Future<void> endView() async {
    if (!Platform.isIOS) return;

    throw UnimplementedError('endView is not implemented yet.');
  }

  static Future<void> dispose() async {
    if (!Platform.isIOS) return;

    throw UnimplementedError('dispose is not implemented yet.');
  }
}
