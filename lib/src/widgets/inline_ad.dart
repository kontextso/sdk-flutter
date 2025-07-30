import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/models/public_ad.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';
import 'package:kontext_flutter_sdk/src/widgets/ads_provider_data.dart';
import 'package:kontext_flutter_sdk/src/widgets/hooks/use_bid.dart';

class InlineAd extends HookWidget {
  const InlineAd({
    super.key,
    required this.code,
    required this.messageId,
    this.otherParams,
  });

  final String code;
  final String messageId;
  final Map<String, dynamic>? otherParams;

  void _postUpdateIframe(
    InAppWebViewController controller, {
    required String adServerUrl,
    required List<Message> messages,
  }) {
    print('Posted update iframe');
    final payload = {
      'type': 'update-iframe',
      'data': {
        'sdk': 'sdk',
        'code': code,
        'messageId': messageId,
        'messages': messages.map((m) => m.toJson()).toList(),
        if (otherParams != null) 'otherParams': otherParams,
      },
    };

    controller.evaluateJavascript(source: '''
      window.postMessage(${jsonEncode(payload)}, '$adServerUrl');
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
    final adsProviderData = AdsProviderData.of(context);
    if (adsProviderData == null) {
      return const SizedBox.shrink();
    }

    if (adsProviderData.isDisabled) {
      return const SizedBox.shrink();
    }

    final bid = useBid(adsProviderData, code: code, messageId: messageId);
    if (bid == null) {
      return const SizedBox.shrink();
    }

    final messageContent = adsProviderData.messages.firstWhere((m) => m.id == messageId).content;

    final iframeLoaded = useState(false);
    final showIframe = useState(false);
    final height = useState(.0);

    final webViewController = useRef<InAppWebViewController?>(null);

    useEffect(() {
      if (!iframeLoaded.value || webViewController.value == null) {
        return null;
      }

      _postUpdateIframe(
        webViewController.value!,
        adServerUrl: adsProviderData.adServerUrl,
        messages: adsProviderData.messages.getLastMessages(),
      );

      return null;
    }, [iframeLoaded.value, webViewController.value, otherParams]);

    void resetIframe() {
      iframeLoaded.value = false;
      showIframe.value = false;
      height.value = 0.0;
      webViewController.value = null;
      adsProviderData.resetAll();
    }

    return Offstage(
      offstage: !iframeLoaded.value || !showIframe.value,
      child: SizedBox(
        height: height.value,
        width: double.infinity,
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri('${adsProviderData.adServerUrl}/api/frame/${bid.id}?code=$code&messageId=$messageId'),
          ),
          initialSettings: InAppWebViewSettings(useShouldOverrideUrlLoading: true),
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final url = navigationAction.request.url?.toString();
            print('Navigating to URL: $url');

            if (url != null && url.contains(adsProviderData.adServerUrl)) {
              return NavigationActionPolicy.ALLOW;
            }

            url?.openUrl();
            return NavigationActionPolicy.CANCEL;
          },
          onConsoleMessage: (controller, consoleMessage) {
            print('Console Message: ${consoleMessage.message}');
          },
          onWebViewCreated: (controller) {
            webViewController.value = controller;
            controller.addJavaScriptHandler(
              handlerName: 'postMessage',
              callback: (args) {
                final postMessage = args.firstOrNull;
                print('Received postMessage: $postMessage');
                if (postMessage == null || postMessage is! Json) {
                  return;
                }

                final messageType = postMessage['type'];
                final data = postMessage['data'];

                switch (messageType) {
                  case 'init-iframe':
                    iframeLoaded.value = true;
                    break;
                  case 'show-iframe':
                    showIframe.value = true;
                    break;
                  case 'hide-iframe':
                    showIframe.value = false;
                    break;
                  case 'resize-iframe':
                    final dataHeight = data['height'];
                    if (dataHeight is num) {
                      height.value = dataHeight.toDouble();
                    }
                    break;
                  case 'view-iframe':
                    _handleAdCallback(adsProviderData.onAdView, data);
                    break;
                  case 'click-iframe':
                    _handleAdCallback(adsProviderData.onAdClick, data);
                    break;
                  case 'ad-done-iframe':
                    _handleAdCallback(adsProviderData.onAdDone, data);
                    break;
                  case 'error-iframe':
                    resetIframe();
                    break;
                  default:
                    print('Unknown message type: $messageType, message: $postMessage');
                }
              },
            );
          },
          onReceivedError: (controller, request, error) {
            print('onReceivedError: $error');
          },
          onReceivedHttpError: (controller, request, error) {
            // Ignore favicon 404 errors as they're not critical
            if (request.url.toString().endsWith('/favicon.ico')) {
              return;
            }

            print('onReceivedHttpError: $error, request: $request');
          },
          onLoadStop: (controller, url) async {
            await controller.evaluateJavascript(source: '''
                  if (!window.__flutterSdkBridgeReady) {
                    console.log('InAppWebView loaded with message: ' + ${jsonEncode(messageContent)} + ', URL: ' + ${jsonEncode(url.toString())});
                    window.__flutterSdkBridgeReady = true;
                    window.addEventListener('message', event => {
                      window.flutter_inappwebview.callHandler('postMessage', event.data);
                    });
                  }
                ''');
          },
        ),
      ),
    );
  }
}
