import 'dart:io';

import 'package:flutter/services.dart' show MethodChannel;
import 'package:kontext_flutter_sdk/src/models/bid.dart' show Skan;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;

abstract final class SKStoreProductService {
  static const MethodChannel _channel = MethodChannel('kontext_flutter_sdk/sk_store_product');

  static bool Function() isIOS = () => Platform.isIOS;

  static Future<bool> present(Skan skan) async {
    if (!isIOS()) return false;

    try {
      final result = await _channel.invokeMethod('present', _skanToMap(skan));
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

  static Map<String, dynamic> _skanToMap(Skan skan) => {
    'version': skan.version,
    'network': skan.network,
    'itunesItem': skan.itunesItem,
    'sourceApp': skan.sourceApp,
    if (skan.sourceIdentifier != null) 'sourceIdentifier': skan.sourceIdentifier,
    if (skan.campaign != null) 'campaign': skan.campaign,
    if (skan.nonce != null) 'nonce': skan.nonce,
    if (skan.timestamp != null) 'timestamp': skan.timestamp,
    if (skan.signature != null) 'signature': skan.signature,
    if (skan.fidelities != null)
      'fidelities': skan.fidelities!
          .map((f) => {
                'fidelity': f.fidelity,
                'nonce': f.nonce,
                'timestamp': f.timestamp,
                'signature': f.signature,
              })
          .toList(),
  };
}
