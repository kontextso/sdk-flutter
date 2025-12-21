import 'dart:io';

import 'package:flutter/services.dart' show MethodChannel;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;

class SkStoreProductService {
  SkStoreProductService._();

  static SkStoreProductService? _instance;

  factory SkStoreProductService() {
    return _instance ??= SkStoreProductService._();
  }

  static const MethodChannel _channel = MethodChannel('kontext_flutter_sdk/sk_store_product');

  static Future<bool> present({required String appStoreId}) async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod('present', {'appStoreId': appStoreId});
      Logger.debug('SKStoreProduct presented: $result');
      return result == true;
    } catch (e, stack) {
      Logger.exception('Error presenting SKStoreProduct: $e', stack);
      return false;
    }
  }

  static Future<bool> dismiss() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod('dismiss');
      Logger.debug('SKStoreProduct dismissed: $result');
      return result == true;
    } catch (e, stack) {
      Logger.exception('Error dismissing SKStoreProduct: $e',stack);
      return false;
    }
  }
}
