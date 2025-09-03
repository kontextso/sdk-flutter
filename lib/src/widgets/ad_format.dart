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
    required this.onActiveChanged,
  });

  final String code;
  final String messageId;
  final ValueChanged<bool> onActiveChanged;

  void _postUpdateIframe(
    InAppWebViewController controller, {
    required String adServerUrl,
    required List<Message> messages,
    Map<String, dynamic>? otherParams,
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
    required bool Function() disposed,
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
        if (disposed()) return;

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

        final milliseconds = data?['timeout'];
        final timeout = (milliseconds is int && milliseconds > 0)
            ? Duration(milliseconds: milliseconds)
            : const Duration(seconds: 5);

        final modalUri = inlineUri.replacePath('/api/$component/$bidId');
        InterstitialModal.show(
          context,
          adServerUrl: adServerUrl,
          uri: modalUri,
          initTimeout: timeout,
          onAdClick: (data) => _onAdClick(adServerUrl, adsProviderData.onAdClick, data),
        );
        break;
      case 'error-iframe':
        resetIframe();
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    void setActive(bool active) => WidgetsBinding.instance.addPostFrameCallback((_) {
          onActiveChanged(active);
        });

    final adsProviderData = AdsProviderData.of(context);
    final disabled = adsProviderData == null || adsProviderData.isDisabled;

    final bidId = !disabled ? selectBid(adsProviderData, code: code, messageId: messageId)?.id : null;

    Uri? inlineUri;
    if (!disabled && bidId != null) {
      inlineUri = KontextUrlBuilder(
        baseUrl: adsProviderData.adServerUrl,
        path: '/api/frame/$bidId',
      )
          .addParam('code', code)
          .addParam('messageId', messageId)
          .addParam('sdk', kSdkLabel)
          .addParam('theme', adsProviderData.otherParams?['theme'])
          .buildUri();
    }

    final isActive = !disabled && bidId != null && inlineUri != null;

    useEffect(() {
      setActive(isActive);
      return null;
    }, [isActive]);

    if (!isActive) return const SizedBox.shrink();

    final adServerUrl = adsProviderData.adServerUrl;
    final otherParams = adsProviderData.otherParams;

    useEffect(() {
      return () => setActive(false);
    }, const []);

    final disposed = useRef(false);
    useEffect(() {
      return () => disposed.value = true;
    }, const []);

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
        otherParams: otherParams,
      );

      return null;
    }, [iframeLoaded.value, webViewController.value, otherParamsHash]);

    void resetIframe() {
      iframeLoaded.value = false;
      showIframe.value = false;
      height.value = 0.0;
      webViewController.value = null;
      adsProviderData.resetAll();
      setActive(false);
    }

    return Offstage(
      offstage: !iframeLoaded.value || !showIframe.value,
      child: Container(
        height: height.value,
        width: double.infinity,
        color: Colors.transparent,
        child: KontextWebview(
          key: ValueKey('ad-$messageId-$bidId'), // Force rebuild on bidId or messageId change
          uri: inlineUri,
          allowedOrigins: [adServerUrl],
          onMessageReceived: (controller, messageType, data) {
            webViewController.value = controller;
            _handleWebViewCreated(
              context,
              messageType: messageType,
              disposed: () => disposed.value,
              data: data,
              adServerUrl: adServerUrl,
              inlineUri: inlineUri!,
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
