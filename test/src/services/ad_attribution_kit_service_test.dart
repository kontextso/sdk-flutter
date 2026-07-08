import 'dart:io' show Platform;
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/services/ad_attribution_kit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdAttributionKit on non-iOS hosts', () {
    final skipOnIOS = Platform.isIOS;

    test('initImpression returns false', () async {
      expect(await AdAttributionKit.initImpression('jws-token'), isFalse);
    }, skip: skipOnIOS);

    test('setAttributionFrame returns false when not initialised', () async {
      expect(
        await AdAttributionKit.setAttributionFrame(const Rect.fromLTWH(0, 0, 100, 100)),
        isFalse,
      );
    }, skip: skipOnIOS);

    test('handleTap returns false when not initialised (with or without URI)', () async {
      expect(await AdAttributionKit.handleTap(null), isFalse);
      expect(await AdAttributionKit.handleTap(Uri.parse('https://example.com')), isFalse);
    }, skip: skipOnIOS);

    test('beginView completes as no-op', () async {
      await AdAttributionKit.beginView();
    }, skip: skipOnIOS);

    test('endView completes as no-op', () async {
      await AdAttributionKit.endView();
    }, skip: skipOnIOS);

    test('dispose completes even when not initialised', () async {
      await AdAttributionKit.dispose();
    }, skip: skipOnIOS);
  });
}
