import 'dart:collection' show UnmodifiableListView;
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;
import 'package:kontext_flutter_sdk/src/utils/extensions.dart' show UriExtension;
import 'package:kontext_flutter_sdk/src/utils/types.dart' show Json;

DateTime? _lastUserGestureAt;
final _storeOpenGate = _RecentStringGate(window: const Duration(milliseconds: 1200));

class _RecentStringGate {
  _RecentStringGate({required this.window});

  final Duration window;
  String? _lastValue;
  DateTime? _lastAt;

  bool allow(String value) {
    final now = DateTime.now();
    final lastAt = _lastAt;
    if (lastAt != null && _lastValue == value && now.difference(lastAt) < window) {
      return false;
    }
    _lastValue = value;
    _lastAt = now;
    return true;
  }
}

// In ad redirect chains, hasGesture can be true on an intermediate click tracker
// request and false on the final store URL request. Example:
// user tap: -> https://click.liftoff.io/... (hasGesture=true) -> https://play.google.com/... (hasGesture=false)
// Keep a short (2s) latch so the final request can still be treated as
// user-initiated.
bool _hasRecentUserGesture() {
  final last = _lastUserGestureAt;
  if (last == null) {
    return false;
  }
  return DateTime.now().difference(last) < const Duration(seconds: 2);
}

bool _isStoreUrl(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  final host = uri.host.toLowerCase();
  return scheme == 'itms-apps' ||
      scheme == 'market' ||
      scheme == 'intent' ||
      host == 'apps.apple.com' ||
      host == 'play.google.com' ||
      host == 'market.android.com';
}

final _earlyBridge = UserScript(
  source: '''
    (function() {
      if (window.__flutterSdkBridgeReady) return;
      window.__flutterSdkBridgeReady = true;
      
      // Messages buffered before the bridge is ready
      window.__kontextMsgQueue = [];
      
      function postToFlutter(data) {
        try {
          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
            window.flutter_inappwebview.callHandler('postMessage', data);
          } else {
            window.__kontextMsgQueue.push(data);
          }
        } catch (e) {
          console.error('Error posting message to Flutter: ', e);
        }
      }
      
      window.addEventListener('message', event => {
        postToFlutter(event.data);
      });
    })();
  ''',
  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  forMainFrameOnly: false,
);

final _flushMsgQueue = '''
  (function() {
    try {
      var queue = window.__kontextMsgQueue || [];
      if (queue.length === 0) return;
      window.__kontextMsgQueue = [];
      
      for (var i = 0; i < queue.length; i++) {
        var msg = queue[i];
        try {
          window.flutter_inappwebview.callHandler('postMessage', msg);
        } catch (e) {
          console.error('Error posting queued message to Flutter: ', e);
        }
      }
    } catch (e) {
      console.error('Error flushing message queue to Flutter: ', e);
    }
  })();
''';

typedef OnMessageReceived = void Function(InAppWebViewController controller, String messageType, Json? data);
typedef KontextWebviewBuilder = Widget Function({
  Key? key,
  required Uri uri,
  required List<String> allowedOrigins,
  required void Function(Json? data) onEventIframe,
  required OnMessageReceived onMessageReceived,
});

class KontextWebview extends StatelessWidget {
  const KontextWebview({
    super.key,
    required this.uri,
    required this.allowedOrigins,
    required this.onEventIframe,
    required this.onMessageReceived,
  });

  final Uri uri;
  final List<String> allowedOrigins;
  final void Function(Json? data) onEventIframe;
  final OnMessageReceived onMessageReceived;

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri.uri(uri)),
      initialUserScripts: UnmodifiableListView([_earlyBridge]),
      initialSettings: InAppWebViewSettings(
        transparentBackground: true,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        verticalScrollBarEnabled: false,
        horizontalScrollBarEnabled: false,
        sharedCookiesEnabled: true,
        supportMultipleWindows: true,
        javaScriptCanOpenWindowsAutomatically: true,
      ),
      onCreateWindow: (controller, request) async {
        if (request.hasGesture == true) {
          _lastUserGestureAt = DateTime.now();
        }

        final uri = request.request.url?.uriValue;
        if (uri == null) {
          return false;
        }

        if (Platform.isIOS) {
          final scheme = uri.scheme.toLowerCase();
          final isHttp = scheme == 'http' || scheme == 'https';
          if (isHttp && !_isStoreUrl(uri)) {
            // On iOS, keep HTTP(S) redirect chains inside WebView until they
            // resolve to a definitive store URL.
            return false;
          }
        }

        return uri.openInAppBrowser();
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final uri = navigationAction.request.url?.uriValue;
        if (uri == null) {
          return NavigationActionPolicy.CANCEL;
        }

        if (_isStoreUrl(uri)) {
          if (!Platform.isIOS || _storeOpenGate.allow(uri.toString())) {
            await uri.openInAppBrowser();
          }
          return NavigationActionPolicy.CANCEL;
        }

        if (uri.toString() == 'about:srcdoc') {
          return NavigationActionPolicy.ALLOW;
        }

        final url = uri.toString();
        final isAllowed = allowedOrigins.any(
          (origin) {
            if (url.startsWith(origin)) return true;
            try {
              return uri.origin == origin || uri.host == origin;
            } catch (_) {
              return uri.host == origin;
            }

          },
        );

        if (isAllowed) {
          return NavigationActionPolicy.ALLOW;
        }

        final isUserGesture = navigationAction.hasGesture == true;
        if (Platform.isIOS) {
          final scheme = uri.scheme.toLowerCase();
          final isHttp = scheme == 'http' || scheme == 'https';
          if (isHttp) {
            return NavigationActionPolicy.ALLOW;
          }
        }
        if (isUserGesture) {
          await uri.openInAppBrowser();
          return NavigationActionPolicy.CANCEL;
        }

        return NavigationActionPolicy.ALLOW;
      },
      shouldInterceptRequest: (controller, request) async {
        if (!Platform.isAndroid) {
          return null;
        }

        final uri = request.url.uriValue;
        final host = uri.host.toLowerCase();
        final scheme = uri.scheme.toLowerCase();

        if (request.hasGesture == true) {
          _lastUserGestureAt = DateTime.now();
        }

        final emptyResponse = WebResourceResponse(
          contentType: 'text/plain',
          data: Uint8List(0),
          headers: const {'Content-Type': 'text/plain'},
          statusCode: 204,
          reasonPhrase: 'No Content',
        );

        if (scheme == 'itms-apps') {
          // Returning a empty response to prevent the WebView from
          // showing an error page on Android when trying to load the Apple itms-apps URL.
          return emptyResponse;
        }

        if (host == 'play.google.com') {
          final isUserGesture = request.hasGesture == true || _hasRecentUserGesture();
          if (isUserGesture) {
            await uri.openInAppBrowser();
            // Reset the last user gesture timestamp to prevent subsequent non-gesture requests from being treated as gestures.
            _lastUserGestureAt = null;
          }

          // Return an empty response so the iframe doesn't render a WebView error page.
          return emptyResponse;
        }

        return null;
      },
      onWebViewCreated: (controller) {
        controller.addJavaScriptHandler(
          handlerName: 'postMessage',
          callback: (args) {
            final postMessage = args.firstOrNull;
            if (postMessage == null || postMessage is! Json) {
              return;
            }

            final messageType = postMessage['type'];
            final data = postMessage['data'];

            if (messageType is String && (data == null || data is Json)) {
              if (messageType == 'event-iframe') {
                onEventIframe(data);
              }
              onMessageReceived(controller, messageType, data as Json?);
            }
          },
        );

        controller.evaluateJavascript(source: _flushMsgQueue);
      },
      onConsoleMessage: (controller, consoleMessage) {
        final message = consoleMessage.message;
        final level = consoleMessage.messageLevel;

        if (level == ConsoleMessageLevel.ERROR) {
          Logger.error('WebView Console $level: $message');
        } else if (level == ConsoleMessageLevel.WARNING) {
          Logger.warn('WebView Console $level: $message');
        } else {
          Logger.info('WebView Console: $message');
        }
      },
      onReceivedError: (controller, request, error) {
        Logger.error('Error received in InAppWebView: $error, request: $request');
      },
      onReceivedHttpError: (controller, request, error) {
        // Ignore favicon 404 errors as they're not critical
        if (request.url.toString().endsWith('/favicon.ico')) {
          return;
        }

        Logger.error('HTTP error received in InAppWebView: $error, request: $request');
      },
    );
  }
}
