import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/models/public_ad.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/widgets/ads_provider_data.dart';
import 'package:kontext_flutter_sdk/src/widgets/hooks/use_bid.dart';

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

  void _handleAdCallback(AdCallback? callback, Json? data) {
    if (callback == null || data == null) {
      return;
    }

    final ad = PublicAd.fromJson(data);
    callback(ad);
  }

  @override
  Widget build(BuildContext context) {
    print('Building InlineAd with code: $code, messageId: $messageId');
    final adsProviderData = AdsProviderData.of(context);
    if (adsProviderData == null) {
      return const SizedBox.shrink();
    }

    final bid = useBid(adsProviderData, code: code, messageId: messageId);
    print('Bid for code $code: $bid');
    if (bid == null) {
      return const SizedBox.shrink();
    }

    final iframeLoaded = useState(false);
    final showIframe = useState(false);
    final height = useState(.0);

    final messages = adsProviderData.messages;

    return Offstage(
      offstage: !iframeLoaded.value || !showIframe.value,
      child: SizedBox(
        height: height.value,
        width: double.infinity,
        child: InAppWebView(
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
                  case 'show-iframe':
                    print('Showing iframe with message: $message');
                    showIframe.value = true;
                    break;
                  case 'resize-iframe':
                    print('Resizing iframe with message: $message');
                    final dataHeight = message['data']['height'];
                    if (dataHeight is num) {
                      height.value = dataHeight.toDouble();
                    }
                    break;
                  case 'view-iframe':
                    print('Viewing iframe with message: $message');
                    _handleAdCallback(adsProviderData.onAdView, message['data']);
                    break;
                  case 'click-iframe':
                    print('Clicking iframe with message: $message');
                    _handleAdCallback(adsProviderData.onAdClick, message['data']);
                    break;
                  default:
                    print('Unknown message type: ${message['type']}, message: $message');
                }
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
        ),
      ),
    );
  }
}
