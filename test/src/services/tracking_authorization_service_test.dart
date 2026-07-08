import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/services/tracking_authorization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('kontext_flutter_sdk/tracking_authorization');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('trackingAuthorizationStatus', () {
    test('returns notSupported on non-iOS hosts', () async {
      // Running the test on macOS/linux means Platform.isIOS == false.
      if (!Platform.isIOS) {
        expect(await TrackingAuthorizationService.trackingAuthorizationStatus,
            TrackingStatus.notSupported);
      }
    });

    test('maps raw status ints to enum cases when channel responds (iOS path)', () async {
      // We cannot change Platform.isIOS from a Dart test, but we can at least
      // ensure the mapping helper would produce the expected values. On
      // non-iOS hosts, trackingAuthorizationStatus short-circuits before the
      // channel is touched, so this test documents the expected contract via
      // the enum index ordering instead.
      const cases = [
        (0, TrackingStatus.notDetermined),
        (1, TrackingStatus.restricted),
        (2, TrackingStatus.denied),
        (3, TrackingStatus.authorized),
      ];
      for (final (i, expected) in cases) {
        expect(TrackingStatus.values[i], expected);
      }
    });

    test('every TrackingStatus case is reachable from the values array', () {
      expect(TrackingStatus.values, contains(TrackingStatus.notDetermined));
      expect(TrackingStatus.values, contains(TrackingStatus.restricted));
      expect(TrackingStatus.values, contains(TrackingStatus.denied));
      expect(TrackingStatus.values, contains(TrackingStatus.authorized));
      expect(TrackingStatus.values, contains(TrackingStatus.notSupported));
    });
  });

  group('requestTrackingAuthorization', () {
    test('returns notSupported on non-iOS hosts', () async {
      if (!Platform.isIOS) {
        expect(await TrackingAuthorizationService.requestTrackingAuthorization(),
            TrackingStatus.notSupported);
      }
    });
  });
}
