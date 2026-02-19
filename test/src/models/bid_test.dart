import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';

void main() {
  group('Bid.fromJson', () {
    Map<String, dynamic> baseJson({
      Object? revenue,
      String position = 'afterAssistantMessage',
      Map<String, dynamic>? akk,
      Map<String, dynamic>? skan,
    }) =>
        {
          'bidId': 'bid-1',
          'code': 'code-1',
          'revenue': revenue,
          'adDisplayPosition': position,
          if (akk != null) 'akk': akk,
          if (skan != null) 'skan': skan,
        };

    // --- revenue ---

    group('revenue', () {
      test('accepts integer values', () {
        final bid = Bid.fromJson(baseJson(revenue: 12));
        expect(bid.revenue, 12.0);
      });

      test('accepts float values', () {
        final bid = Bid.fromJson(baseJson(revenue: 12.0));
        expect(bid.revenue, 12.0);
      });

      test('handles null revenue', () {
        final bid = Bid.fromJson(baseJson());
        expect(bid.revenue, isNull);
      });

      test('parses numeric string values', () {
        final bid = Bid.fromJson(baseJson(revenue: '123'));
        expect(bid.revenue, 123.0);
      });

      test('parses numeric string with whitespace', () {
        final bid = Bid.fromJson(baseJson(revenue: '  45.5  '));
        expect(bid.revenue, 45.5);
      });

      test('returns null for non-numeric string', () {
        final bid = Bid.fromJson(baseJson(revenue: 'abc'));
        expect(bid.revenue, isNull);
      });

      test('returns null for object value', () {
        final bid = Bid.fromJson(baseJson(revenue: {'amount': 12}));
        expect(bid.revenue, isNull);
      });

      test('returns null for infinity', () {
        final bid = Bid.fromJson(baseJson(revenue: double.infinity));
        expect(bid.revenue, isNull);
      });

      test('returns null for negative infinity', () {
        final bid = Bid.fromJson(baseJson(revenue: double.negativeInfinity));
        expect(bid.revenue, isNull);
      });

      test('returns null for NaN', () {
        final bid = Bid.fromJson(baseJson(revenue: double.nan));
        expect(bid.revenue, isNull);
      });
    });

    // --- position ---

    group('position', () {
      test('parses afterAssistantMessage', () {
        final bid = Bid.fromJson(baseJson(position: 'afterAssistantMessage'));
        expect(bid.position, AdDisplayPosition.afterAssistantMessage);
        expect(bid.isAfterAssistantMessage, isTrue);
        expect(bid.isAfterUserMessage, isFalse);
      });

      test('parses afterUserMessage', () {
        final bid = Bid.fromJson(baseJson(position: 'afterUserMessage'));
        expect(bid.position, AdDisplayPosition.afterUserMessage);
        expect(bid.isAfterUserMessage, isTrue);
        expect(bid.isAfterAssistantMessage, isFalse);
      });

      test('falls back to afterAssistantMessage for unknown position', () {
        final bid = Bid.fromJson(baseJson(position: 'unknownPosition'));
        expect(bid.position, AdDisplayPosition.afterAssistantMessage);
      });

      test('falls back to afterAssistantMessage for missing position', () {
        final json = {
          'bidId': 'bid-1',
          'code': 'code-1',
          'revenue': null,
        };
        final bid = Bid.fromJson(json);
        expect(bid.position, AdDisplayPosition.afterAssistantMessage);
      });
    });

    // --- akk ---

    group('akk', () {
      test('parses valid akk object', () {
        final bid = Bid.fromJson(baseJson(akk: {'jws': 'token-123'}));
        expect(bid.akk, isNotNull);
        expect(bid.akk!.jws, 'token-123');
      });

      test('returns null akk when not present', () {
        final bid = Bid.fromJson(baseJson());
        expect(bid.akk, isNull);
      });

      test('returns null akk when jws is missing', () {
        final bid = Bid.fromJson(baseJson(akk: {}));
        expect(bid.akk, isNull);
      });

      test('returns null akk when akk is wrong type', () {
        final json = baseJson()..['akk'] = 'not-a-map';
        final bid = Bid.fromJson(json);
        expect(bid.akk, isNull);
      });
    });

    // --- skan ---

    group('skan', () {
      Map<String, dynamic> validSkan({Map<String, dynamic> overrides = const {}}) => {
            'version': '4.0',
            'network': 'network-id',
            'itunesItem': 'itunes-item',
            'sourceApp': 'source-app',
            ...overrides,
          };

      test('parses valid skan object with required fields only', () {
        final bid = Bid.fromJson(baseJson(skan: validSkan()));
        expect(bid.skan, isNotNull);
        expect(bid.skan!.version, '4.0');
        expect(bid.skan!.network, 'network-id');
        expect(bid.skan!.itunesItem, 'itunes-item');
        expect(bid.skan!.sourceApp, 'source-app');
        expect(bid.skan!.sourceIdentifier, isNull);
        expect(bid.skan!.campaign, isNull);
        expect(bid.skan!.fidelities, isNull);
        expect(bid.skan!.nonce, isNull);
        expect(bid.skan!.timestamp, isNull);
        expect(bid.skan!.signature, isNull);
      });

      test('parses skan with all optional fields', () {
        final bid = Bid.fromJson(baseJson(
          skan: validSkan(overrides: {
            'sourceIdentifier': 'src-id',
            'campaign': 'campaign-1',
            'nonce': 'nonce-abc',
            'timestamp': '1700000000',
            'signature': 'sig-xyz',
          }),
        ));
        expect(bid.skan!.sourceIdentifier, 'src-id');
        expect(bid.skan!.campaign, 'campaign-1');
        expect(bid.skan!.nonce, 'nonce-abc');
        expect(bid.skan!.timestamp, '1700000000');
        expect(bid.skan!.signature, 'sig-xyz');
      });

      test('parses skan with fidelities', () {
        final bid = Bid.fromJson(baseJson(
          skan: validSkan(overrides: {
            'fidelities': [
              {
                'fidelity': 1,
                'signature': 'sig-1',
                'nonce': 'nonce-1',
                'timestamp': '1700000000',
              },
              {
                'fidelity': 0,
                'signature': 'sig-0',
                'nonce': 'nonce-0',
                'timestamp': '1700000001',
              },
            ],
          }),
        ));
        expect(bid.skan!.fidelities, hasLength(2));
        expect(bid.skan!.fidelities![0].fidelity, 1);
        expect(bid.skan!.fidelities![1].fidelity, 0);
      });

      test('filters out invalid fidelity entries, keeps valid ones', () {
        final bid = Bid.fromJson(baseJson(
          skan: validSkan(overrides: {
            'fidelities': [
              {'fidelity': 1, 'signature': 'sig-1', 'nonce': 'nonce-1', 'timestamp': 'ts-1'},
              {'fidelity': 'not-an-int', 'signature': 'sig-0', 'nonce': 'nonce-0', 'timestamp': 'ts-0'},
            ],
          }),
        ));
        expect(bid.skan!.fidelities, hasLength(1));
        expect(bid.skan!.fidelities![0].fidelity, 1);
      });

      test('returns null skan when not present', () {
        final bid = Bid.fromJson(baseJson());
        expect(bid.skan, isNull);
      });

      test('returns null skan when a required field is missing', () {
        final bid = Bid.fromJson(baseJson(skan: validSkan(overrides: {'network': null})));
        expect(bid.skan, isNull);
      });

      test('returns null skan when skan is wrong type', () {
        final json = baseJson()..['skan'] = 'not-a-map';
        final bid = Bid.fromJson(json);
        expect(bid.skan, isNull);
      });

      test('returns null skan when all required fields are missing', () {
        final bid = Bid.fromJson(baseJson(skan: {}));
        expect(bid.skan, isNull);
      });
    });

    // --- equality ---

    group('equality', () {
      test('two bids with same values are equal', () {
        final a = Bid.fromJson({
          'bidId': 'bid-1',
          'code': 'code-1',
          'revenue': 10.0,
          'adDisplayPosition': 'afterUserMessage',
        });
        final b = Bid.fromJson({
          'bidId': 'bid-1',
          'code': 'code-1',
          'revenue': 10.0,
          'adDisplayPosition': 'afterUserMessage',
        });
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('two bids with different ids are not equal', () {
        final a = Bid.fromJson({'bidId': 'bid-1', 'code': 'code-1', 'adDisplayPosition': 'afterAssistantMessage'});
        final b = Bid.fromJson({'bidId': 'bid-2', 'code': 'code-1', 'adDisplayPosition': 'afterAssistantMessage'});
        expect(a, isNot(equals(b)));
      });

      test('two bids with different akk are not equal', () {
        final a = Bid.fromJson({'bidId': 'bid-1', 'code': 'code-1', 'adDisplayPosition': 'afterAssistantMessage', 'akk': {'jws': 'token-a'}});
        final b = Bid.fromJson({'bidId': 'bid-1', 'code': 'code-1', 'adDisplayPosition': 'afterAssistantMessage', 'akk': {'jws': 'token-b'}});
        expect(a, isNot(equals(b)));
      });
    });

    // --- toString ---

    group('toString', () {
      test('includes all fields', () {
        final bid = Bid.fromJson({
          'bidId': 'bid-1',
          'code': 'code-1',
          'revenue': 9.99,
          'adDisplayPosition': 'afterUserMessage',
        });
        final str = bid.toString();
        expect(str, contains('bid-1'));
        expect(str, contains('code-1'));
        expect(str, contains('9.99'));
        expect(str, contains('afterUserMessage'));
      });
    });
  });
}