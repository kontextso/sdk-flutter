import 'dart:collection' show UnmodifiableListView;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart' show Json;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;

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
  final void Function(InAppWebViewController controller, String messageType, Json? data) onMessageReceived;

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
      ),
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url?.toString();

        if (url != null && allowedOrigins.any((origin) => url.contains(origin))) {
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
