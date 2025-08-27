import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

class KontextWebview extends StatelessWidget {
  const KontextWebview({
    super.key,
    required this.urlRequest,
    required this.allowedUrlSubstrings,
    required this.onWebViewCreated,
  });

  final URLRequest urlRequest;
  final List<String> allowedUrlSubstrings;
  final void Function(InAppWebViewController controller) onWebViewCreated;

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

        url?.openUrl();
        return NavigationActionPolicy.CANCEL;
      },
      onConsoleMessage: (controller, consoleMessage) {
        Logger.info('WebView Console: ${consoleMessage.message}');
      },
      onWebViewCreated: onWebViewCreated,
      onReceivedError: (controller, request, error) {
        Logger.exception('Error received in InAppWebView: $error, request: $request');
      },
      onReceivedHttpError: (controller, request, error) {
        // Ignore favicon 404 errors as they're not critical
        if (request.url.toString().endsWith('/favicon.ico')) {
          return;
        }

        Logger.exception('HTTP error received in InAppWebView: $error, request: $request');
      },
      onLoadStop: (controller, url) async {
        await controller.evaluateJavascript(source: '''
                  if (!window.__flutterSdkBridgeReady) {
                    window.__flutterSdkBridgeReady = true;
                    window.addEventListener('message', event => {
                      window.flutter_inappwebview.callHandler('postMessage', event.data);
                    });
                  }
                ''');
      },
    );
  }
}
