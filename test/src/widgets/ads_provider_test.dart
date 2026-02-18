import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/services/advertising_id_service.dart';
import 'package:kontext_flutter_sdk/src/services/tracking_authorization_service.dart';
import 'package:kontext_flutter_sdk/src/widgets/ads_provider.dart';

void main() {
  setUp(() {
    AdvertisingIdService.resetForTesting();
  });

  tearDown(() {
    AdvertisingIdService.resetForTesting();
  });

  testWidgets('AdsProvider triggers startup ATT flow', (tester) async {
    var requestCount = 0;

    AdvertisingIdService.isIOSProvider = () => true;
    AdvertisingIdService.iosVersionProvider = () async => '16.0';
    AdvertisingIdService.trackingStatusProvider = () async => TrackingStatus.notDetermined;
    AdvertisingIdService.requestTrackingProvider = () async {
      requestCount += 1;
      return TrackingStatus.authorized;
    };

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AdsProvider(
          publisherToken: 'token',
          userId: 'user',
          conversationId: 'conv',
          messages: <Message>[],
          enabledPlacementCodes: <String>['inlineAd'],
          child: SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();

    expect(requestCount, 1);
  });

  testWidgets('AdsProvider startup ATT flow runs only once across remounts', (tester) async {
    var requestCount = 0;

    AdvertisingIdService.isIOSProvider = () => true;
    AdvertisingIdService.iosVersionProvider = () async => '16.0';
    AdvertisingIdService.trackingStatusProvider = () async => TrackingStatus.notDetermined;
    AdvertisingIdService.requestTrackingProvider = () async {
      requestCount += 1;
      return TrackingStatus.authorized;
    };

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AdsProvider(
          key: ValueKey('provider-1'),
          publisherToken: 'token',
          userId: 'user',
          conversationId: 'conv',
          messages: [],
          enabledPlacementCodes: ['inlineAd'],
          child: SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AdsProvider(
          key: ValueKey('provider-2'),
          publisherToken: 'token',
          userId: 'user',
          conversationId: 'conv',
          messages: [],
          enabledPlacementCodes: ['inlineAd'],
          child: SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();

    expect(requestCount, 1);
  });
}
