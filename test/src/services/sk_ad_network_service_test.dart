import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart' show Skan;
import 'package:kontext_flutter_sdk/src/services/sk_ad_network_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Skan skan() => Skan(
        version: '4.0',
        network: 'example.com',
        itunesItem: '123',
        sourceApp: '0',
      );

  group('SKAdNetwork on non-iOS hosts', () {
    // These tests run on whatever the test host is (macOS during local dev).
    // If that host happens to be iOS (unlikely in CI but possible), skip.
    final skipOnIOS = Platform.isIOS;

    test('initImpression returns false without touching the channel', () async {
      expect(await SKAdNetwork.initImpression(skan()), isFalse);
    }, skip: skipOnIOS);

    test('startImpression completes (no-op) without side effects', () async {
      await SKAdNetwork.startImpression();
    }, skip: skipOnIOS);

    test('endImpression completes (no-op) without side effects', () async {
      await SKAdNetwork.endImpression();
    }, skip: skipOnIOS);

    test('dispose completes even when not initialised', () async {
      await SKAdNetwork.dispose();
    }, skip: skipOnIOS);
  });
}
