import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart' show Json;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;

class KontextWebview extends StatelessWidget {
  const KontextWebview({
    super.key,
    required this.urlRequest,
    required this.allowedUrlSubstrings,
    required this.onMessageReceived,
  });

  final URLRequest urlRequest;
  final List<String> allowedUrlSubstrings;

  final void Function(InAppWebViewController controller, String messageType, Json? data) onMessageReceived;

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: urlRequest,
      initialSettings: InAppWebViewSettings(
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
      ),
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url?.toString();

        if (url != null && allowedUrlSubstrings.any((substring) => url.contains(substring))) {
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
              onMessageReceived(controller, messageType, data as Json?);
            }
          },
        );
      },
      onLoadStart: (controller, url) async {
        await controller.evaluateJavascript(source: '''
                  if (!window.__flutterSdkBridgeReady) {
                    window.__flutterSdkBridgeReady = true;
                    window.addEventListener('message', event => {
                      window.flutter_inappwebview.callHandler('postMessage', event.data);
                    });
                  }
                ''');
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
