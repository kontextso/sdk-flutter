import 'package:flutter/services.dart' show MethodChannel;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;

class TransparencyConsentFrameworkService {
  static const _ch = MethodChannel('kontext_flutter_sdk/transparency_consent_framework');

  static Future<({int? gdpr, String? gdprConsent})> getTCFData() async {
    try {
      final m = await _ch.invokeMapMethod<String, dynamic>('getTCFData');
      if (m == null) {
        return (gdpr: null, gdprConsent: null);
      }

      final rawGdprApplies = m['gdprApplies'];
      final gdpr = (rawGdprApplies is int && (rawGdprApplies == 0 || rawGdprApplies == 1))
          ? rawGdprApplies
          : null;
      final rawTcString = m['tcString'];
      final gdprConsent = (rawTcString is String && rawTcString.isNotEmpty)
          ? rawTcString
          : null;

      return (gdpr: gdpr, gdprConsent: gdprConsent);
    } catch (e, stack) {
      Logger.error(e.toString(), stack);
      return (gdpr: null, gdprConsent: null);
    }
  }
}