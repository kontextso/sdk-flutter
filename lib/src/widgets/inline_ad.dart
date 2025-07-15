import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/widgets/ads_provider_data.dart';

class InlineAd extends HookWidget {
  const InlineAd({super.key, required this.code, required this.messageId});

  final String code;
  final String messageId;

  void _postUpdateIframe(InAppWebViewController controller, {required List<Message> messages}) {
    final payload = {
      'type': 'update-iframe',
      'data': {
        'sdk': 'sdk',
        'code': code,
        'messageId': messageId,
        'messages': messages.map((message) => message.toJson()).toList(),
      },
    };

    controller.evaluateJavascript(source: '''
      window.postMessage(${jsonEncode(payload)}, 'https://server.develop.megabrain.co');
    ''');
  }

  @override
  Widget build(BuildContext context) {
    print('Building InlineAd with code: $code, messageId: $messageId');
    final adsProviderData = AdsProviderData.of(context);
    final bid = (adsProviderData?.bids ?? []).firstOrNull;
    if (bid == null) {
      return const SizedBox.shrink();
    }

    final iframeLoaded = useState(false);

    final messages = adsProviderData?.messages ?? [];


    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri('https://server.develop.megabrain.co/api/frame/${bid.id}?code=$code&messageId=$messageId'),
      ),
      initialSettings: InAppWebViewSettings(
        useShouldOverrideUrlLoading: true,
      ),
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url?.toString();
        print('Navigating to URL: $url');

        return NavigationActionPolicy.CANCEL;
      },
      onConsoleMessage: (controller, consoleMessage) {
        print('Console Message: ${consoleMessage.message}');
      },
      onWebViewCreated: (controller) {
        controller.addJavaScriptHandler(
          handlerName: 'message',
          callback: (args) {
            print('Message from iframe: $args');
            final message = args.firstOrNull;
            if (message == null || message is! Json) {
              return;
            }

            switch (message['type']) {
              case 'init-iframe':
                print('Initializing iframe with message: $message');
                iframeLoaded.value = true;
                _postUpdateIframe(controller, messages: messages);
                break;
              default:
                print('Unknown message type: ${message['type']}');
            }
            print('Received message: $message');
          },
        );
      },
      onReceivedError: (controller, request, error) {
        print('onReceivedError: $error');
      },
      onReceivedHttpError: (controller, request, error) {
        print('onReceivedHttpError: $error');
      },
      onLoadStop: (controller, url) async {
        await controller.evaluateJavascript(source: '''
              console.log('InAppWebView loaded with URL: $url');
              if (!window.__flutterSdkBridgeReady) {
                window.__flutterSdkBridgeReady = true;
                window.addEventListener('message', event => {
                  window.flutter_inappwebview.callHandler('message', event.data);
                });
              }
            ''');
      },
    );
  }
}
