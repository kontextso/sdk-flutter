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
import 'package:kontext_flutter_sdk/src/utils/kontext_url_builder.dart';
import 'package:kontext_flutter_sdk/src/widgets/ads_provider_data.dart';
import 'package:kontext_flutter_sdk/src/widgets/hooks/select_bid.dart';
import 'package:kontext_flutter_sdk/src/widgets/interstitial_modal.dart';
import 'package:kontext_flutter_sdk/src/widgets/kontext_webview.dart';

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

  void _onAdClick(String adServerUrl, AdCallback? callback, Json? data) {
    final path = data?['url'];
    if (path is! String) {
      Logger.error('Ad click URL is missing or invalid. Data: $data');
      return;
    }

    final uri = KontextUrlBuilder(baseUrl: adServerUrl, path: path).buildUri();
    if (uri == null) {
      Logger.error('Ad click URL is invalid: $path');
      return;
    }

    uri.openUri();

    final updatedData = {
      ...data!,
      'url': uri.toString(),
    };

    _handleAdCallback(callback, updatedData);
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

  void _handleWebViewCreated(
    BuildContext context, {
    required String messageType,
    Json? data,
    required String adServerUrl,
    required Uri inlineUri,
    required String bidId,
    required ValueNotifier<bool> iframeLoaded,
    required ValueNotifier<bool> showIframe,
    required ValueNotifier<double> height,
    required VoidCallback resetIframe,
    required AdsProviderData adsProviderData,
  }) {
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
        final dataHeight = data?['height'];
        if (dataHeight is num) {
          height.value = dataHeight.toDouble();
        }
        break;
      case 'view-iframe':
        _handleAdCallback(adsProviderData.onAdView, data);
        break;
      case 'click-iframe':
        _onAdClick(adServerUrl, adsProviderData.onAdClick, data);
        break;
      case 'ad-done-iframe':
        // To ensure the ad is fully processed
        Future.delayed(const Duration(milliseconds: 300), () {
          _handleAdCallback(adsProviderData.onAdDone, data);
        });
        break;
      case 'open-component-iframe':
        final component = data?['component'];
        if (component is! String || component.isEmpty) {
          Logger.error('Ad component is missing or invalid. Data: $data');
          return;
        }

        final modalUri = inlineUri.replacePath('/api/$component/$bidId');
        InterstitialModal.show(
          context,
          adServerUrl: adServerUrl,
          uri: modalUri,
          onAdClick: (data) => _onAdClick(adServerUrl, adsProviderData.onAdClick, data),
        );
      case 'error-iframe':
        resetIframe();
        break;
      default:
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

    final bidId = selectBid(adsProviderData, code: code, messageId: messageId)?.id;
    if (bidId == null) {
      return const SizedBox.shrink();
    }

    final adServerUrl = adsProviderData.adServerUrl;
    final inlineUri = KontextUrlBuilder(
      baseUrl: adServerUrl,
      path: '/api/frame/$bidId',
    ).addParam('code', code).addParam('messageId', messageId).addParam('sdk', kSdkLabel).buildUri();
    if (inlineUri == null) {
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

    final otherParamsHash = otherParams?.deepHash;
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
    }, [iframeLoaded.value, webViewController.value, otherParamsHash]);

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
        child: KontextWebview(
          uri: inlineUri,
          allowedOrigins: [adServerUrl],
          onMessageReceived: (controller, messageType, data) {
            webViewController.value = controller;
            _handleWebViewCreated(
              context,
              messageType: messageType,
              data: data,
              adServerUrl: adServerUrl,
              inlineUri: inlineUri,
              bidId: bidId,
              iframeLoaded: iframeLoaded,
              showIframe: showIframe,
              height: height,
              resetIframe: resetIframe,
              adsProviderData: adsProviderData,
            );
          },
        ),
      ),
    );
  }
}
