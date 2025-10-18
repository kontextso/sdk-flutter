import 'dart:async' show Timer;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kontext_flutter_sdk/src/models/ad_event.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart';
import 'package:kontext_flutter_sdk/src/services/sk_overlay_service.dart';
import 'package:kontext_flutter_sdk/src/services/sk_store_product_service.dart';
import 'package:kontext_flutter_sdk/src/utils/constants.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';
import 'package:kontext_flutter_sdk/src/utils/helper_methods.dart';
import 'package:kontext_flutter_sdk/src/utils/kontext_url_builder.dart';
import 'package:kontext_flutter_sdk/src/utils/types.dart' show OnEventCallback, Json, OpenIframeComponent;
import 'package:kontext_flutter_sdk/src/widgets/ads_provider_data.dart';
import 'package:kontext_flutter_sdk/src/widgets/utils/select_bid.dart';
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

  Rect _visibleWindowRect(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final top = mediaQuery.padding.top; // status bar / notch
    final left = mediaQuery.padding.left;
    final right = mediaQuery.padding.right;

    return Rect.fromLTWH(
      left,
      top,
      size.width - left - right,
      size.height - top,
    );
  }

  Rect? _slotRectInWindow(GlobalKey key) {
    final currentContext = key.currentContext;
    if (currentContext == null) return null;

    final box = currentContext.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;

    final topLeft = box.localToGlobal(Offset.zero);
    final size = box.size;

    return Rect.fromLTWH(topLeft.dx, topLeft.dy, size.width, size.height);
  }

  void _postDimensions({
    required BuildContext context,
    required GlobalKey key,
    InAppWebViewController? controller,
    required String adServerUrl,
    required bool Function() disposed,
    required bool isNullDimensions,
    required void Function(bool isNull) setIsNullDimensions,
  }) {
    if (disposed()) return;

    final slot = _slotRectInWindow(key);
    if (slot == null || controller == null) return;

    final viewport = _visibleWindowRect(context);
    final mq = MediaQueryData.fromView(View.of(context));
    final keyboardHeight = mq.viewInsets.bottom;

    final containerWidth = slot.width.nullIfNaN;
    final containerHeight = slot.height.nullIfNaN;
    final containerX = slot.left.nullIfNaN;
    final containerY = slot.top.nullIfNaN;

    final isAnyNullDimension =
        containerWidth == null || containerHeight == null || containerX == null || containerY == null;
    // If first time any dimension is null, we set the flag to avoid further posts
    setIsNullDimensions(isAnyNullDimension);

    if (isNullDimensions) return;

    final payload = {
      'type': 'update-dimensions-iframe',
      'data': {
        'windowWidth': viewport.width.nullIfNaN,
        'windowHeight': viewport.height.nullIfNaN,
        'containerWidth': slot.width.nullIfNaN,
        'containerHeight': slot.height.nullIfNaN,
        'containerX': slot.left.nullIfNaN,
        'containerY': slot.top.nullIfNaN,
        'keyboardHeight': keyboardHeight.nullIfNaN,
      },
    };

    controller.evaluateJavascript(source: '''
      window.postMessage(${jsonEncode(payload)}, '$adServerUrl');
    ''');
  }

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

  void _handleEventIframe({required String adServerUrl, OnEventCallback? onEvent, Json? data}) {
    if (onEvent == null || data == null) {
      return;
    }

    try {
      final payload = data['payload'] as Json?;
      final path = payload?['url'] as String?;
      Uri? uri;
      if (path is String) {
        uri = KontextUrlBuilder(baseUrl: adServerUrl, path: path).buildUri();
      }

      if (uri != null && data['name'] == 'ad.clicked') {
        _handleAdClickedEvent(uri, payload: payload);
      }

      final updatedData = {
        ...data,
        if (payload != null)
          'payload': {
            ...payload,
            if (uri != null) 'url': uri.toString(),
          }
      };

      final event = AdEvent.fromJson(updatedData);
      onEvent(event);
    } catch (e, stack) {
      Logger.exception(e, stack);
      return;
    }
  }

  Future<void> _handleAdClickedEvent(Uri uri, {Json? payload}) async {
    bool storeProductOpened = false;
    final appStoreId = payload?['appStoreId'];
    if (appStoreId is String && appStoreId.isNotEmpty) {
      final result = await SkStoreProductService.present(appStoreId: appStoreId);
      storeProductOpened = result;
    }

    if (!storeProductOpened) {
      uri.openInAppBrowser();
    }
  }

  void _handleWebViewCreated(
    BuildContext context, {
    required String messageType,
    Json? data,
    required bool Function() isDisposed,
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
      case 'open-component-iframe':
        final component = toOpenIframeComponent(data?['component']);
        if (component == null) {
          return;
        }

        _handleOpenComponentIframe(
          context,
          adServerUrl: adServerUrl,
          inlineUri: inlineUri,
          bidId: bidId,
          component: component,
          data: data,
          onEvent: adsProviderData.onEvent,
        );
        break;
      case 'close-component-iframe':
        final component = toOpenIframeComponent(data?['component']);
        if (component == null) {
          return;
        }

        _handleCloseComponentIframe(component);
        break;
      case 'error-iframe':
        resetIframe();
        break;
      default:
    }
  }

  void _handleOpenComponentIframe(
    BuildContext context, {
    required String adServerUrl,
    required Uri inlineUri,
    required String bidId,
    required OpenIframeComponent component,
    Json? data,
    OnEventCallback? onEvent,
  }) {
    if (data == null) {
      Logger.error('Ad component data is missing. Component: $component');
      return;
    }

    final milliseconds = data['timeout'];
    final timeout =
        (milliseconds is int && milliseconds > 0) ? Duration(milliseconds: milliseconds) : const Duration(seconds: 5);

    switch (component) {
      case OpenIframeComponent.modal:
        final modalUri = inlineUri.replacePath('/api/${component.name}/$bidId');
        InterstitialModal.show(
          context,
          adServerUrl: adServerUrl,
          uri: modalUri,
          initTimeout: timeout,
          onEventIframe: (data) => _handleEventIframe(
            adServerUrl: adServerUrl,
            onEvent: onEvent,
            data: data,
          ),
          onOpenComponentIframe: (component, data) => _handleOpenComponentIframe(
            context,
            adServerUrl: adServerUrl,
            inlineUri: inlineUri,
            bidId: bidId,
            component: component,
            data: data,
            onEvent: onEvent,
          ),
          closeSKOverlay: () => _handleCloseComponentIframe(OpenIframeComponent.skoverlay),
        );
        break;
      case OpenIframeComponent.skoverlay:
        final appStoreId = data['appStoreId'];
        if (appStoreId is! String || appStoreId.isEmpty) {
          Logger.error('App Store ID is required to open SKOverlay. Data: $data');
          return;
        }

        final position = SKOverlayPosition.values.firstWhere(
          (e) => e.name == (data['position'] is String ? data['position'].toLowerCase() : null),
          orElse: () => SKOverlayPosition.bottom,
        );

        final dismissible = data['dismissible'];
        SKOverlayService.present(
          appStoreId: appStoreId,
          position: position,
          dismissible: dismissible is bool ? dismissible : true,
        );
        break;
    }
  }

  void _handleCloseComponentIframe(OpenIframeComponent component) {
    switch (component) {
      case OpenIframeComponent.modal:
        break; // Do nothing, already handled by InterstitialModal
      case OpenIframeComponent.skoverlay:
        SKOverlayService.dismiss();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final slotKey = useMemoized(() => GlobalKey(), const []);

    final ticker = useRef<Timer?>(null);
    void cancelTimer() {
      ticker.value?.cancel();
      ticker.value = null;
    }

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
      return () {
        SKOverlayService.dismiss();
        SkStoreProductService.dismiss();
      };
    }, const []);

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

    final isNullDimensions = useRef(false);
    useEffect(() {
      void postDimensions() => _postDimensions(
            context: context,
            controller: webViewController.value,
            key: slotKey,
            adServerUrl: adServerUrl,
            disposed: () => disposed.value,
            isNullDimensions: isNullDimensions.value,
            setIsNullDimensions: (isNull) => isNullDimensions.value = isNull,
          );
      final shouldRun = iframeLoaded.value && showIframe.value;
      if (shouldRun && ticker.value == null) {
        // Start after a short delay to allow initial layout to settle
        Future.delayed(const Duration(milliseconds: 500), () {
          // First call immediately without waiting for the first tick
          postDimensions();
          ticker.value = Timer.periodic(
            const Duration(milliseconds: 300),
            (_) => postDimensions(),
          );
        });
      } else if (!shouldRun) {
        cancelTimer();
      }
      return null;
    }, [iframeLoaded.value, showIframe.value]);

    useEffect(() {
      return () => cancelTimer();
    }, const []);

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
      SKOverlayService.dismiss();
      SkStoreProductService.dismiss();
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
        key: slotKey,
        height: height.value,
        width: double.infinity,
        color: Colors.transparent,
        child: KontextWebview(
          key: ValueKey('ad-$messageId-$bidId'),
          uri: inlineUri,
          allowedOrigins: [adServerUrl],
          onEventIframe: (data) => _handleEventIframe(
            adServerUrl: adServerUrl,
            onEvent: adsProviderData.onEvent,
            data: data,
          ),
          onMessageReceived: (controller, messageType, data) {
            webViewController.value = controller;
            _handleWebViewCreated(
              context,
              messageType: messageType,
              isDisposed: () => disposed.value,
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
