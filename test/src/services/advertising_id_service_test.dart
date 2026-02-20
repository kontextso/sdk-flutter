import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/services/advertising_id_service.dart';
import 'package:kontext_flutter_sdk/src/services/tracking_authorization_service.dart';

void main() {
  setUp(() {
    AdvertisingIdService.resetForTesting();
  });

  tearDown(() {
    AdvertisingIdService.resetForTesting();
  });

  test('requests ATT on iOS 14.5+ when status is not determined', () async {
    var requestCount = 0;

    AdvertisingIdService.isIOSProvider = () => true;
    AdvertisingIdService.iosVersionProvider = () async => '16.0';
    AdvertisingIdService.trackingStatusProvider = () async => TrackingStatus.notDetermined;
    AdvertisingIdService.requestTrackingProvider = () async {
      requestCount += 1;
      return TrackingStatus.authorized;
    };

    await AdvertisingIdService.requestTrackingAuthorization();

    expect(requestCount, 1);
  });

  test('does not request ATT on iOS below 14.5', () async {
    var statusCount = 0;
    var requestCount = 0;

    AdvertisingIdService.isIOSProvider = () => true;
    AdvertisingIdService.iosVersionProvider = () async => '14.4';
    AdvertisingIdService.trackingStatusProvider = () async {
      statusCount += 1;
      return TrackingStatus.notDetermined;
    };
    AdvertisingIdService.requestTrackingProvider = () async {
      requestCount += 1;
      return TrackingStatus.authorized;
    };

    await AdvertisingIdService.requestTrackingAuthorization();

    expect(statusCount, 0);
    expect(requestCount, 0);
  });

  test('does not request ATT on non-iOS', () async {
    var requestCount = 0;

    AdvertisingIdService.isIOSProvider = () => false;
    AdvertisingIdService.requestTrackingProvider = () async {
      requestCount += 1;
      return TrackingStatus.authorized;
    };

    await AdvertisingIdService.requestTrackingAuthorization();

    expect(requestCount, 0);
  });

  test('startup ATT flow runs only once per app run', () async {
    var statusCount = 0;
    var requestCount = 0;
    final completer = Completer<TrackingStatus>();

    AdvertisingIdService.isIOSProvider = () => true;
    AdvertisingIdService.iosVersionProvider = () async => '17.1';
    AdvertisingIdService.trackingStatusProvider = () async {
      statusCount += 1;
      return TrackingStatus.notDetermined;
    };
    AdvertisingIdService.requestTrackingProvider = () {
      requestCount += 1;
      return completer.future;
    };

    final first = AdvertisingIdService.requestTrackingAuthorization();
    final second = AdvertisingIdService.requestTrackingAuthorization();

    completer.complete(TrackingStatus.authorized);
    await Future.wait([first, second]);
    await AdvertisingIdService.requestTrackingAuthorization();

    expect(statusCount, 1);
    expect(requestCount, 1);
  });

  test('normalizes identifiers and prefers service values', () async {
    AdvertisingIdService.isIOSProvider = () => true;
    AdvertisingIdService.idfvProvider = () async => ' service-idfv ';
    AdvertisingIdService.advertisingIdProvider = () async => '00000000-0000-0000-0000-000000000000';

    final ids = await AdvertisingIdService.resolveIds(
      vendorIdFallback: 'fallback-idfv',
      advertisingIdFallback: 'fallback-idfa',
    );

    expect(ids.vendorId, 'service-idfv');
    expect(ids.advertisingId, 'fallback-idfa');
  });

  test('returns null ids when service and fallback values are empty', () async {
    AdvertisingIdService.isIOSProvider = () => true;
    AdvertisingIdService.idfvProvider = () async => '';
    AdvertisingIdService.advertisingIdProvider = () async => '  ';

    final ids = await AdvertisingIdService.resolveIds(
      vendorIdFallback: '   ',
      advertisingIdFallback: '',
    );

    expect(ids.vendorId, isNull);
    expect(ids.advertisingId, isNull);
  });
}
