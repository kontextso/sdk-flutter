import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/widgets/webview_console_error_limiter.dart';

void main() {
  group('WebViewConsoleErrorLimiter', () {
    late WebViewConsoleErrorLimiter limiter;

    setUp(() {
      limiter = WebViewConsoleErrorLimiter();
    });

    test('first message is remote-eligible', () {
      expect(limiter.shouldSendRemote('Error: Failed to open https://x'), isTrue);
    });

    test('same message is remote-suppressed after first send', () {
      const message = 'Error: Failed to open https://x';
      expect(limiter.shouldSendRemote(message), isTrue);
      expect(limiter.shouldSendRemote(message), isFalse);
      expect(limiter.shouldSendRemote(message), isFalse);
    });

    test('different messages are treated as different keys', () {
      expect(limiter.shouldSendRemote('Error: Failed to open https://x?a=1'), isTrue);
      expect(limiter.shouldSendRemote('Error: Failed to open https://x?a=2'), isTrue);
    });

    test('clear resets seen message set', () {
      const message = 'Error: Failed to open https://x';
      expect(limiter.shouldSendRemote(message), isTrue);
      expect(limiter.shouldSendRemote(message), isFalse);
      limiter.clear();
      expect(limiter.shouldSendRemote(message), isTrue);
    });
  });
}
