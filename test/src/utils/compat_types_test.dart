import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/webview/compat_types.dart';

void main() {
  group('NavigationAction.fromMap', () {
    test('reads isForMainFrame when true', () {
      final action = NavigationAction.fromMap({
        'request': {'url': 'https://example.com'},
        'isForMainFrame': true,
      });

      expect(action.request.url.toString(), 'https://example.com');
      expect(action.isForMainFrame, isTrue);
    });

    test('reads isForMainFrame when false', () {
      final action = NavigationAction.fromMap({
        'request': {'url': 'https://example.com/frame'},
        'isForMainFrame': false,
      });

      expect(action.request.url.toString(), 'https://example.com/frame');
      expect(action.isForMainFrame, isFalse);
    });

    test('defaults isForMainFrame to true when missing', () {
      final action = NavigationAction.fromMap({
        'request': {'url': 'https://example.com/default'},
      });

      expect(action.request.url.toString(), 'https://example.com/default');
      expect(action.isForMainFrame, isTrue);
    });
  });
}
