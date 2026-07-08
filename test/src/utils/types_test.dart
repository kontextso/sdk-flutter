import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/utils/types.dart';

void main() {
  group('OpenIframeComponent.fromMessageType', () {
    test('returns modal for open-component-iframe', () {
      expect(OpenIframeComponent.fromMessageType('open-component-iframe'), OpenIframeComponent.modal);
    });

    test('returns modal for close-component-iframe', () {
      expect(OpenIframeComponent.fromMessageType('close-component-iframe'), OpenIframeComponent.modal);
    });

    test('returns skoverlay for open-skoverlay-iframe', () {
      expect(OpenIframeComponent.fromMessageType('open-skoverlay-iframe'), OpenIframeComponent.skoverlay);
    });

    test('returns skoverlay for close-skoverlay-iframe', () {
      expect(OpenIframeComponent.fromMessageType('close-skoverlay-iframe'), OpenIframeComponent.skoverlay);
    });

    test('returns null for unknown message type', () {
      expect(OpenIframeComponent.fromMessageType('unknown-type'), null);
    });

    test('returns null for non-string input', () {
      expect(OpenIframeComponent.fromMessageType(42), null);
      expect(OpenIframeComponent.fromMessageType(null), null);
    });
  });
}
