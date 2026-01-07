import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/regulatory.dart';

void main() {
  group('Regulatory.toJson', () {
    test('returns all non-null properties', () {
      final regulatory = const Regulatory(
        gdpr: 1,
        gdprConsent: 'consentString123',
        coppa: 0,
        gpp: 'gppStringABC',
        gppSid: [2, 6],
        usPrivacy: '1YNN',
      );

      final json = regulatory.toJson();

      expect(json, {
        'gdpr': 1,
        'gdprConsent': 'consentString123',
        'coppa': 0,
        'gpp': 'gppStringABC',
        'gppSid': [2, 6],
        'usPrivacy': '1YNN',
      });
    });

    test('omits null and empty-string values', () {
      final regulatory = const Regulatory(
        gdprConsent: '',
        gpp: '',
        usPrivacy: '',
      );

      final json = regulatory.toJson();

      expect(json, isEmpty);
    });

    test('includes only provided fields', () {
      final regulatory = const Regulatory(
        gdpr: 1,
        coppa: 1,
      );

      final json = regulatory.toJson();

      expect(json.keys, containsAll(['gdpr', 'coppa']));
      expect(json.length, 2);
      expect(json['gdpr'], 1);
      expect(json['coppa'], 1);
    });
  });
}
