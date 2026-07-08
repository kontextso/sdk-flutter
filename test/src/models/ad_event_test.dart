import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/ad_event.dart';

void main() {
  group('AdEventType.fromString', () {
    test('maps every known event name to the right enum case', () {
      expect(AdEventType.fromString('ad.clicked'), AdEventType.adClicked);
      expect(AdEventType.fromString('ad.viewed'), AdEventType.adViewed);
      expect(AdEventType.fromString('ad.filled'), AdEventType.adFilled);
      expect(AdEventType.fromString('ad.no-fill'), AdEventType.adNoFill);
      expect(AdEventType.fromString('ad.render-started'), AdEventType.adRenderStarted);
      expect(AdEventType.fromString('ad.render-completed'), AdEventType.adRenderCompleted);
      expect(AdEventType.fromString('ad.error'), AdEventType.adError);
      expect(AdEventType.fromString('reward.granted'), AdEventType.rewardGranted);
      expect(AdEventType.fromString('video.started'), AdEventType.videoStarted);
      expect(AdEventType.fromString('video.completed'), AdEventType.videoCompleted);
    });

    test('falls back to unknown for an unrecognized event name', () {
      expect(AdEventType.fromString('pizza.delivered'), AdEventType.unknown);
    });

    test('falls back to unknown for a null name', () {
      expect(AdEventType.fromString(null), AdEventType.unknown);
    });

    test('exposes the raw event-name string via .value', () {
      expect(AdEventType.adClicked.value, 'ad.clicked');
      expect(AdEventType.rewardGranted.value, 'reward.granted');
      expect(AdEventType.unknown.value, 'unknown');
    });
  });

  group('AdEvent.fromJson', () {
    test('parses top-level code and nested payload fields', () {
      final event = AdEvent.fromJson({
        'name': 'ad.clicked',
        'code': 'inlineAd',
        'payload': {
          'id': 'bid-1',
          'content': 'ad body',
          'messageId': 'm-1',
          'url': 'https://advertiser.example',
          'format': 'inline',
          'area': 'cta',
        },
      });

      expect(event.type, AdEventType.adClicked);
      expect(event.code, 'inlineAd');
      expect(event.id, 'bid-1');
      expect(event.content, 'ad body');
      expect(event.messageId, 'm-1');
      expect(event.url, 'https://advertiser.example');
      expect(event.format, 'inline');
      expect(event.area, 'cta');
    });

    test('parses error payload into message and errCode', () {
      final event = AdEvent.fromJson({
        'name': 'ad.error',
        'payload': {'message': 'boom', 'errCode': 'E42'},
      });

      expect(event.type, AdEventType.adError);
      expect(event.message, 'boom');
      expect(event.errCode, 'E42');
    });

    test('returns unknown event with all-null fields when payload is missing', () {
      final event = AdEvent.fromJson({'name': 'ad.no-fill'});
      expect(event.type, AdEventType.adNoFill);
      expect(event.code, isNull);
      expect(event.id, isNull);
      expect(event.content, isNull);
      expect(event.messageId, isNull);
      expect(event.url, isNull);
    });

    test('falls back to unknown type when name is missing', () {
      final event = AdEvent.fromJson({});
      expect(event.type, AdEventType.unknown);
    });

    test('swallows malformed JSON and returns an unknown event', () {
      // payload is not a Json — casting `as Json?` throws → catch block returns unknown event.
      final event = AdEvent.fromJson({
        'name': 'ad.clicked',
        'payload': 'not-a-map',
      });
      expect(event.type, AdEventType.unknown);
    });
  });

  group('AdEvent.copyWith', () {
    test('returns a new instance with overridden fields', () {
      final original = AdEvent(type: AdEventType.adFilled, code: 'inlineAd', id: 'bid-1');
      final updated = original.copyWith(type: AdEventType.adViewed, id: 'bid-2');

      expect(updated.type, AdEventType.adViewed);
      expect(updated.id, 'bid-2');
      expect(updated.code, 'inlineAd');
    });

    test('returns an equivalent event when no overrides are supplied', () {
      final original = AdEvent(type: AdEventType.adFilled, code: 'c', id: 'id', revenue: 1.0);
      final copy = original.copyWith();

      expect(copy.type, original.type);
      expect(copy.code, original.code);
      expect(copy.id, original.id);
      expect(copy.revenue, original.revenue);
    });
  });

  group('AdEvent skip code constants', () {
    test('expose the stable strings used by the server contract', () {
      expect(AdEvent.skipCodeUnFilledBid, 'unfilled_bid');
      expect(AdEvent.skipCodeSessionDisabled, 'session_disabled');
      expect(AdEvent.skipCodeRequestFailed, 'request_failed');
      expect(AdEvent.skipCodeUnknown, 'unknown');
      expect(AdEvent.skipCodeError, 'error');
    });
  });

  group('AdEvent.toString', () {
    test('includes all set fields for diagnostics', () {
      final event = AdEvent(
        type: AdEventType.adClicked,
        code: 'c',
        id: 'i',
        url: 'https://x.y',
      );
      final str = event.toString();
      expect(str, contains('AdEventType.adClicked'));
      expect(str, contains('c'));
      expect(str, contains('i'));
      expect(str, contains('https://x.y'));
    });
  });
}
