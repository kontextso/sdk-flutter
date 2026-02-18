import 'dart:collection' show UnmodifiableListView;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;
import 'package:kontext_flutter_sdk/src/utils/types.dart' show Json;
import 'package:kontext_flutter_sdk/src/widgets/webview_console_error_limiter.dart' show WebViewConsoleErrorLimiter;

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

typedef OnEventIframe = void Function(InAppWebViewController controller, Json? data);
typedef OnMessageReceived = void Function(InAppWebViewController controller, String messageType, Json? data);
typedef KontextWebviewBuilder = Widget Function({
  Key? key,
  required Uri uri,
  required List<String> allowedOrigins,
  required OnEventIframe onEventIframe,
  required OnMessageReceived onMessageReceived,
});

class KontextWebview extends HookWidget {
  const KontextWebview({
    super.key,
    required this.uri,
    required this.allowedOrigins,
    required this.onEventIframe,
    required this.onMessageReceived,
  });

  final Uri uri;
  final List<String> allowedOrigins;
  final OnEventIframe onEventIframe;
  final OnMessageReceived onMessageReceived;

  void _logError(WebViewConsoleErrorLimiter limiter, {required String message}) {
    if (limiter.shouldSendRemote(message)) {
      Logger.error(message);
    } else {
      Logger.errorLocalOnly(message);
    }
  }

  bool _isAllowedUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }

    return allowedOrigins.any((origin) {
      final originUri = Uri.tryParse(origin);
      if (originUri == null) {
        return false;
      }

      return uri.scheme == originUri.scheme && uri.host == originUri.host;
    });
  }

  @override
  Widget build(BuildContext context) {
    final webViewConsoleErrorLimiter = useMemoized(() => WebViewConsoleErrorLimiter());
    final previousUri = useRef<Uri?>(null);

    useEffect(() {
      if (previousUri.value != null && previousUri.value != uri) {
        webViewConsoleErrorLimiter.clear();
      }
      previousUri.value = uri;
      return null;
    }, [uri, webViewConsoleErrorLimiter]);

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
      ),
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url?.toString();
        if (url == null) {
          return NavigationActionPolicy.CANCEL;
        }

        if (url.toString() == 'about:srcdoc') {
          return NavigationActionPolicy.ALLOW;
        }

        if (_isAllowedUrl(url)) {
          return NavigationActionPolicy.ALLOW;
        }

        return NavigationActionPolicy.CANCEL;
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

            if (messageType is String && data is Json?) {
              if (messageType == 'event-iframe') {
                onEventIframe(controller, data);
              }
              onMessageReceived(controller, messageType, data);
            }
          },
        );

        controller.evaluateJavascript(source: _flushMsgQueue);
      },
      onConsoleMessage: (controller, consoleMessage) {
        final level = consoleMessage.messageLevel;
        final webViewMessage = 'WebView Console $level: ${consoleMessage.message}';

        switch (level) {
          case ConsoleMessageLevel.ERROR:
            _logError(
              webViewConsoleErrorLimiter,
              message: webViewMessage,
            );
            break;
          case ConsoleMessageLevel.WARNING:
            Logger.warn(webViewMessage);
            break;
          default:
            Logger.info(webViewMessage);
        }
      },
      onReceivedError: (controller, request, error) {
        final webViewMessage = 'Error received in InAppWebView: $error, request: $request';
        _logError(
          webViewConsoleErrorLimiter,
          message: webViewMessage,
        );
      },
      onReceivedHttpError: (controller, request, error) {
        // Ignore favicon 404 errors as they're not critical
        if (request.url.toString().endsWith('/favicon.ico')) {
          return;
        }

        final webViewMessage = 'HTTP error received in InAppWebView: $error, request: $request';
        _logError(
          webViewConsoleErrorLimiter,
          message: webViewMessage,
        );
      },
    );
  }
}
