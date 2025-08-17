import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/models/public_ad.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';
import 'package:kontext_flutter_sdk/src/utils/constants.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';
import 'package:kontext_flutter_sdk/src/widgets/ads_provider_data.dart';
import 'package:kontext_flutter_sdk/src/widgets/hooks/use_bid.dart';

class AdFormat extends HookWidget {
  const AdFormat({
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
    final payload = {
      'type': 'update-iframe',
      'data': {
        'sdk': kSdkLabel,
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

    try {
      final ad = PublicAd.fromJson(data);
      callback(ad);
    } catch (e, stack) {
      Logger.exception(e, stack);
      return;
    }
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

    final iframeLoaded = useState(false);
    final showIframe = useState(false);
    final height = useState(.0);

    useEffect(() {
      // messageId can only become relevant if an ad was shown for that specific messageId
      if (showIframe.value && adsProviderData.lastAssistantMessageId == messageId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          adsProviderData.setRelevantAssistantMessageId(messageId);
        });
      }

      return null;
    }, [showIframe.value]);

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
          initialSettings: InAppWebViewSettings(
            useShouldOverrideUrlLoading: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
          ),
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final url = navigationAction.request.url?.toString();

            if (url != null && url.contains(adsProviderData.adServerUrl)) {
              return NavigationActionPolicy.ALLOW;
            }

            url?.openUrl();
            return NavigationActionPolicy.CANCEL;
          },
          onWebViewCreated: (controller) {
            webViewController.value = controller;
            controller.addJavaScriptHandler(
              handlerName: 'postMessage',
              callback: (args) {
                final postMessage = args.firstOrNull;
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
                    // To ensure the ad is fully processed
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _handleAdCallback(adsProviderData.onAdDone, data);
                    });
                    break;
                  case 'error-iframe':
                    resetIframe();
                    break;
                  default:
                }
              },
            );
          },
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
        ),
      ),
    );
  }
}
