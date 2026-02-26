import 'dart:io';

import 'package:flutter/services.dart' show MethodChannel;
import 'package:kontext_flutter_sdk/src/models/bid.dart' show Skan;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;
import 'package:kontext_flutter_sdk/src/utils/skan_utils.dart';

abstract final class SKStoreProductService {
  static const MethodChannel _channel = MethodChannel('kontext_flutter_sdk/sk_store_product');

  static bool Function() isIOS = () => Platform.isIOS;

  static Future<bool> present(Skan skan) async {
    if (!isIOS()) return false;

    try {
      final result = await _channel.invokeMethod('present', skanToMap(skan));
      Logger.debug('SKStoreProduct presented: $result');
      return result == true;
    } catch (e, stack) {
      Logger.exception('Error presenting SKStoreProduct: $e', stack);
      return false;
    }
  }

  static Future<bool> dismiss() async {
    if (!isIOS()) return false;

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
