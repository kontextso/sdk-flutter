import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';

void main() {
  group('Bid.fromJson', () {
    Map<String, dynamic> baseJson({Object? value}) => {
          'bidId': 'bid-1',
          'code': 'code-1',
          'revenue': value,
          'adDisplayPosition': 'afterAssistantMessage',
        };

    test('accepts integer bid values', () {
      final bid = Bid.fromJson(baseJson(value: 12));
      expect(bid.revenue, 12.0);
    });

    test('accepts float values', () {
      final bid = Bid.fromJson(baseJson(value: 12.0));
      expect(bid.revenue, 12.0);
    });

    test('handles null values', () {
      final bid = Bid.fromJson(baseJson());
      expect(bid.revenue, isNull);
    });

    test('parses numeric string values', () {
      final bid = Bid.fromJson(baseJson(value: '123'));
      expect(bid.revenue, 123.0);
    });

    test('returns null for invalid values', () {
      final bid = Bid.fromJson(baseJson(value: {'amount': 12}));
      expect(bid.revenue, isNull);
    });
  });
}
