import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/services/transparency_consent_framework_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('kontext_flutter_sdk/transparency_consent_framework');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('TransparencyConsentFrameworkService.getTCFData', () {
    test('returns both fields when native layer provides valid data', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getTCFData') {
          return <String, Object?>{
            'gdprApplies': 1,
            'tcString': 'CONSENT-STRING',
          };
        }
        return null;
      });

      final data = await TransparencyConsentFrameworkService.getTCFData();
      expect(data.gdpr, 1);
      expect(data.gdprConsent, 'CONSENT-STRING');
    });

    test('returns gdpr=0 when native reports no GDPR applicability', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return <String, Object?>{'gdprApplies': 0, 'tcString': 'CS'};
      });
      final data = await TransparencyConsentFrameworkService.getTCFData();
      expect(data.gdpr, 0);
    });

    test('treats non-0/1 gdprApplies as null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return <String, Object?>{'gdprApplies': 2, 'tcString': 'CS'};
      });
      final data = await TransparencyConsentFrameworkService.getTCFData();
      expect(data.gdpr, isNull);
    });

    test('treats non-int gdprApplies as null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return <String, Object?>{'gdprApplies': '1', 'tcString': 'CS'};
      });
      final data = await TransparencyConsentFrameworkService.getTCFData();
      expect(data.gdpr, isNull);
    });

    test('treats empty tcString as null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return <String, Object?>{'gdprApplies': 1, 'tcString': ''};
      });
      final data = await TransparencyConsentFrameworkService.getTCFData();
      expect(data.gdprConsent, isNull);
    });

    test('treats non-string tcString as null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return <String, Object?>{'gdprApplies': 1, 'tcString': 42};
      });
      final data = await TransparencyConsentFrameworkService.getTCFData();
      expect(data.gdprConsent, isNull);
    });

    test('returns both null when native returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);
      final data = await TransparencyConsentFrameworkService.getTCFData();
      expect(data.gdpr, isNull);
      expect(data.gdprConsent, isNull);
    });

    test('returns both null when native throws', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'E', message: 'boom');
      });
      final data = await TransparencyConsentFrameworkService.getTCFData();
      expect(data.gdpr, isNull);
      expect(data.gdprConsent, isNull);
    });
  });
}
