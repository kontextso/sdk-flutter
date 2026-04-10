import 'dart:io' show Platform;

import 'package:flutter/services.dart';

class OMSDKService {
  OMSDKService._();

  static const MethodChannel _channel = MethodChannel('kontext_flutter_sdk/omsdk');

  static Future<bool> activate() async {
    if (!Platform.isIOS) {
      return false;
    }

    final isActive = await _channel.invokeMethod<bool>('activate');
    return isActive ?? false;
  }
}
