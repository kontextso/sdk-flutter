import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';

void main() {
  group('Bid.fromJson', () {
    Map<String, dynamic> baseJson({Object? value}) => {
          'bidId': 'bid-1',
          'code': 'code-1',
          'value': value,
          'adDisplayPosition': 'afterAssistantMessage',
        };

    test('accepts integer bid values', () {
      final bid = Bid.fromJson(baseJson(value: 12));

      expect(bid.value, 12);
    });

    test('accepts float values only when they are whole numbers', () {
      final bid = Bid.fromJson(baseJson(value: 12.0));

      expect(bid.value, 12);
    });

    test('returns null for non-integer float values', () {
      final bid = Bid.fromJson(baseJson(value: 12.5));

      expect(bid.value, isNull);
    });

    test('handles null values', () {
      final bid = Bid.fromJson(baseJson());

      expect(bid.value, isNull);
    });

    test('parses numeric string values', () {
      final bid = Bid.fromJson(baseJson(value: '123'));

      expect(bid.value, 123);
    });

    test('returns null for invalid values', () {
      final bid = Bid.fromJson(baseJson(value: {'amount': 12}));

      expect(bid.value, isNull);
    });

    test('returns null for non-numeric strings', () {
      final bid = Bid.fromJson(baseJson(value: '12.5'));

      expect(bid.value, isNull);
    });
  });
}
